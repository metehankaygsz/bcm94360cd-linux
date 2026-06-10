#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT/build-bundle.sh"
bash -n "$ROOT/install.sh"

grep -Fq 'DEFAULT_KERNEL="7.0.0-14-generic"' "$ROOT/build-bundle.sh"
grep -Fq 'PCI_VENDOR=0x14e4' "$ROOT/build-bundle.sh"
grep -Fq 'PCI_DEVICE=0x43a0' "$ROOT/build-bundle.sh"
grep -Fq 'broadcom-sta-dkms' "$ROOT/build-bundle.sh"
grep -Fq 'bcm94360cd-linux-installer.log' "$ROOT/install.sh"

echo "Project checks passed."
