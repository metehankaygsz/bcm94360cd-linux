## Summary

Describe the change and the hardware or kernel it affects.

## Validation

- [ ] `bash -n build-bundle.sh install.sh`
- [ ] `shellcheck build-bundle.sh install.sh tests/test-project.sh`
- [ ] `./tests/test-project.sh`
- [ ] Offline installation tested when package or installer behavior changed

## Licensing

- [ ] No generated archives or Ubuntu packages are committed
- [ ] Third-party notices remain intact

