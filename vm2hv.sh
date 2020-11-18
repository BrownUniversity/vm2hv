#!/bin/bash

# root or GTFO
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# Variables
SYSC=/etc/sysconfig
NWS=${SYSC}/network-scripts
OSVER=$(lsb_release -r | grep -oP "[0-9]+" | head -1)
IFACES=$(basename -a /sys/class/net/* | grep -v lo)
declare -A IFA
for M in `echo ${IFACES}`; do
  IFA+=(${M})
done


vmtools() {
# vmtools function
  yum -y remove open-vm-tools && yum -y install hyperv-daemons hyperv-tools
  if [ $? -ne 0 ]; then
    echo "YUM command failed. exiting"
    exit 1
  fi
}

backup() {
  echo "Saving network files"
  tar cf /root/vm2hv-BAK.tar ${SYSC}/network ${NWS}/ifcfg-e*
}

rhel7() {
  # rhel 7 function
  vmtools
  backup
  if [[ ${IFACES} != *eth* ]]; then
    # fix the ifaces
    for I in "${!IFA[@]}"; do
      sed "s/${I}/eth${I}/g; /HWADDR/d" ${NWC}/ifcfg-${IFA[$i]} > ${NWS}/ifcfg-eth${I}

    done
          sed -i "s/${IFA[0]}/eth0/" ${SYSC}/network
  else
    # Still remove HWADDR from ethX
    for I in "${!IFA[@]}"; do
      sed -i "/HWADDR/d" ${NWC}/ifcfg-${IFA[$i]}
    done

  fi
## shutdown
}

rhel8() {
# rhel 8 function
  vmtools
  backup
  # fix the ifaces
  for I in "${!IFA[@]}"; do
    sed "s/${I}/eth${I}/g; /HWADDR/d" ${NWC}/ifcfg-${IFA[$i]} > ${NWS}/ifcfg-eth${I}
  done
  sed -i '/GATEWAY/d; /GATEWAYDEV/d' ${SYSC}/network
  # run mkinitrd
  mkinitrd -f -v --with=hid-hyperv --with=hv_utils --with=hv_vmbus --with=hv_storvsc --with=hv_netvsc /boot/initramfs-$(uname -r).img $(uname -r)
## shutdown
}

# OS test: RHEL 7 or RHEL 8
case ${OSVER} in 
  7) 
    rhel7
    ;;
  8) 
    rhel8
    ;;
  *)
    echo "OS version failure"
    exit 1
esac

# reverse it all
