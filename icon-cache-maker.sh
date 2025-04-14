### Auto update the iconcache
### Do a manual update with following code in a terminal if you get errors
### Do check if you have used spaces in the naming of files or folders
### Sometimes you make a copy of an icon - this contains a space
### gtk-update-icon-cache -f iconthemefolder

### in some of the distributions you will a message popup if an icon theme has no cache
### if you have changed the icons - deleted folders etcetera then run this script
gtk-update-icon-cache -f usr/share/icons/al-beautyline
gtk-update-icon-cache -f usr/share/icons/al-candy-icons
gtk-update-icon-cache -f usr/share/icons/a-candy-beauty-icon-theme

rm -v usr/share/icons/al-beautyline/icon-theme.cache
rm -v usr/share/icons/al-candy-icons/icon-theme.cache
rm -v usr/share/icons/a-candy-beauty-icon-theme/icon-theme.cache
