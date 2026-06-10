# Compatibility

## Confirmed

| Computer | Module | PCI ID | OS | Kernel | Status |
| --- | --- | --- | --- | --- | --- |
| Mac Pro Late 2013 (`MacPro6,1`, A1481) | BCM94360CD | `14e4:43a0` | Ubuntu 26.04 LTS | `7.0.0-14-generic` | Tested |

## Potential Factory or Replacement-Card Candidates

The following Apple models have documented BCM94360CD hardware or compatible
OEM replacement boards. They have **not** been tested with this installer.

| Computer | Identifier | Notes |
| --- | --- | --- |
| iMac 21.5-inch Late 2013 | `iMac14,1`, A1418 | BCM94360CD identified in teardown |
| iMac 27-inch Late 2013 | `iMac14,2`, A1419 | Compatible OEM AirPort/Bluetooth board |
| iMac 21.5-inch Mid 2014 | `iMac14,4`, A1418 | Compatible OEM AirPort/Bluetooth board |
| iMac Retina 5K 27-inch Late 2014 | `iMac15,1`, A1419 | BCM94360CD identified in teardown |

Sources:

- [iFixit: Late 2013 21.5-inch iMac teardown](https://www.ifixit.com/Teardown/iMac+Intel+21.5-Inch+EMC+2638+Teardown/17829)
- [iFixit: Late 2013-Late 2014 iMac AirPort/Bluetooth board](https://www.ifixit.com/products/imac-intel-21-5-or-27-late-2013-late-2014-airport-bluetooth-board)
- [iFixit: Late 2014 Retina 5K iMac teardown](https://www.ifixit.com/Teardown/iMac+Intel+27-Inch+Retina+5K+Display+Teardown/30260)

## Potential Adapter-Based Candidates

These systems can be fitted with BCM94360CD upgrade kits, but physical
installation, Bluetooth USB wiring, antenna routing, and PCIe adapters vary.
They have **not** been tested with this installer.

- Mac Pro 2006 (`MacPro1,1`)
- Mac Pro 2007 (`MacPro2,1`)
- Mac Pro 2008 (`MacPro3,1`)
- Mac Pro 2009 (`MacPro4,1`)
- Mac Pro 2010-2012 (`MacPro5,1`)
- Standard PCs using a compatible PCIe adapter and genuine BCM94360CD module

The installer supports only devices that enumerate as:

```text
14e4:43a0
```

Check before installation:

```bash
lspci -nn | grep -i broadcom
```

Similar-looking modules can use a different chipset or PCI ID and are outside
the current support scope.

