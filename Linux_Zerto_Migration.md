# Steps to migrate VMs to HyperV using Zerto

## Tools used: 
* bash
* ansible
* wget

## Prerequisites:
* Working ansible environment (ppup4cit)
* VPG of VMs to be migrate

## Pre-Migration

On Ppup4cit, run these command in the working ansible environment.

### Pull down and run the  pre-migration script

This will backup important files, fix the networks, and update the kernel

```
# ansible host1*:host2*:host3* -m shell -a "wget -c https://raw.githubusercontent.com/BrownUniversity/vm2hv/main/zerto.sh ; chmod 755 zerto.sh" -b

# ansible host1*:host2*:host3* -m shell -a "./zerto.sh -y" -b
```

## Migrate

The VMs are now ready for the Zerto move. This is done via the zerto WebUI, and is beyond the scope of this document.

## Post-Migration

The VM should now be accessable on the network, but the networks needs to be changed to static.
These are the steps to do that.

### Pull down and run the post-migration script

This will ensure VMware Tools are removed, HyperV tools are installed, and clear the MAC address for the switch to static.

```
# ansible host1*:host2*:host3* -m shell -a -c "wget https://raw.githubusercontent.com/BrownUniversity/vm2hv/main/post-zerto.sh ; chmod 755 post-zerto.sh" -b

# ansible host1*:host2*:host3* -m shell -a "./post-zerto.sh -y" -b
```

### Change Networking

You can now shutdown the VM, and change the properties to set the MAC address to static. HyperV will assign it on boot.

Run the FixVMLatest.ps1 for the VM, then boo it. 

## Complete

The VM should now be running and on the network in HyperV.