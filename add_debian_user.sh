#!/bin/bash
if [ "$EUID" -ne 0 ]
  then printf "This script must be executed with sudo. Please run again: sudo ./add_debian_user.sh\n"
  exit
fi

# This script is designed to be executed when you need to add another user to the FrePBX 17 host Debian system.

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
case "$myKeySource" in
	ssh-*|ecdsa-*|sk-*)
		# a single public key pasted at the prompt
		echo "$myKeySource" >> /home/$myUserName/.ssh/authorized_keys
		;;
	http://*|https://*)
		# a URL serving an authorized_keys style list
		wget -q -O - "$myKeySource" >> /home/$myUserName/.ssh/authorized_keys
		;;
	*)
		# anything else is a github username
		wget -q -O - "https://github.com/$myKeySource.keys" >> /home/$myUserName/.ssh/authorized_keys
		;;
esac
chown -R $myUserName:$myUserName /home/$myUserName
