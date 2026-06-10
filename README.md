# BCM94360CD Linux

Offline Broadcom BCM94360CD / BCM4360 Wi-Fi driver installer for Ubuntu.

[![Ubuntu 26.04](https://img.shields.io/badge/Ubuntu-26.04_LTS-E95420?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/26.04/)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-enabled-4EAA25?logo=gnu-bash&logoColor=white)](https://www.shellcheck.net/)
[![License: MIT](https://img.shields.io/badge/Project_License-MIT-blue.svg)](LICENSE)

This project packages Ubuntu's official `broadcom-sta-dkms` driver and the
matching build dependencies into a self-contained archive. It is intended for
machines that cannot connect to the Internet after installing Ubuntu because
the Broadcom `wl` driver is missing.

## Tested Configuration

| Component | Tested value |
| --- | --- |
| Computer | Mac Pro (Late 2013), `MacPro6,1`, A1481 |
| Wireless module | Broadcom BCM94360CD |
| Wi-Fi chipset | Broadcom BCM4360 |
| PCI ID | `14e4:43a0` |
| Operating system | Ubuntu 26.04 LTS amd64 |
| Release kernel | `7.0.0-14-generic` |
| Driver package | `broadcom-sta-dkms` `6.30.223.271-29ubuntu1` |

## Installation

Download both release files:

- `bcm94360cd-linux-ubuntu-26.04-7.0.0-14-generic.tar.gz`
- `bcm94360cd-linux-ubuntu-26.04-7.0.0-14-generic.tar.gz.sha256`

On the offline Ubuntu machine, verify the running kernel:

```bash
uname -r
```

For the `v1.0.0` release, it must print:

```text
7.0.0-14-generic
```

Verify, extract, and install:

```bash
sha256sum -c bcm94360cd-linux-ubuntu-26.04-7.0.0-14-generic.tar.gz.sha256
tar -xzf bcm94360cd-linux-ubuntu-26.04-7.0.0-14-generic.tar.gz
cd bcm94360cd-linux-ubuntu-26.04-7.0.0-14-generic
sudo ./install.sh
```

The installer:

1. Verifies Ubuntu version, CPU architecture, running kernel, and PCI ID.
2. Verifies SHA-256 checksums for every bundled package.
3. Creates an isolated local APT repository without using the network.
4. Installs the matching kernel headers and DKMS build dependencies.
5. Builds and installs the Broadcom `wl` module.
6. Unloads conflicting modules and verifies that a wireless interface appears.

The full installation log is written to:

```text
/var/log/bcm94360cd-linux-installer.log
```

## Other Kernels

DKMS must compile the driver against headers matching the exact running kernel.
If `uname -r` does not match the release bundle, build another bundle on an
Internet-connected computer with Docker:

```bash
./build-bundle.sh --kernel "7.0.0-22-generic"
```

The completed archive and checksum are written to `dist/`.

## Potential Compatibility

Only the Late 2013 Mac Pro configuration above has been tested with this
project. The following systems are potential candidates because they have been
documented with the BCM94360CD module or can use it through an adapter:

- iMac 21.5-inch Late 2013 (`iMac14,1`, A1418)
- iMac 27-inch Late 2013 (`iMac14,2`, A1419)
- iMac 21.5-inch Mid 2014 (`iMac14,4`, A1418)
- iMac Retina 5K 27-inch Late 2014 (`iMac15,1`, A1419)
- Mac Pro 2006-2012 (`MacPro1,1` through `MacPro5,1`) upgraded with a
  BCM94360CD adapter
- PCs using a genuine BCM94360CD module through a compatible PCIe adapter

**These configurations are not tested by this project.** Confirm that Linux
reports PCI ID `14e4:43a0` before attempting installation:

```bash
lspci -nn | grep -i broadcom
```

See [Compatibility](docs/COMPATIBILITY.md) for evidence and limitations.

## Secure Boot

Unsigned DKMS modules may be blocked when Secure Boot is enabled. The installer
detects this condition and reports it. Disable Secure Boot or enroll the DKMS
module-signing key according to your distribution's documented procedure.

## Troubleshooting

See [Troubleshooting](docs/TROUBLESHOOTING.md). When reporting a problem,
include:

```bash
uname -a
lspci -nnk | grep -A3 -i network
dkms status
sudo modprobe wl
```

Also attach `/var/log/bcm94360cd-linux-installer.log`.

## Licensing

The scripts and documentation in this repository are licensed under the
[MIT License](LICENSE).

The generated release bundle contains unmodified Ubuntu packages with their
own licenses. Broadcom's binary component is proprietary and restricted; its
license is included in the bundle under `THIRD_PARTY_LICENSES/`. See
[Third-Party Notices](THIRD_PARTY_NOTICES.md).

## Contributing

Bug reports and tested hardware results are welcome. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes.

