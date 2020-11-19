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
IRAMFS=/boot/initramfs-$(uname -r).img
SYSC=/etc/sysconfig
NWS=${SYSC}/network-scripts
OSVER=$(lsb_release -r | grep -oP "[0-9]+" | head -1)
IFACES=$(basename -a /sys/class/net/* | grep -v lo)
IFA=($IFACES)

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
  echo -e "\t${BOLD}-t, --test${NORM}:\t\tShow info about conversion"
  echo -e "\t${BOLD}-r, --restore${NORM}:\t\tRestore system files"
  echo -e ""
  echo ""
}

# Code funtions
vmtools() {
  # vmtools function
  if [ "${_test}" -eq 1 ]; then
    echo "yum -y remove open-vm-tools && yum -y install hyperv-daemons hyperv-tools"
  else
    yum -y remove open-vm-tools && yum -y install hyperv-daemons hyperv-tools
    if [ $? -ne 0 ]; then
      echo "YUM command failed. exiting"
      exit 1
    fi
  fi
}

backup() {
  echo "Saving network files"
  if [ "${_test}" -eq 1 ]; then
    echo "tar cf ${BKUP} ${SYSC}/network ${NWS}/ifcfg-e* ${IRAMFS}"
  else  
    tar cf ${BKUP} ${SYSC}/network ${NWS}/ifcfg-e* ${IRAMFS}
  fi
}

rhel7() {
  # rhel 7 function
  if [ "${_test}" -eq 1 ]; then
    echo "OS Version: RHEL 7"
    echo "Interfaces found: ${IFA[@]}"
  else
    if [[ "${IFACES}" != *eth* ]]; then
      # fix the ifaces
      for I in "${!IFA[@]}"; do
        sed "s/${I}/eth${I}/g; /HWADDR/d" ${NWC}/ifcfg-${IFA[$i]} > ${NWS}/ifcfg-eth${I}
      done
      # Swap gateway in network file
      sed -i "s/${IFA[0]}/eth0/" ${SYSC}/network
    else
      # Still remove HWADDR from ethX
      for I in "${!IFA[@]}"; do
        sed -i "/HWADDR/d" ${NWC}/ifcfg-${IFA[$i]}
      done
    fi
  fi
}

rhel8() {
  # rhel 8 function
  if [ "${_test}" -eq 1 ]; then
    echo "OS Version: RHEL 7"
    echo "Interfaces found: ${IFA[@]}"
  else
    if [[ "${IFACES}" != *eth* ]]; then
      # fix the ifaces
      for I in "${!IFA[@]}"; do
        sed "s/${I}/eth${I}/g; /HWADDR/d" ${NWC}/ifcfg-${IFA[$i]} > ${NWS}/ifcfg-eth${I}
      done
    else
      # Still remove HWADDR from ethX
      for I in "${!IFA[@]}"; do
        sed -i "/HWADDR/d" ${NWC}/ifcfg-${IFA[$i]}
      done
    fi
  fi
  if [ "${_test}" -eq 1 ]; then
    echo "sed -i '/GATEWAY/d; /GATEWAYDEV/d' ${SYSC}/network"
    echo "mkinitrd -f -v --with=hid-hyperv --with=hv_utils --with=hv_vmbus --with=hv_storvsc --with=hv_netvsc /boot/initramfs-$(uname -r).img $(uname -r)"
  else
    # Remove GATEWAY* from network file
    sed -i '/GATEWAY/d; /GATEWAYDEV/d' ${SYSC}/network
    # run mkinitrd
    mkinitrd -f -v --with=hid-hyperv --with=hv_utils --with=hv_vmbus --with=hv_storvsc --with=hv_netvsc /boot/initramfs-$(uname -r).img $(uname -r)
  fi
}

poweroff() {
  if [[ "${_test}" -eq 1 ]] || [[ "${_noshutdown}" -eq 1 ]]; then
    echo "No shutdown performed"
  ## shutdown
  else
    echo "Shutting down in 5 sec. CTRL-C to stop" && sleep 5
    shutdown -h now
  fi
}

# reverse it all
restore() {
  if [ "${_test}" -eq 1 ]; then
    echo "TAR location: ${BKUP}"
    exit $?
  else
    # Get rid of old files
    rm ${NWS}/ifcfg-e*
    # Restore tar file
    cd / ; tar xvf ${BKUP}
    if [ $? -gt 0 ]; then
      echo "Restore failed. Please check ${BKUP}"
      exit $?
    else
      echo "Restore complete"
      exit 0
    fi
  fi
}

# CLInt GENERATED_CODE: start
# Default values
_noshutdown=0
_test=0
_restore=0

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
  *) set -- "$@" "$arg"
  esac
done

function print_illegal() {
    echo Unexpected flag in command line \"$@\"
}

# Parsing flags and arguments
while getopts 'hntrvy' OPT; do
    case $OPT in
        h) help
           exit 1 ;;
        n) _noshutdown=1 ;;
        t) _test=1 ;;
        r) _restore=1 ;;
        y) _yes=1 ;;
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

# OS test: RHEL 7 or RHEL 8
case ${OSVER} in 
  7) 
    backup
    vmtools
    rhel7
    poweroff
    ;;
  8) 
    backup
    vmtools
    rhel8
    poweroff
    ;;
  *)
    echo "OS version failure"
    exit 1
esac
