#!/bin/bash

shopt -s globstar

# This script requires running as root
if [ $EUID != 0 ]
then
	echo "ERROR: Please run as root"
	exit 0
fi

# Check if pv installed for progress
if [[ -z $(which pv) ]]
then
	echo "ERROR: Please install pv"
	exit 0
fi

EXCLUDE=(
"/dev/*"
"/proc/*"
"/sys/*"
"/tmp/*"
"/run/*"
"/mnt/*"
"/media/*"
"/lost+found/*"
"/backup/*"
"/var/cache/*"
"/**/.cache/*"
"/**/steamapps/common/*"
"/home/jukka/manual_packages/nerd-fonts"
"/home/jukka/VirtualBox_VMs"
)

# Excludes for calculating size and estimating progress with pv
SIZE_EXCLUDE=("${EXCLUDE[@]%*}")
SIZE_EXCLUDE=("${EXCLUDE[@]%/}")

# Construct filename and path
DATE=$(date +%Y-%m-%d)
DISTRO_NAME=$(grep -ioP "^PRETTY_NAME=\K.+" /etc/os-release)
DISTRO_NAME=$(echo $DISTRO_NAME | tr -d '\"\(\)' | tr ' /' '-' )
FILENAME=$DATE-$(hostname)-$DISTRO_NAME.tar.gz
mkdir -p /backup
FULL_PATH=/backup/$FILENAME

echo "The backup will be written to:"
echo -e "$FULL_PATH\n"
echo "The following directories and files will be excluded:"
for DIR in "${EXCLUDE[@]}"
do
	echo "$DIR"
done
while :
do
	echo "Type y to continue, n to cancel"
	read CONFIRM
	CONFIRM=$(echo $CONFIRM | tr [:upper:] [:lower:] )
	if [[ $CONFIRM = 'y' || $CONFIRM = 'n' ]]
	then
		break
	fi
done
if [[ $CONFIRM = 'n' ]]
then
	exit 0
fi

TOTAL_SIZE=$(du -sb \
		$(for DIR in "${SIZE_EXCLUDE[@]}"; \
		do echo --exclude="$DIR "; \
		done) / | awk '{print $1}')

tar -cpP --xattrs --acls --exclude-caches \
	$(for DIR in "${EXCLUDE[@]}"; do echo "--exclude=$DIR "; done) \
	-f - / | pv -s $TOTAL_SIZE | gzip > $FULL_PATH

