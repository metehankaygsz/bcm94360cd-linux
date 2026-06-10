# Contributing

Contributions should remain focused on reliable offline installation of the
Broadcom BCM94360CD / BCM4360 `wl` driver.

## Reporting Hardware Results

Open a hardware compatibility report and include:

- Computer manufacturer and exact model
- Wireless module marking
- `lspci -nnk | grep -A3 -i network`
- Ubuntu version and `uname -r`
- Whether installation succeeded
- Relevant installer log excerpts

Do not report a model as supported unless the installer completed and Wi-Fi
was used successfully.

## Development

Validate shell scripts before submitting changes:

```bash
bash -n build-bundle.sh install.sh
shellcheck build-bundle.sh install.sh
./tests/test-project.sh
```

Changes to package selection or installer behavior should also be tested in a
clean Ubuntu 26.04 amd64 environment without network access.

## Pull Requests

- Keep changes narrowly scoped.
- Explain the target hardware and kernel.
- Document validation performed.
- Do not commit generated archives or Ubuntu `.deb` packages.
- Preserve third-party license notices.

