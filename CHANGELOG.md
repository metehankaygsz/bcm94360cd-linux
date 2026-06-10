# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-10

### Added

- Offline installer for Broadcom BCM94360CD / BCM4360 PCI ID `14e4:43a0`.
- Ubuntu 26.04 LTS release bundle for kernel `7.0.0-14-generic`.
- Local-only APT repository with complete DKMS build dependencies.
- Package checksum verification and target-system validation.
- Automatic Broadcom `wl` DKMS build, module loading, and interface checks.
- Kernel-specific bundle builder using official Ubuntu repositories.
- Installation logging and Secure Boot diagnostics.

[1.0.0]: https://github.com/metehankaygsz/bcm94360cd-linux/releases/tag/v1.0.0

