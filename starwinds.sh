#!/bin/bash
root() {
  # root or GTFO
  if [ "${EUID}" -ne 0 ]
    then echo "Please run as root"
    exit 1
  fi
}

# Variables
BKUP=/root/vm2hv-BAK.tar
IRAMFS=initramfs-$(uname -r).img
SYSC=/etc/sysconfig
UBMODS=/etc/initramfs-tools/modules
NWS=${SYSC}/network-scripts
NETP=/etc/netplan
NPUB=99-netcfg-vmware.yaml
NPHV=99-netcfg-hyperv.yaml
OSDIST=$(lsb_release -d)
OSVER=$(lsb_release -r | grep -oP "[0-9]+" | head -1)
UDEV=/etc/udev/rules.d/70-persistent-net.rules

case ${OSDIST} in
  *[Uu]buntu*)
    OSDIST=ubuntu
    ;;
  *[hH]at*)
    OSDIST=redhat
    ;;
esac


# Help text variables
NORM=`tput sgr0`
BOLD=`tput bold`
REV=`tput smso`

help() {
  # Help info
  echo "Basic usage: ${BOLD}$0 ${NORM}"
  echo -e "This will prep a RHEL 7 or 8  for V2V conversion"
  echo -e "to HyperV. By default it will convert and shutdown."
  echo -e ""
  echo -e "This script will ${BOLD}NOT${NORM} execute conversion without the -y,--yes option"
  echo -e ""
  echo -e "\t${BOLD}-y, --yes${NORM}:\t\tExecute the conversion."
  echo -e "\t${BOLD}-n, --noshutdown${NORM}:\tDo ${BOLD}NOT${NORM} shutdown at the end"
  echo -e "\t${BOLD}-r, --restore${NORM}:\t\tRestore system files"
  echo -e "\t${BOLD}-m, --mkinit${NORM}:\t\tDo ${BOLD}NOT${NORM} run mkinitrd command"
  echo -e "\t${BOLD}-t, --test${NORM}:\t\tShow info about conversion"
  echo -e ""
  echo ""
}

# Code funtions
ifaces() {
  IFACES=$(ls -1 /sys/class/net/ | grep -v lo | grep -E '^ens[0-9]{3}\b|^eth[0-9]{1}\b')
  IFA=($IFACES)
}

vmtools() {
  case ${OSDIST} in
    ubuntu)
      # vmtools function
      if [ "${_test}" -eq 1 ]; then
        echo "apt-get -yq remove open-vm-tools && apt-get -yq install linux-virtual linux-cloud-tools-virtual linux-tools-virtual"
        echo "=========="
      else
        apt-get -yq remove open-vm-tools && apt-get -yq install linux-virtual linux-cloud-tools-virtual linux-tools-virtual
        if [ $? -ne 0 ]; then
          echo "APT command failed. exiting"
          exit 1
        fi
      fi
      ;;
    redhat)
      # vmtools function
      if [ "${_test}" -eq 1 ]; then
        echo "yum -yq -e 0 remove open-vm-tools && yum -yq -e 0 install hyperv-daemons hyperv-tools"
        echo "=========="
      else
        yum -yq -e 0 remove open-vm-tools && yum -yq -e 0 install hyperv-daemons hyperv-tools
        if [ $? -ne 0 ]; then
          echo "YUM command failed. exiting"
          exit 1
        fi
      fi
      ;;
  esac
}

backup() {
  echo "Saving network files"
  case ${OSDIST} in
    redhat)
      if [ "${_test}" -eq 1 ]; then
        echo "tar cvf ${BKUP} ${SYSC}/network ${NWS}/ifcfg-e* ${IRAMFS} ${UDEV}"
        echo "============"
      else  
        tar cvf ${BKUP} ${SYSC}/network ${NWS}/ifcfg-e* /boot/${IRAMFS} ${UDEV}
      fi
      ;;
    ubuntu)
      if [ "${_test}" -eq 1 ]; then
        echo "tar cvf ${BKUP} ${NETP}/${NPUB}"
        echo "============"
      else  
        tar cvf ${BKUP} ${NETP}/${NPUB}
      fi
      ;;
  esac
}

rhel76() {
  # rhel 7 function
  if [ "${_test}" -eq 1 ]; then
    echo "OS Version: RHEL ${OSVER}"
    echo "Interfaces found: ${IFA[@]}"
    echo "=========="
    echo "rm ${UDEV}"
  else
    if [[ "${IFACES}" != *eth* ]]; then
      # fix the ifaces
      for I in "${!IFA[@]}"; do
        sed "s/${IFA[$I]}/eth${I}/g; /HWADDR/d" ${NWS}/ifcfg-${IFA[$I]} > ${NWS}/ifcfg-eth${I}
      done
      # Swap gateway in network file
      sed -i "s/${IFA[0]}/eth0/" ${SYSC}/network
    else
      # Still remove HWADDR from ethX
      for I in "${!IFA[@]}"; do
        sed -i "/HWADDR/d" ${NWS}/ifcfg-${IFA[$I]}
      done
    fi
    rm ${UDEV}
  fi
  if [ "${_mkinit}" -eq 0 ]; then
    if [ "${_test}" -eq 1 ]; then
      echo "mkinitrd -f -v --with=hid-hyperv --with=hv_utils --with=hv_vmbus --with=hv_storvsc --with=hv_netvsc /boot/initramfs-$(uname -r).img $(uname -r)"
      
    else
      # run mkinitrd
      mkinitrd -f -v --with=hid-hyperv --with=hv_utils --with=hv_vmbus --with=hv_storvsc --with=hv_netvsc /boot/initramfs-$(uname -r).img $(uname -r)
    fi
  fi
}

rhel8() {
  # rhel 8 function
  if [ "${_test}" -eq 1 ]; then
    echo "OS Version: RHEL ${OSVER}"
    echo "Interfaces found: ${IFA[@]}"
    echo "=========="
    echo "sed -i '/GATEWAY/d; /GATEWAYDEV/d' ${SYSC}/network"
  else
    if [[ "${IFACES}" != *eth* ]]; then
      # fix the ifaces
      for I in "${!IFA[@]}"; do
        sed "s/${IFA[$I]}/eth${I}/g; /HWADDR/d" ${NWS}/ifcfg-${IFA[$I]} > ${NWS}/ifcfg-eth${I}
      done
    else
      # Still remove HWADDR from ethX
      for I in "${!IFA[@]}"; do
        sed -i "/HWADDR/d" ${NWS}/ifcfg-${IFA[$I]}
      done
    fi
    # Remove GATEWAY* from network file
    sed -i '/GATEWAY/d; /GATEWAYDEV/d' ${SYSC}/network
  fi
  if [ "${_mkinit}" -eq 0 ]; then
    if [ "${_test}" -eq 1 ]; then
      echo "mkinitrd -f -v --with=hid-hyperv --with=hv_utils --with=hv_vmbus --with=hv_storvsc --with=hv_netvsc /boot/initramfs-$(uname -r).img $(uname -r)"
    else
      # run mkinitrd
      mkinitrd -f -v --with=hid-hyperv --with=hv_utils --with=hv_vmbus --with=hv_storvsc --with=hv_netvsc /boot/initramfs-$(uname -r).img $(uname -r)
    fi
  fi
}

ubuntu() {
  # ubuntu function
  ## Check test
  if [ "${_test}" -eq 1 ]; then
    echo "OS Version: Ubuntu ${OSVER}"
    echo "Interfaces found: ${IFA[@]}"
    echo "=========="
  else
    if [[ "${IFACES}" != *eth* ]]; then
      # Sed out interfaces
      sed 's/ens160/eth0/g ; s/ens192/eth1/g ; s/ens224/eth2/g' ${NETP}/${NPUB} > ${NETP}/${NPHV}
      if [ -f ${NETP}/${NPHV} ] ; then 
        rm ${NETP}/${NPUB}
      else
        echo "NETWORK ISSUE, STOPPING"
        exit 1
      fi
    else
      echo "No IFACES to change."
    fi
  fi
}

poweroff() {
  if [[ "${_test}" -eq 1 ]] || [[ "${_noshutdown}" -eq 1 ]]; then
    echo "No shutdown performed"
    echo "=========="
  ## shutdown
  else
    echo "Shutting down in 5 sec. CTRL-C to stop" && sleep 5
    shutdown -h now
  fi
}

# reverse it all
restore() {
  case ${OSDIST} in
    redhat)
      if [ "${_test}" -eq 1 ]; then
        echo "TAR location: ${BKUP}"
        echo "Packages: "
        echo -e "\tInstall: open-vm-tools"
        echo -e "\tRemove: hyperv-daemons hyperv-tools"
        echo "=========="
        exit $?
      else
        # Get rid of old files
        rm ${NWS}/ifcfg-e*
        # Restore tar file, uninstall hyperV tools, install open-vm-tools
        cd / ; tar xvf ${BKUP} && ( yum -yq -e 0 install open-vm-tools && yum -yq -e 0 remove hyperv-daemons hyperv-tools )
        EXIT=$?
        if [ $EXIT -gt 0 ]; then
          echo "Restore failed. Please check ${BKUP}"
          echo "=========="
          exit $EXIT
        else
          echo "Restore complete"
          echo "=========="
          exit $EXIT
        fi
      fi
      ;;
    ubuntu)
      if [ "${_test}" -eq 1 ]; then
        echo "TAR location: ${BKUP}"
        echo "Packages: "
        echo -e "\tInstall: open-vm-tools"
        echo -e "\tRemove: "
        echo "=========="
        exit $?
      else
        # Get rid of old files
        rm ${NETP}/${NPHV}
        # Restore tar file, uninstall hyperV tools, install open-vm-tools
        cd / ; tar xvf ${BKUP} && ( apt-get -yq install open-vm-tools && apt-get -yq remove linux-virtual linux-cloud-tools-virtual linux-tools-virtual )
        EXIT=$?
        if [ $EXIT -gt 0 ]; then
          echo "Restore failed. Please check ${BKUP}"
          echo "=========="
          exit $EXIT
        else
          echo "Restore complete"
          echo "=========="
          exit $EXIT
        fi
      fi
      ;;
  esac

}

# CLInt GENERATED_CODE: start
# Default values
_noshutdown=0
_test=0
_restore=0
_mkinit=0

# No-arguments is not allowed
[ $# -eq 0 ] && help && exit 1

# Converting long-options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
"--noshutdown") set -- "$@" "-n";;
"--test") set -- "$@" "-t";;
"--restore") set -- "$@" "-r";;
"--yes") set -- "$@" "-y";;
"--mkinit") set -- "$@" "-m";;
  *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'hntrvym' OPT; do
    case $OPT in
        h) help
           exit 1 ;;
        n) _noshutdown=1 ;;
        t) _test=1 ;;
        r) _restore=1 ;;
        y) _yes=1 ;;
        m) _mkinit=1 ;;
        \?) print_illegal $@ >&2;
            echo "---"
            help
            exit 1
            ;;
    esac
done
# CLInt GENERATED_CODE: end

# Execute 
if [ "${_test}" -eq 1 ]; then
  echo "=====TESTING ONLY====="
  echo "====NO CHANGES MADE==="
  echo ""
else
  root
fi

if [ "${_restore}" -eq 1 ]; then
  restore
  exit $?
fi

# OS test: RHEL or Ubuntu
case ${OSDIST} in
  ubuntu)
    case ${OSVER} in
      18)
        OSDIST=ubuntu
        ifaces
        backup
        vmtools
        ubuntu
        poweroff
        ;;
      20)
        OSDIST=ubuntu
        ifaces
        backup
        vmtools
        ubuntu
        poweroff
        ;;
      *)
        echo "OS Version failure"
        echo ${OSVER}
        exit 1
    esac
    ;;
  redhat)
  # OS test: RHEL 7 or RHEL 8
    case ${OSVER} in 
      7|6) 
        OSDIST=redhat
        ifaces
        backup
        vmtools
        rhel76
        poweroff
        ;;
      8) 
        OSDIST=redhat
        ifaces
        backup
        vmtools
        rhel8
        poweroff
        ;;
      *)
        echo "OS version failure"
        exit 1
    esac
    ;;
  *) 
    echo "No valid OS found:"
    echo ${OSDIST}
    exit 1
  esac