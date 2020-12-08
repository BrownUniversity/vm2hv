# vm2hv

## Description

Utility to assist in migration of RHEL system from ESXi to Hyper-V. 

OS support:
* RHEL 6
* RHEL 7
* RHEL 8

(Ubuntu support in feat branches)

## How to Run on Systems or TL;DR

This **should** be all you need to do on the VM before it is shutdown for conversion.

```
# wget https://raw.githubusercontent.com/BrownUniversity/vm2hv/main/vm2hv.sh ; chmod 755 vm2hv.sh
# ./vm2hv.sh -y
```
This will config and shutdown the system. Conversion can begin.

## Requires

* bash
* yum

And other standard unix utils. Nothing you need to install.

## Usage

Basic usage: *./vm2hv.sh*
This will prep a RHEL 7 or 8 for V2V conversion
to HyperV. By default it will convert and shutdown.

This script will *NOT* execute conversion without the -y,--yes option

        -y, --yes:              Execute the conversion.
        -n, --noshutdown:       Do *NOT* shutdown at the end
        -t, --test:             Show info about conversion
        -r, --restore:          Restore system files

## What is does

This script does these things to a running VM to prep it for migration:"
* Backup config files
* Change the network interfaces names (if needed)
* Remove **VMWare tools** (open-vm-tools)
* Install **HyperVisor tools** (hyperv-daemons hyperv-tools)
* Inject drivers into boot image (initrd)
* Restore from backup file (-r option)
* Show what will be done (-t option)
* Shutdown (can be disabled with -n)

## Development

https://github.com/BrownUniversity/vm2hv