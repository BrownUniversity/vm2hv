#!/bin/bash
root() {
  # root or GTFO
  if [ "${EUID}" -ne 0 ]
    then echo "Please run as root"
    exit 1
  fi
}

# Vars
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
  echo -e "This perform post-zerto conversion of a VM on HyperV"
  echo -e ""
  echo -e "This script will ${BOLD}NOT${NORM} execute conversion without the -y,--yes option"
  echo -e ""
  echo -e "\t${BOLD}-y, --yes${NORM}:\t\tExecute the conversion."
  echo -e "\t${BOLD}-t, --test${NORM}:\t\tShow info about conversion"
  echo -e ""
  echo ""
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

udev () {
  rm ${UDEV}
  # Still remove HWADDR from ethX
  for I in 0 1 2 3 4 5; do
    sed -i "/HWADDR/d" ${NWS}/ifcfg-eth${I}
  done
}


# CLInt GENERATED_CODE: start
# Default values
_test=0

# No-arguments is not allowed
[ $# -eq 0 ] && help && exit 1

# Converting long-options into short ones
for arg in "$@"; do
  shift
  case "$arg" in
"--test") set -- "$@" "-t";;
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
        t) _test=1 ;;
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

# OS test: RHEL or Ubuntu
case ${OSDIST} in
  ubuntu)
    case ${OSVER} in
      18)
        OSDIST=ubuntu
        vmtools
        ;;
      20)
        OSDIST=ubuntu
        vmtools
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
        vmtools
        udev
        ;;
      8) 
        OSDIST=redhat
        vmtools
        udev
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