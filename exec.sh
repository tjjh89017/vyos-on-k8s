source /opt/vyatta/etc/functions/script-template
config
load /opt/vyatta/etc/config.boot.default
load /config/config.temp
source /config/config.command
commit
exit
