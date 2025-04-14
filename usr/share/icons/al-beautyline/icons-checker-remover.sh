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

echo "Checking and printing all the icons with a broken symbolic link"
find . -type l -exec sh -c 'file -b "$1" | grep -q "broken symbolic" && rm -v "$1"' sh {} \;

echo "finding blanco spaces"
find . -type f -name '* *' -exec rm '{}' +
echo "End of script"
