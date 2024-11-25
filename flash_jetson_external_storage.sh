#!/bin/bash
#MIT License
#Copyright (c) 2021-23 Jetsonhacks

JETSON_FOLDER=R36.4 # UPDATED: Updated to match Jetpack 36.4 naming conventions
LINUX_FOR_TEGRA_DIRECTORY="$JETSON_FOLDER/Linux_for_Tegra"

# Flash Jetson Xavier to run from external storage
# Some helper functions. These scripts only flash Jetson Orins and Xaviers
# https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/text/IN/QuickStart.html#jetson-modules-and-configurations # UPDATED: Updated documentation link

declare -a device_names=(
    "jetson-agx-orin-devkit"
    "jetson-agx-xavier-devkit"
    "jetson-agx-xavier-industrial"
    "jetson-orin-nano-devkit"
    "jetson-xavier-nx-devkit"
    "jetson-xavier-nx-devkit-emmc"
    "jetson-orin-nx-devkit" # UPDATED: Added new device for Jetpack 36.4
)

# Function to check if the device is Xavier
function is_xavier() {
    local input=$1
    for device_name in "${device_names[@]}"; do
        if [[ "$device_name" == "$input" ]] && [[ "$device_name" == *"xavier"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if the device is Orin
function is_orin() {
    local input=$1
    for device_name in "${device_names[@]}"; do
        if [[ "$device_name" == "$input" ]] && [[ "$device_name" == *"orin"* ]]; then
            return 0
        fi
    done
    return 1
}

# Sanity warning; Make sure we're not running from a Jetson
# First check to see if we're running on Ubuntu
# Next, check the architecture to make sure it's x86, not a Jetson

function help_func
{
  echo "Usage: ./flash_jetson_external_storage [OPTIONS]"
  echo "   No option flashes to nvme0n1p1 by default"
  echo "   -s | --storage - Specific storage media to flash; sda1 or nvme0n1p1"
  echo "   -h | --help - displays this message"
}

# Check OS and architecture
if [ -f /etc/os-release ]; then
  if [[ ! $( grep Ubuntu < /etc/os-release ) ]] ; then
    echo 'WARNING: This does not appear to be an Ubuntu machine. The script is targeted for Ubuntu, and may not work with other distributions.'
    read -p 'Continue with installation (Y/n)? ' answer
    case ${answer:0:1} in
       y|Y )
         echo Yes
       ;;
       * )
         exit
       ;;
    esac
  else
    if [ $(arch) == 'aarch64' ]; then
      echo 'This script must be run from a x86 host machine'
      if [ -f /etc/nv_tegra_release ]; then
        echo 'An aarch64 Jetson cannot be the host machine'
      fi
      exit
    fi
  fi
else
    echo 'WARNING: This does not appear to be an Ubuntu machine. The script is targeted for Ubuntu, and may not work with other distributions.'
    read -p 'Continue with installation (Y/n)? ' answer
    case ${answer:0:1} in
       y|Y )
         echo Yes
       ;;
       * )
         exit
       ;;
    esac
fi

if [[ ! -d $LINUX_FOR_TEGRA_DIRECTORY ]] ; then
   echo "Could not find the Linux_for_Tegra folder."
   echo "Please download the Jetson sources and ensure they are in $JETSON_FOLDER/Linux_for_Tegra"
   exit 1
fi

# Check board setup
function check_board_setup
{
  cd $LINUX_FOR_TEGRA_DIRECTORY
  echo $PWD
  # Check to see if we can see the Jetson
  echo "Checking Jetson ..."
  
  FLASH_BOARDID=$(sudo ./nvautoflash.sh --print_boardid) # UPDATED: Updated script to use latest `nvautoflash.sh`
  if [ $? -eq 1 ] ; then
    echo "$FLASH_BOARDID" | grep Error
    echo "Make sure that your Jetson is connected through"
    echo "a USB port and in Force Recovery Mode"
    exit 1
  else
    last_line=$(echo "$FLASH_BOARDID" | sed -e 's/ *$//' | tail -n 1)
    FLASH_BOARDID=$(echo "$last_line" | sed -e 's/found\.$//')
    echo $FLASH_BOARDID
    if is_orin $FLASH_BOARDID || is_xavier $FLASH_BOARDID ; then
      echo "$FLASH_BOARDID" | grep found
      if [[ $FLASH_BOARDID == *"jetson-xavier-nx-devkit"* ]] ; then
        read -p "Make sure the SD card and the force recovery jumper are removed. Continue (Y/n)? " answer
        case ${answer:0:1} in
          y|Y )
          ;;
          * )
          echo 'You need to remove the force recovery jumper before flashing.'
          exit 1
          ;;
        esac
      fi
    else
      echo "$FLASH_BOARDID" | grep found
      echo "ERROR: Unsupported device."
      echo "This method currently only works for the Jetson Xavier or Jetson Orin"
      exit 1
   fi
 fi
}

# If Ubuntu 22.04, Python 3.8+ is used
function check_python_install
{
  if [[ $(lsb_release -rs) == "22.04" ]] ; then # UPDATED: Checked for Ubuntu 22.04
    if [ ! -L "/usr/bin/python" ] ; then
      echo "Setting Python"
      sudo apt install python-is-python3
      SCRIPT_SET_PYTHON=true
    fi 
  fi
} 

# Start flashing process
function flash_jetson
{
  local storage=$1
  check_board_setup
  check_python_install
  if [[ $(lsb_release -rs) == "20.04" ]] || [[ $(lsb_release -rs) == "22.04" ]] ; then # UPDATED: Ensure compatibility with Ubuntu 22.04
    export LC_ALL=C.UTF-8
  fi
  sudo systemctl stop udisks2.service
  echo "Flashing to $storage"
  sudo ./nvsdkmanager_flash.sh --storage "${storage}" # UPDATED: Reflects the latest SDK Manager script
  cleanup
}

# Default to nvme0n1p1 if no arguments
storage_arg="nvme0n1p1"
if [ "$1" == "" ]; then
  flash_jetson "${storage_arg}"
  exit 0
fi 

while [ "$1" != "" ];
do
   case $1 in
  -s | --storage )
    shift
    storage_arg=$1
    flash_jetson "${storage_arg}"
    exit 0;
    ;;
  -h | --help )
    help_func
    exit
    ;;
  * )
    echo "*** ERROR Invalid flag"
    help_func
    exit
    ;;
  esac
  shift
done
