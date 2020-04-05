# Load config files
[ -f /etc/xprofile ] && source /etc/xprofile
[ -f ~/.xprofile ] && source ~/.xprofile

# Set unzip-iconv
export ZIPINFOOPT=-OCP932
export UNZIPOPT=-OCP932

# No beep
xset -b

# Start xfce4
exec startxfce4