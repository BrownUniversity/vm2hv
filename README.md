# vm2hv

## Description

Utilities to assist in migration of RHEL system from ESXi to Hyper-V. 

OS support:
* RHEL 6
* RHEL 7
* RHEL 8
* Ubuntu 18.04

In addition, there is a post-zerto script that will remove vmtools and install
HyperV tools.

## How to Run on Systems or TL;DR

This **should** be what you need to do on the VM for it's conversion. 

### zerto and post-zerto

[Step-by-step with ansible commands here](Linux_Zerto_Migration.md)

When doing zerto migrattions leave VMware until after the migration is complete, where you can then 
run post-zerto.sh

```
# wget https://raw.githubusercontent.com/BrownUniversity/vm2hv/main/zerto.sh ; chmod 755 zerto.sh
# ./zerto.sh -y

# wget https://raw.githubusercontent.com/BrownUniversity/vm2hv/main/post-zerto.sh ; chmod 755 post-zerto.sh
# ./post-zerto.sh -y
```
### Starwinds

This **should** be all you need to do on the VM before it is shutdown for conversion.

```
# wget https://raw.githubusercontent.com/BrownUniversity/vm2hv/main/starwinds.sh ; chmod 755 starwinds.sh
# ./starwinds.sh -y
```
This will config and shutdown the system. Conversion can begin.

## Requires

* bash
* yum

And other standard unix utils. Nothing you need to install.

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