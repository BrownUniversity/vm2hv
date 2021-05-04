# Steps to Starwind Migrate Linux VM

## Assumptions

* Access to Vmware
* Access to VMM
* Access to [Adjust-VMs.ps1 script](https://github.com/rem14rem/HyperVProvision)
* Access to Pansunixcit ansible
* Starwind Conversion software

## Gather info about VM

These are needed for each VM:

* Subnet(s) it will be on
* IP of VMware host is sits
* IP of HyperV it will go to
* Adjustment data
  * Adjustment data file format example.

*HOSTNAME,VMM CENTER,BACKUP TAG*

```
qhostcit,HVIC01.hvi.brown.edu,intBackup_2wk
```

## Procedure

1. Pull and run starwinds.sh script, using ansible
```
# ansible qhostcit* -m shell -a "wget https://raw.githubusercontent.com/BrownUniversity/vm2hv/main/starwinds.sh ; chmod 755 starwinds.sh; ./starwinds.sh -y" -b

```
This converts and shutdown the VM.

2. Convert in Starwind
   1. Wait until VM is stopped
   2. Record duration 

3. Refresh VM in VMM
4. Change the Network and OS in VMM properties
   1. Click Properties, and modify "Operating System"
   2. Click "Hardware Properties -> Network Adapter 1"
   3. Click "Browse" and find subnet
   4. Click OK

5. Start PowerShell as Administrator 
6. Run Adjust-VMs.ps1 script with adjustments data file as argument
```
Adjust-VMs.ps1 qhostcit.txt
```

7. Validate VM
```
ping qhostcit.services.brown.edu
```