source /opt/vyatta/etc/functions/script-template
configure
if [ -s /config/config.temp ]
then
load /config/config.temp
commit
else
load /opt/vyatta/etc/config.boot.default
commit
fi
source /config/config.command
commit
exit
