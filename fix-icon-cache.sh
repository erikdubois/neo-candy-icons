#!/bin/bash
#
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	Erik Dubois
# Website 	: 	http://www.erikdubois.be
##################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################
echo "Removing files with a space"
files=(
"preferences-desktop-multitasking 1.svg"
"battery-level-100-symbolic.symbolic (copy 1).svg"
)

for file in "${files[@]}"; do
    find / -type f -name "$file" -exec rm -f {} \; 2>/dev/null
done

file="/home/erik/DATA/EDU/neo-candy-icons/usr/share/icons/or-beautyline/devices/scalable/battery-level-100-symbolic.symbolic (copy 1).svg"

if [ -f "$file" ]; then
    rm -v "$file"
fi
echo "Removal step finished"

echo "Files containing spaces"
find . -type f -name "* *"

echo "Directories containing spaces"
find . -type d -name "* *"

echo "Searching for files or directories containing spaces"
ls -R | grep ' '

sleep 10

echo "Checking and printing all the icons with a broken symbolic link"
find ./ -type l -exec file {} \; | grep 'broken symbolic'

echo "End of symbolic link check"

sleep 5

echo "Searching for hidden files in /home/erik/DATA/EDU/neo-candy-icons/usr/share/icons/"
find /home/erik/DATA/EDU/neo-candy-icons/usr/share/icons/ -type f -iname ".*" -ls

echo "Searching for hidden directories in /home/erik/DATA/EDU/neo-candy-icons/usr/share/icons/"
find /home/erik/DATA/EDU/neo-candy-icons/usr/share/icons/ -type d -iname ".*" -ls

sleep 10

echo "Script finished"
