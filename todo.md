# Stuff I think this needs

- [X] Test function with info output
- [X] RHEL8 don't assume no eth ifaces
- [X] Help/Usage text
- [X] Fix interface enumeration/label issue in rhel7 and rhel8 functions
- [X] Test on VM with multiple interfaces
  - [X] RHEL 7
  - [X] RHEL 8
- [X] Add mkinit/dracut to RHEL 7 (some systems need it)
- [ ] Add Ubuntu support - Integrate into backup, tools and restore
  - [X] os detect
  - [X] backup
  - [X] vmtools
  - [X] iface detect (make universal function)
  - [X] network fix - Own functions (18 and 20)
    ens160 = eth0
    ens192 = eth1
    ens224 = eth2
    ens??? = eth3
  - [ ] restore