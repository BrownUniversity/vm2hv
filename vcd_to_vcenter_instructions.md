# VCD to vCenter Conversion Script

This script assists in the migration of VMs from vCloud Director instances to vCenter. It attempts to strike a balance between robustness and simplicity, likely achieving neither. In any case, this script requires some setup prior to execution, which is explained below.

## Requirements

* powershell Core > 7.1
* VMware PowerCLI > 12.2

## Optional Software

* LastPass
* ssh (for remote script execution)
* vcd-cli (for handling multiple VM vApps. Instructions: http://vmware.github.io/vcd-cli/

### Getting Started

`vcd_to_vcenter` handles migration in a few steps:

* A session on the source vCloud Director Instance and the destination vCenter is created
* (Optional) A command is executed on the source VM via SSH if desired
* The source VM is powered off
* On the source, an OVF-based package of the VM disks is created and downloaded
* On the destination, a VM shell and vApp are created and the VM data is copied into it without touching the computer running the script
* The VM's network is disconnected and placed on a dummy network with no uplinks (if using the defaults) on the vCenter destination
* The destination VM copy can be powered on if desired via the `$poweron_vm_at_destination` variable

Once the script is complete, you are free to deal with the VM in whatever manner is appropriate from vCenter, including all traditional HyperV conversion tools.

The script requires the following information to be set as environment variables:

```powershell
$vcd_server = $Env:VCD_SERVER
$vcd_username = $Env:VCD_USERNAME
$vcd_password = $Env:VCD_PASSWORD
$vcd_org = $Env:VCD_ORG

$vsphere_server = $Env:VSPHERE_SERVER
$vsphere_username = $Env:VSPHERE_USERNAME
$vsphere_password = $Env:VSPHERE_PASSWORD
```

The advisable way to do this is to use `lastpass-cli`, or `PSLastPass` (https://www.powershellgallery.com/packages/PSLastPass/1.2.1) to load these variables into the `VCD_` and `VSPHERE_` prefixes prior to running the script. Doing so avoids the terrible temptation to ever write down a password.

Next, you can define the following required variables in the script:

```powershell
$vm_name = "" # VM we ultimately want to convert
$vapp_name = "myvcdvm" # vApp name. Will usually equal $vm_name, but not always. See instruction doc
$dest_dc = "mylocaldc" # Destination datastore in vCenter
$dest_cluster = "mylocal-cluster" # Destination cluster in vCenter
$dest_datastore = "dcdatastore" # Destination datastore in vCenter
$dest_network = "vcd_migration" # Destination network in vCenter.
$poweron_vm_at_destination = $false # If $true, the VM will be powered on after migration is complete
```

These variables are optional if you want to execute commands on the VM prior to migration

```powershell
$dns_suffix = "vcloud.tld.com" # DNS suffix for the VM. Used if running a script on the VM prior to conversion
$vm_command = "hostname" # Command to run on the VM prior to migration, if desired
```

### Executing a migration

With the above variables filled out in the script, execute the script with `./vcd_to_vcenter.ps1` or `pwsh vcd_to_vcenter.ps1` if not in a current PS session. The script will probably take a while and advise you to get a drink because the migration involves two steps, a conversion to OVF and a download step. The speed of these tasks is entirely dependent on the size of the VM.

### Handling multiple VM vApps

Newly added is a feature that allows the script to handle vApps with multiple VMs while maintaining uptime for the rest of the VMs in the vApp. This is accomplished using the vcd-cli python package. Install instructions are here: http://vmware.github.io/vcd-cli/. If this package is installed, the script will automatically shutdown the target VM, create a new vApp, and copy the VM into it. The migration will then continue using the temporary vApp.

When migration is complete, you will be prompted to remove the temporary vApp. It is generally safe and recommended to do so.

### Known Issues

A vApp can contain multiple VMs. The script does have a safety switch to catch if a VM in part of a vApp with more than one VM so unintended VM shutdown does not occur. Moving a vApp with multiple VMs is possible, but may take an extremely long time and increases the chance of transfer failure (of which there is no recovery). To increase the chances of success, it is recommended that you create a temporary vApp and copy your VM into it.