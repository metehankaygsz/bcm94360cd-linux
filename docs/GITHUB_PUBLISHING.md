# GitHub Publishing Checklist

Repository name:

```text
bcm94360cd-linux
```

Suggested description:

```text
Offline Broadcom BCM94360CD and BCM4360 Wi-Fi driver installer for Ubuntu Linux
```

Topics:

```text
broadcom
bcm94360cd
bcm4360
linux
ubuntu
wifi
dkms
offline-installer
mac-pro-2013
ubuntu-2604
```

After review, create the remote without pushing:

```bash
gh repo create bcm94360cd-linux --public --source=. --remote=origin
```

When publication is approved:

```bash
git push -u origin main
git push origin v1.0.0

gh repo edit \
  --description "Offline Broadcom BCM94360CD and BCM4360 Wi-Fi driver installer for Ubuntu Linux" \
  --add-topic broadcom \
  --add-topic bcm94360cd \
  --add-topic bcm4360 \
  --add-topic linux \
  --add-topic ubuntu \
  --add-topic wifi \
  --add-topic dkms \
  --add-topic offline-installer \
  --add-topic mac-pro-2013 \
  --add-topic ubuntu-2604

gh release create v1.0.0 \
  dist/bcm94360cd-linux-ubuntu-26.04-7.0.0-14-generic.tar.gz \
  dist/bcm94360cd-linux-ubuntu-26.04-7.0.0-14-generic.tar.gz.sha256 \
  --title "BCM94360CD Linux v1.0.0" \
  --notes-file releases/v1.0.0.md
```

