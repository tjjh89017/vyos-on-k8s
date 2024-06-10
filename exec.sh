source /opt/vyatta/etc/functions/script-template
configure
load /opt/vyatta/etc/config.boot.default
commit
load /config/config.temp
commit
source /config/config.command
commit
exit
