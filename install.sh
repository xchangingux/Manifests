#!/bin/bash

set +o noclobber

export DNSgb1=10.61.245.12
export DNSgb3=10.105.238.13
export DNSresl=/etc/resolv.conf
export SysConf=/etc/sysconfig/network

cp ${DNSresl}{,.orig}
cat > $DNSresl <<EOF
domain xchangingcloud.local
search xchangingcloud.local
EOF

PrivIp=`hostname -I | cut -d. -f2`
if [ $? != 0 ];
then
  PrivIp=`ip addr | grep 'state UP' -A2 | tail -n1 | awk -F'[/ ]+' '{print $3} | cut -d. -f2'`
fi

case "${PrivIp}" in
  105)
    LoC="gb3"
  ;;
  61)
    LoC="gb1"
  ;;
  *)
    echo "Can not determine node location."
  ;;
esac 

if [ $LoC="gb3" ];
then
  echo -e "nameserver "$DNSgb3" \nnameserver "$DNSgb1"" >> $DNSresl
else 
  echo -e "nameserver "$DNSgb1" \nnameserver "$DNSgb3"" >> $DNSresl
fi
chattr +i $DNSresl

cp ${SysConf}{,.orig}
sed -i '/^HOSTNAME=/ s/$/.xchangingcloud.local/' $SysConf
chattr +i $SysConf
