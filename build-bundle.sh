#!/usr/bin/env bash
set -Eeuo pipefail

UBUNTU_VERSION="26.04"
DEFAULT_KERNEL="7.0.0-14-generic"
KERNEL_RELEASE="$DEFAULT_KERNEL"
OUTPUT_ROOT=""

usage() {
    cat <<EOF
Usage: $0 [--kernel RELEASE] [--output DIRECTORY]

Build an offline Broadcom BCM94360CD / BCM4360 Wi-Fi driver bundle for Ubuntu 26.04.

Options:
  --kernel RELEASE   Exact target kernel from 'uname -r'
                     (default: $DEFAULT_KERNEL)
  --output DIRECTORY Parent output directory (default: ./dist)
  -h, --help         Show this help
EOF
}

while (($#)); do
    case "$1" in
        --kernel)
            [[ $# -ge 2 ]] || { echo "Missing value for --kernel" >&2; exit 2; }
            KERNEL_RELEASE="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { echo "Missing value for --output" >&2; exit 2; }
            OUTPUT_ROOT="$2"
            shift 2
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

if [[ ! "$KERNEL_RELEASE" =~ ^[0-9][0-9A-Za-z.+~-]*-generic$ ]]; then
    echo "Invalid kernel release: $KERNEL_RELEASE" >&2
    exit 2
fi

command -v docker >/dev/null 2>&1 || {
    echo "Docker is required to build the Ubuntu amd64 bundle." >&2
    exit 1
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ROOT="${OUTPUT_ROOT:-"$SCRIPT_DIR/dist"}"
BUNDLE_NAME="bcm94360cd-linux-ubuntu-${UBUNTU_VERSION}-${KERNEL_RELEASE}"
BUNDLE_DIR="$OUTPUT_ROOT/$BUNDLE_NAME"
PACKAGES_DIR="$BUNDLE_DIR/packages"
ARCHIVE="$OUTPUT_ROOT/$BUNDLE_NAME.tar.gz"

rm -rf -- "$BUNDLE_DIR"
mkdir -p -- "$PACKAGES_DIR"

echo "Downloading Ubuntu $UBUNTU_VERSION amd64 packages for $KERNEL_RELEASE..."
docker run --rm --platform linux/amd64 \
    -e TARGET_KERNEL="$KERNEL_RELEASE" \
    -v "$BUNDLE_DIR:/bundle" \
    "ubuntu:$UBUNTU_VERSION" \
    bash -lc '
        set -Eeuo pipefail
        export DEBIAN_FRONTEND=noninteractive

        packages=/bundle/packages
        mkdir -p "$packages"
        mkdir -p "$packages/partial"
        apt-get update
        apt-get --download-only -y --no-install-recommends \
            -o Dir::Cache::archives="$packages" \
            install \
                broadcom-sta-dkms \
                "linux-headers-${TARGET_KERNEL}" \
                gcc \
                make \
                patch

        apt-get install -y --no-install-recommends dpkg-dev
        cd "$packages"
        rm -rf partial lock
        dpkg-scanpackages --multiversion . /dev/null > Packages
        gzip -9cn Packages > Packages.gz
        sha256sum ./*.deb > SHA256SUMS

        driver_package="$(find "$packages" -maxdepth 1 \
            -name "broadcom-sta-dkms_*.deb" -print -quit)"
        test -n "$driver_package"
        dpkg-deb -x "$driver_package" /tmp/broadcom-sta
        mkdir -p /bundle/THIRD_PARTY_LICENSES
        cp /tmp/broadcom-sta/usr/share/doc/broadcom-sta-dkms/copyright \
            /bundle/THIRD_PARTY_LICENSES/broadcom-sta-dkms.txt
    '

DRIVER_PACKAGE="$(find "$PACKAGES_DIR" -maxdepth 1 -name 'broadcom-sta-dkms_*.deb' -print -quit)"
[[ -n "$DRIVER_PACKAGE" ]] || {
    echo "The Broadcom driver package was not downloaded." >&2
    exit 1
}

DRIVER_FILENAME="$(basename -- "$DRIVER_PACKAGE")"
DRIVER_VERSION="${DRIVER_FILENAME#broadcom-sta-dkms_}"
DRIVER_VERSION="${DRIVER_VERSION%_amd64.deb}"

cp -- "$SCRIPT_DIR/install.sh" "$BUNDLE_DIR/install.sh"
chmod 0755 "$BUNDLE_DIR/install.sh"

cat > "$BUNDLE_DIR/bundle.env" <<EOF
BUNDLE_VERSION=1
UBUNTU_VERSION=$UBUNTU_VERSION
KERNEL_RELEASE=$KERNEL_RELEASE
ARCHITECTURE=amd64
PCI_VENDOR=0x14e4
PCI_DEVICE=0x43a0
DRIVER_PACKAGE=broadcom-sta-dkms
DRIVER_VERSION=$DRIVER_VERSION
EOF

cat > "$BUNDLE_DIR/README.txt" <<EOF
BCM94360CD Linux Offline Installer
==================================

Target: Ubuntu $UBUNTU_VERSION amd64
Kernel: $KERNEL_RELEASE
Card:   Broadcom BCM4360 (PCI 14e4:43a0)
Driver: broadcom-sta-dkms $DRIVER_VERSION

On the offline Ubuntu system:

  1. Confirm that 'uname -r' prints exactly:
       $KERNEL_RELEASE

  2. Run:
       sudo ./install.sh

Log file:
  /var/log/bcm94360cd-linux-installer.log

This bundle includes third-party software. Review:
  THIRD_PARTY_LICENSES/broadcom-sta-dkms.txt
EOF

rm -f -- "$ARCHIVE"
tar -C "$OUTPUT_ROOT" -czf "$ARCHIVE" "$BUNDLE_NAME"

if command -v sha256sum >/dev/null 2>&1; then
    (
        cd "$OUTPUT_ROOT"
        sha256sum "$(basename -- "$ARCHIVE")" > "$(basename -- "$ARCHIVE").sha256"
    )
else
    (
        cd "$OUTPUT_ROOT"
        shasum -a 256 "$(basename -- "$ARCHIVE")" > "$(basename -- "$ARCHIVE").sha256"
    )
fi

echo
echo "Bundle created:"
echo "  $BUNDLE_DIR"
echo "  $ARCHIVE"
echo "  $ARCHIVE.sha256"
echo "  Packages: $(find "$PACKAGES_DIR" -maxdepth 1 -name '*.deb' | wc -l | tr -d ' ')"
echo "  Size: $(du -h "$ARCHIVE" | awk '{print $1}')"
