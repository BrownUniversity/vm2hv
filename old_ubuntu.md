# Migrating OLD Ubuntu versions < 18.04

Older Ubuntu versions which are no longer supported should be modified by hand
during the migration process. This will incure a longer outage.

## VPG and Move

Create VPGs for the VMs. No pre-script is needed for the migration.

## Local changes

Once the VM has been migrated the needed changes will depend on a few
things:

* Did the VM already have an eth interface
  * If yes, nothing further is needed
  * In no, continue
* Is Network Manager being used:
  * If yes, see [NMCLI changes](#NMCLI) below
  * If no, see [interface file changes](#interface) below


### NMCLI



### interface

Edit /etc/network/interfaces and change the ensXXX text to eth0.

Reboot