# vcd_to_vcenter.ps1 - Downloads and converts a VM from vCloud Director to vCenter

# USER VARIABLES
# Set the name of the VM we want to download, the destination VMhost and the destination datastore
$vm_name = "my_vm"
$dest_dc = "my_datacenter"
$dest_cluster = "my_cluster"
$dest_datastore = "my_datastore"
$dest_network = "my_dvs_portgroup"
$poweron_vm_at_destination = $false

# Set some execution environment variables - I use LastPass and set these environment variables prior to execution. Don't save them in a script file.
$vcd_server = $Env:VCD_SERVER
$vcd_username = $Env:VCD_USERNAME
$vcd_password = $Env:VCD_PASSWORD
$vcd_org = $Env:VCD_ORG

$vsphere_server = $Env:VSPHERE_SERVER
$vsphere_username = $Env:VSPHERE_USERNAME
$vsphere_password = $Env:VSPHERE_PASSWORD

# Don't touch the stuff below unless you know what you're doing

# Create VCD and vCenter instances

$vcd_instance = Connect-CIServer -Server $vcd_server -Org $vcd_org -User $vcd_username -Password $vcd_password
$vsphere_instance = Connect-VIServer -Server $vsphere_server -User $vsphere_username -Password $vsphere_password

$source_vm = Get-CIVM -Name $vm_name
$source_vapp = Get-CIVapp -Name $vm_name
$dest_vm_name = "${vm_name}-vcd-migrated"

# Shutdown the source VM and vApp and spin until they are shut off

$source_vapp | Stop-CIVappGuest -Confirm:$false

# Poll for VM to be shut down
while ((Get-CIVM $source_vm).Status -eq "PoweredOn") {
    Start-Sleep -s 10
    Write-Output "Waiting on VM to shut down..."
}

# Make sure the vApp is in a stopped state
$source_vapp | Stop-CIVapp

# Download and Import the VM to vCenter

Write-Output "Starting download of OVF from vCloud. This will take a while. Grab a beverage."
ovftool --datastore=${dest_datastore} --network=${dest_network} "vcloud://${vcd_username}:${vcd_password}@${vcd_server}/cloud?org=${vcd_org}&vdc=Production&catalog=Brown%20Catalog&vapp=${vm_name}" "vi://${vsphere_username}:${vsphere_password}@${vsphere_server}/${dest_dc}/host/${dest_cluster}/Resources/${dest_vm_name}"

# Get the VM information from vCenter and disconnect the network

$dest_vm = Get-VM $dest_vm_name

$dest_vm | Get-NetworkAdapter | Set-NetworkAdapter -Connected $false

# If variable is set, power on the VM at the destination vCenter

If ($poweron_vm_at_destination) {
    $dest_vm | Start-VM
}
