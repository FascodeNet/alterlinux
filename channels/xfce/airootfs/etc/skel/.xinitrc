[ -f /etc/xprofile ] && source /etc/xprofile
[ -f ~/.xprofile ] && source ~/.xprofile

export ZIPINFOOPT=-OCP932
export UNZIPOPT=-OCP932

exec startxfce4