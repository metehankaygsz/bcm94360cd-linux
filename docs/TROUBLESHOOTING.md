# Troubleshooting

## Kernel Mismatch

The archive must contain headers for the exact running kernel:

```bash
uname -r
```

Build a matching archive on an Internet-connected computer:

```bash
./build-bundle.sh --kernel "<output-from-uname-r>"
```

## Card Not Detected

Confirm the PCI ID:

```bash
lspci -nnk | grep -A3 -i network
```

The supported BCM4360 device ID is `14e4:43a0`.

## Module Did Not Load

Inspect DKMS and kernel messages:

```bash
dkms status
sudo modprobe wl
sudo dmesg | tail -n 100
```

## Secure Boot

If `modprobe wl` reports a key or signature error, Secure Boot is blocking the
DKMS module. Disable Secure Boot or enroll the DKMS signing key using Ubuntu's
documented process.

## Conflicting Modules

The installer attempts to unload `b43`, `brcmsmac`, `brcmfmac`, `bcma`, and
`ssb` before loading `wl`. A reboot may be required if another module is in
active use.

## Installation Log

The complete log is stored at:

```text
/var/log/bcm94360cd-linux-installer.log
```

