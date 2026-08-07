#!/bin/bash
if [ "$EUID" -ne 0 ]
  then printf "This script must be executed with sudo. Please run again: sudo ./add_debian_user.sh\n"
  exit
fi

# This script is designed to be executed when you need to add another user to the FreePBX 17 host Debian system.

# collect the linux username and the ssh public key source for the person runnning the script
read -p "Enter a new username to use for SSH access: " myUserName
echo "Public keys can be a github username, a URL serving an authorized_keys list, or a single pasted key."
read -p "Enter the github username, URL, or public key for $myUserName: " myKeySource

# Create user account with default password of ChangeMe
echo "Creating the user $myUserName and assigning permissions"
echo ""
useradd --create-home $myUserName --password $(openssl passwd -1 ChangeMe) --shell /bin/bash>> setup.log
# expire the password to force reset on first login
chage -d 0 $myUserName >> setup.log
# Add user to sudo
gpasswd -a $myUserName sudo >> setup.log
# Create the user's .ssh folder 
mkdir /home/$myUserName/.ssh
# Set permissions
chmod 700 /home/$myUserName/.ssh
# Create empty authorized_keys file
touch /home/$myUserName/.ssh/authorized_keys
# set permissions
chmod 600 /home/$myUserName/.ssh/authorized_keys
# add the pub key(s) for this user, from whichever source was given
# github strips the key comment, so tag each import with where it came from and when
myToday=$(date +%Y-%m-%d)
myKeyFile=/home/$myUserName/.ssh/authorized_keys
case "$myKeySource" in
	ssh-*|ecdsa-*|sk-*)
		# a single public key pasted at the prompt
		echo "# pasted at setup on $myToday" >> $myKeyFile
		echo "$myKeySource" >> $myKeyFile
		;;
	http://*|https://*)
		# a URL serving an authorized_keys style list
		echo "# imported from $myKeySource on $myToday" >> $myKeyFile
		wget -q -O - "$myKeySource" >> $myKeyFile
		;;
	*)
		# anything else is a github username
		myKeyUrl="https://github.com/$myKeySource.keys"
		echo "# imported from $myKeyUrl on $myToday" >> $myKeyFile
		wget -q -O - "$myKeyUrl" >> $myKeyFile
		;;
esac

# drop the maintenance scripts in the new user's home, anyone with console access here is an admin
myScriptUrl=https://raw.githubusercontent.com/sorvani/freepbx17-initial-setup-scripts/main
for myScript in update.sh add_debian_user.sh; do
	# use the local copy if it is here, otherwise pull it from github
	if [ -f "$myScript" ]; then
		cp "$myScript" /home/$myUserName/$myScript
	else
		wget -q -O /home/$myUserName/$myScript "$myScriptUrl/$myScript"
	fi
	chmod +x /home/$myUserName/$myScript
done

chown -R $myUserName:$myUserName /home/$myUserName
