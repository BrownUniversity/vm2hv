# vcd_to_vcenter.ps1 - Downloads and converts a VM from vCloud Director to vCenter

# USER VARIABLES
$vm_name = "pmailrelayanma1" # VM we ultimately want to convert
$dns_suffix = "services.brown.edu" # DNS suffix for the VM. Used if running a script on the VM prior to conversion
$vapp_name = "pmailrelayanma1" # vApp name. Will usually equal $vm_name, but not always. See instruction doc
$dest_dc = "PRD" # Destination datastore in vCenter
$dest_cluster = "prd500-cluster" # Destination cluster in vCenter
$dest_datastore = "ds-p5-sc5020-lun002b" # Destination datastore in vCenter
$dest_network = "vcd_migration" # Destination network in vCenter.
$vm_command = "" # Command to run on the VM prior to migration, if desired
$poweron_vm_at_destination = $false # If $true, the VM will be powered on after migration is complete

# Set some execution environment variables - I use LastPass and set these environment variables prior to execution. Don't save them in a script file.
$vcd_server = $Env:VCD_SERVER
$vcd_username = $Env:VCD_USERNAME
$vcd_password = $Env:VCD_PASSWORD
$vcd_org = $Env:VCD_ORG

$vsphere_server = $Env:VSPHERE_SERVER
$vsphere_username = $Env:VSPHERE_USERNAME
$vsphere_password = $Env:VSPHERE_PASSWORD

# Don't touch the stuff below unless you know what you're doing

$vcd_vdc = "Production"
# If we use a temporary vApp for migration, this will be set to true
$temporary_vapp_in_use = $false

# Create VCD and vCenter instances

Connect-CIServer -Server $vcd_server -Org $vcd_org -User $vcd_username -Password $vcd_password
Connect-VIServer -Server $vsphere_server -User $vsphere_username -Password $vsphere_password

# Load the VM and vApp PS objects with data
$source_vm = Get-CIVM -Name $vm_name
$source_vapp = Get-CIVapp -Name $vapp_name

# Make sure the user actually wants to continue when a vApp contains multiple VMs
If (($source_vapp | Get-CIVM | Measure-Object).Count -gt 1) {
    Write-Output "The vApp contains more than one VM. Assuming you want only one VM. vCloud Director CLI must be installed to continue."
    ((Get-Command "vcd" -ErrorAction SilentlyContinue) -eq $null) {
        Write-Output "Command vcd not found. Migration will not continue."
        exit
    }
    Write-Output "Dropping into vcd-cli to complete VM copy"
    vcd login $vcd_server $vcd_org $vcd_username --password $vcd_password --vdc ${vcd_vdc} -w -i
    vcd vapp create ${vapp_name}_vc_migration
    vcd vm shutdown ${vapp_name} ${vm_name}
    vcd vm copy --target-vapp-name ${vapp_name}_vc_migration --target-vm-name ${vm_name} ${vapp_name} ${vm_name}
    $source_vapp = Get-CIVM -Name ${vapp_name}_vc_migration
    $temporary_vapp_in_use = $true
}

# Run a user-provided command on the VM prior to migration
If ($vm_command -ne "") {
    Write-Output "User requested to run a command on the remote VM prior to shutdown"
    ssh ${vm_local_username}@${vm_name}.${dns_suffix} ${vm_command}
}

# Set the migrated VM's name
$dest_vm_name = "${vm_name}-vcd-migrated"

# Have to have the source's network name, so grab it
$source_network = ($source_vm | Get-CINetworkAdapter).ExtensionData.Network

# Shutdown the source VM and vApp and spin until they are shut off
$source_vapp | Stop-CIVappGuest -Confirm:$false

# Poll for VM to be shut down
while ((Get-CIVM $source_vm).Status -eq "PoweredOn") {
    Start-Sleep -s 10
    Write-Output "Waiting on VM to shut down..."
}

# Make sure the vApp is in a stopped state
$source_vapp | Stop-CIVapp -Confirm:$false

# Download and Import the VM to vCenter
Write-Output "Starting download of OVF from vCloud. This will take a while. Grab a beverage."
$start_time = (Get-Date).Second
ovftool --datastore=${dest_datastore} --net:"${source_network}=${dest_network}" --name=${dest_vm_name} "vcloud://${vcd_username}:${vcd_password}@${vcd_server}/cloud?org=${vcd_org}&vdc=Production&catalog=Brown%20Catalog&vapp=${vapp_name}" "vi://${vsphere_username}:${vsphere_password}@${vsphere_server}/${dest_dc}/host/${dest_cluster}/Resources"
$end_time = (Get-Date).Second

Write-Output "Download took $($end_time - $start_time) seconds to run."

# Get the VM information from vCenter and disconnect the network
$dest_vm = Get-VM $dest_vm_name
$dest_vm | Get-NetworkAdapter | Set-NetworkAdapter -Connected $false

# If variable is set, power on the VM at the destination vCenter
If ($poweron_vm_at_destination) {
    $dest_vm | Start-VM
}

If ($temporary_vapp_in_use) {
    $confirmation = Read-Host "Delete temporary vCloud vApp? (y/n)"
    if ($confirmation -eq 'y') {
        vcd vapp delete -y ${source_vapp}.Name
    }
}
