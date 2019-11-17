#!/bin/bash

##############################
#                            #
#   Wireguard Configurator   #
#                            #
##############################

# downloader

# root check
if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running as root. Please use sudo."
  exit 1
fi

# set git base URL, needs branch added
giturl="https://raw.githubusercontent.com/NiiWiiCamo/wireguard-configurator/"
defaultbranch="master"
# set default paths
wgcdir="/etc/wireguard/wgc"
wgcbackupdir="/etc/wireguard/wgc_backup"
# make an array of all current files
wgcfiles=("README.md" "wgc-config" "wgc-downloader.sh" "wgc-exporter.sh" "wgc-generator.sh" "wgc-installer.sh" "wgc-uninstaller.sh")


clear
echo "#########################################"
echo "#                                       #"
echo "#  WireGuard Configurator | Downloader  #"
echo "#                                       #"
echo "#########################################"
echo ""
echo "Welcome to the Wireguard Configurator Suite!"
echo "You have opened the downloader. This tool will get all the other scripts from GitHub!"
echo ""
echo "The default directory is ${wgcdir}."

# check for previous install of wgc
if [ -d ${wgcdir} ]
then
  echo "WGC is already present. I will create a backup at ${wgcbackupdir}."
  # check for existing backup
  if [ -d ${wgcbackupdir} ]
  then
    echo "Previous backup found. Overwrite? [Y/n]"
    read -r -n 1 result
    case ${result} in
      [nN])
        echo "Please move your backup manually and restart this script."
        exit
      *)
        echo "Removing old backup..."
        rm -r ${wgcbackupdir}
    esac
    unset result
  fi
  # create backup
  echo "Creating backup..."
  mv ${wgcdir} ${wgcbackupdir}
  echo "Your existing WGC files are now at ${wgcbackupdir}"
  echo ""
fi

###### download current version from github
# ask for branch
echo "WGC will be downloaded from GitHub now."
#read gitbranch
#if [ -z ${gitbranch} ]
#then
#  gitbranch=${defaultbranch}
#fi
echo "You have selected branch ${gitbranch} for your download. Commencing..."
giturl="${giturl}${gitbranch}/"
mkdir -p ${wgcdir}
cd ${wgcdir}
# do the actual download stuff
for file in ${wgcfiles}
do
  echo "Downloading ${file}..."
  curl -O ${giturl}${file} 2>/dev/null || wget ${giturl}${file} 2>/dev/null || echo "You seem to have neiter cURL nor wget installed. Please install one of those for this script."; exit 2
done
echo "Finished downloading. You can now use wgc-master.sh (TBD) or any of the other scripts to get going!"
echo "Thank you for using WGC - WireGuard Configurator!"