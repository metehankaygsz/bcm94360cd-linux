#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ENV="$SCRIPT_DIR/bundle.env"
PACKAGES_DIR="$SCRIPT_DIR/packages"
LOG_FILE="/var/log/bcm94360cd-linux-installer.log"
SKIP_HARDWARE_CHECK=0
ORIGINAL_ARGS=("$@")

usage() {
    cat <<EOF
Usage: sudo $0 [--skip-hardware-check]

Install the bundled Broadcom BCM94360CD / BCM4360 Wi-Fi driver without Internet access.

Options:
  --skip-hardware-check  Continue when PCI 14e4:43a0 is not detected
  -h, --help             Show this help
EOF
}

while (($#)); do
    case "$1" in
        --skip-hardware-check)
            SKIP_HARDWARE_CHECK=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ((EUID != 0)); then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo -- "$0" "${ORIGINAL_ARGS[@]}"
    fi
    echo "Run this installer as root." >&2
    exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1

die() {
    echo
    echo "ERROR: $*" >&2
    echo "See $LOG_FILE for details." >&2
    exit 1
}

info() {
    echo
    echo "==> $*"
}

[[ -f "$BUNDLE_ENV" ]] || die "Missing bundle.env next to install.sh."
[[ -d "$PACKAGES_DIR" ]] || die "Missing packages directory."

# shellcheck disable=SC1090
source "$BUNDLE_ENV"

for required in UBUNTU_VERSION KERNEL_RELEASE ARCHITECTURE PCI_VENDOR \
    PCI_DEVICE DRIVER_PACKAGE DRIVER_VERSION; do
    [[ -n "${!required:-}" ]] || die "bundle.env is missing $required."
done

info "Checking the target system"

[[ -r /etc/os-release ]] || die "Cannot identify the operating system."
# shellcheck disable=SC1091
source /etc/os-release

[[ "${ID:-}" == "ubuntu" ]] ||
    die "This bundle supports Ubuntu, but detected '${ID:-unknown}'."
[[ "${VERSION_ID:-}" == "$UBUNTU_VERSION" ]] ||
    die "This bundle supports Ubuntu $UBUNTU_VERSION, but detected '${VERSION_ID:-unknown}'."

CURRENT_ARCH="$(dpkg --print-architecture)"
[[ "$CURRENT_ARCH" == "$ARCHITECTURE" ]] ||
    die "This bundle is for $ARCHITECTURE, but detected $CURRENT_ARCH."

CURRENT_KERNEL="$(uname -r)"
[[ "$CURRENT_KERNEL" == "$KERNEL_RELEASE" ]] ||
    die "Kernel mismatch. Bundle: $KERNEL_RELEASE; running: $CURRENT_KERNEL. Build a bundle for the exact running kernel."

if ((SKIP_HARDWARE_CHECK == 0)); then
    DEVICE_FOUND=0
    for device_path in /sys/bus/pci/devices/*; do
        [[ -r "$device_path/vendor" && -r "$device_path/device" ]] || continue
        vendor="$(tr '[:upper:]' '[:lower:]' < "$device_path/vendor")"
        device="$(tr '[:upper:]' '[:lower:]' < "$device_path/device")"
        if [[ "$vendor" == "$PCI_VENDOR" && "$device" == "$PCI_DEVICE" ]]; then
            DEVICE_FOUND=1
            echo "Detected Broadcom BCM4360 at $(basename -- "$device_path")."
            break
        fi
    done
    ((DEVICE_FOUND == 1)) ||
        die "Broadcom BCM4360 (${PCI_VENDOR#0x}:${PCI_DEVICE#0x}) was not detected."
fi

info "Verifying bundled package checksums"
(
    cd "$PACKAGES_DIR"
    sha256sum --check SHA256SUMS
) || die "Package integrity verification failed."

TMP_ROOT="$(mktemp -d /var/tmp/bcm94360cd-linux.XXXXXX)"
cleanup() {
    rm -rf -- "$TMP_ROOT"
}
trap cleanup EXIT

LOCAL_REPO="$TMP_ROOT/repository"
EMPTY_PARTS="$TMP_ROOT/empty-sources"
SOURCE_LIST="$TMP_ROOT/offline.list"
APT_LISTS="$TMP_ROOT/lists"
APT_ARCHIVES="$TMP_ROOT/archives"
mkdir -p \
    "$LOCAL_REPO" \
    "$EMPTY_PARTS" \
    "$APT_LISTS/partial" \
    "$APT_ARCHIVES/partial"
cp -a "$PACKAGES_DIR"/. "$LOCAL_REPO"/
printf 'deb [trusted=yes] file:%s ./\n' "$LOCAL_REPO" > "$SOURCE_LIST"

APT_OPTIONS=(
    -o "Dir::Etc::sourcelist=$SOURCE_LIST"
    -o "Dir::Etc::sourceparts=$EMPTY_PARTS"
    -o "Dir::State::lists=$APT_LISTS"
    -o "Dir::Cache::archives=$APT_ARCHIVES"
    -o "APT::Get::List-Cleanup=0"
    -o "Acquire::Languages=none"
    -o "Acquire::Retries=0"
)

info "Installing the offline packages"
export DEBIAN_FRONTEND=noninteractive
apt-get "${APT_OPTIONS[@]}" update
apt-get "${APT_OPTIONS[@]}" install -y --no-install-recommends \
    "$DRIVER_PACKAGE" \
    "linux-headers-$CURRENT_KERNEL" \
    gcc \
    make \
    patch

info "Checking the DKMS build"
if ! dkms status | grep -F "$CURRENT_KERNEL" | grep -Fq "broadcom-sta"; then
    dkms autoinstall -k "$CURRENT_KERNEL"
fi

dkms status | grep -F "$CURRENT_KERNEL" | grep -F "broadcom-sta" ||
    die "DKMS did not install broadcom-sta for $CURRENT_KERNEL."

depmod -a "$CURRENT_KERNEL"

if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u -k "$CURRENT_KERNEL"
fi

info "Loading the Broadcom wl module"
for module in wl b43 brcmsmac brcmfmac bcma ssb; do
    if lsmod | awk '{print $1}' | grep -Fxq "$module"; then
        modprobe -r "$module" || true
    fi
done

if ! modprobe wl; then
    if command -v mokutil >/dev/null 2>&1 &&
        mokutil --sb-state 2>/dev/null | grep -qi enabled; then
        die "The wl module was built but Secure Boot blocked it. Disable Secure Boot or enroll the DKMS signing key, then run this installer again."
    fi
    dmesg | tail -n 80 || true
    die "The wl module failed to load."
fi

if command -v rfkill >/dev/null 2>&1; then
    rfkill unblock wifi || true
fi
if command -v nmcli >/dev/null 2>&1; then
    nmcli radio wifi on || true
fi

WIRELESS_INTERFACE=""
if command -v udevadm >/dev/null 2>&1; then
    udevadm settle || true
fi

for _attempt in {1..10}; do
    for interface_path in /sys/class/net/*; do
        [[ -e "$interface_path/device/driver/module" ]] || continue
        module_path="$(readlink -f "$interface_path/device/driver/module")"
        if [[ "$(basename -- "$module_path")" == "wl" ]]; then
            WIRELESS_INTERFACE="$(basename -- "$interface_path")"
            break 2
        fi
    done
    sleep 1
done

if command -v nmcli >/dev/null 2>&1; then
    nmcli device status || true
fi

[[ -n "$WIRELESS_INTERFACE" ]] ||
    die "The wl module loaded, but no network interface was created."

info "Installation completed"
echo "Driver:    $DRIVER_PACKAGE $DRIVER_VERSION"
echo "Kernel:    $CURRENT_KERNEL"
echo "Interface: $WIRELESS_INTERFACE"
echo
echo "Wi-Fi should now appear in Ubuntu's network menu."
