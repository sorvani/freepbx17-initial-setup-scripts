#!/bin/bash
logdate=`date +"%Y%m%d-%H%M%S"`
logfile=upgrade-$logdate.log
printf "Beginning update of FreePBX 17...\n" | tee -a $logfile
if [ "$EUID" -ne 0 ]
  then printf "This script must be executed with sudo. Please run again: sudo ./update.sh\n" | tee -a $logfile
  exit
fi

printf "Updating operating system.\n" | tee -a $logfile
printf "This can take a seemingly excessive amount of time depending on\n" | tee -a $logfile
printf "how many Linux updates have been released since the last update.\n" | tee -a $logfile
apt update | tee -a $logfile
apt upgrade -y | tee -a $logfile
apt autoremove -y | tee -a $logfile

printf "Upgrading all installed modules...\n" | tee -a $logfile
printf "This can also take a seemingly excessive amount of time depending on\n" | tee -a $logfile
printf "how many module updates have been released since the update.\n" | tee -a $logfile
fwconsole ma upgradeall 2> /dev/null >> $logfile

printf "Updating all permissions...\n" | tee -a $logfile
fwconsole chown 2> /dev/null | tee -a $logfile

printf "Reloading FreePBX...\n" | tee -a $logfile
fwconsole reload >> $logfile

printf "Your FreePBX system has been updated.\n\n" | tee -a $logfile
if grep -q "Upgrading module" $logfile
then 
  printf "The following FreePBX modules were upgraded:\n" | tee -a $logfile
  grep "Upgrading module" $logfile | sed 's/Upgrading module //' | tee -a $logfile
  printf "\n\n" | tee -a $logfile
fi

# Get system uptime in whole days, field 1 of /proc/uptime is seconds
daysup=`awk '{print int($1/86400)}' /proc/uptime`

if [ "$daysup" -gt 30 ]
then
  printf "Your system has been running for $daysup days.\n" | tee -a $logfile
  printf "It is strongly recommended that you schedule a reboot.\n\n" | tee -a $logfile
fi
