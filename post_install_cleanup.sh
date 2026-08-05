#!/bin/bash
logfile=setup.log
printf "Beginning FreePBX 17 post install cleanup...\n" | tee -a $logfile
if [ "$EUID" -ne 0 ]
  then printf "This script must be executed with sudo. Please run again: sudo ./post_install_cleanup.sh\n" | tee -a $logfile
  exit
fi
printf "Installing additional usefull applications\n" | tee -a $logfile
apt update | tee -a $logfile
apt install -y git glances | tee -a $logfile

printf "Removing FreePBX commerical modules, except sysadmin...\n" | tee -a $logfile
fwconsole ma delete adv_recovery | tee -a $logfile
fwconsole ma delete areminder | tee -a $logfile
fwconsole ma delete broadcast | tee -a $logfile
fwconsole ma delete callaccounting | tee -a $logfile
fwconsole ma delete callerid | tee -a $logfile
fwconsole ma delete calllimit | tee -a $logfile
fwconsole ma delete cdrpro | tee -a $logfile
fwconsole ma delete conferencespro | tee -a $logfile

fwconsole ma delete extensionroutes | tee -a $logfile
fwconsole ma delete faxpro | tee -a $logfile
fwconsole ma delete oracle_connector | tee -a $logfile
fwconsole ma delete pagingpro | tee -a $logfile
fwconsole ma delete parkpro | tee -a $logfile
fwconsole ma delete pinsetspro | tee -a $logfile
fwconsole ma delete pms | tee -a $logfile
fwconsole ma delete queuestats | tee -a $logfile
fwconsole ma delete qxact_reports | tee -a $logfile
fwconsole ma delete recording_report | tee -a $logfile
fwconsole ma delete sangomaconnect | tee -a $logfile
fwconsole ma delete sangomacrm | tee -a $logfile
fwconsole ma delete sangomartapi | tee -a $logfile
fwconsole ma delete sipstation | tee -a $logfile
fwconsole ma delete smsplus | tee -a $logfile
fwconsole ma delete vmnotify | tee -a $logfile
fwconsole ma delete voicemail_report | tee -a $logfile
fwconsole ma delete voipinnovations | tee -a $logfile
fwconsole ma delete vqplus | tee -a $logfile
fwconsole ma delete webcallback | tee -a $logfile

#pms and oracle_connector dpend on this.
fwconsole ma delete cos | tee -a $logfile 
#sangomaconnect depends on this.
fwconsole ma delete sms | tee -a $logfile
#sangomaconnect depends on this.
fwconsole ma delete restapps | tee -a $logfile
#restapps depends on this.
fwconsole ma delete endpoint | tee -a $logfile

printf "Removing rarely needed Open Source modules\n" | tee -a $logfile
fwconsole ma delete amd >> $logfile
fwconsole ma delete disa >> $logfile
fwconsole ma delete iaxsettings >> $logfile
fwconsole ma delete hotelwakeup >> $logfile
fwconsole ma delete phpinfo >> $logfile

printf "Reloading FreePBX...\n" | tee -a $logfile
fwconsole reload >> $logfile

printf "Enabling commerical repository...\n" | tee -a $logfile
fwconsole ma enablerepo commercial >> $logfile

printf "Updating all permissions...\n" | tee -a $logfile
fwconsole chown 2> /dev/null | tee -a $logfile

printf "Reloading FreePBX...\n" | tee -a $logfile
fwconsole reload >> $logfile

printf "Your initial FreePBX command line setup is complete.\n" | tee -a $logfile
ipaddress=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
printf "Please reboot and then navigate to https://$ipaddress or https://YOURFQDN to complete your setup.\n" | tee -a $logfile
