
if [ "$(id -g -n)" != 'vyattacfg' ] ; then
    exec sg vyattacfg -c "/bin/vbash $(readlink -f $0) $@"
fi

source /opt/vyatta/etc/functions/script-template
configure
if [ -s /config/config.temp ]
then
load /config/config.temp
commit
else
load /config/config.boot
commit
fi
source /config/config.command
commit
exit
