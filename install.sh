#!/bin/bash

set +o noclobber

DNSgb1=10.61.245.12
DNSgb3=10.105.238.13
DNSresl=/etc/resolv.conf
PupConf=/etc/puppet/puppet.conf
PupExec=/usr/bin/puppet
PupRepo=/etc/yum.repos.d/puppetlabs.repo
PrivIp=`hostname -I | cut -d. -f2`
SysConf=/etc/sysconfig/network
XCRepo=/etc/yum.repos.d/xchangingcloud.repo

# --
# -- Determine node IP and configure DNS resolution accordingy
# --
cp ${DNSresl}{,.$$}
cat > $DNSresl <<EOF
domain xchangingcloud.local
search xchangingcloud.local
EOF
if [ -z ${PrivIP+x} ];
  then
    PrivIp=`ip addr | grep 'state UP' -A2 | tail -n1 | awk -F'[/ ]+' '{print $3}' | cut -d. -f2`
fi
case "${PrivIp}" in
  105) LoC="gb3"
       echo -e "nameserver "$DNSgb3" \nnameserver "$DNSgb1"" >> $DNSresl
  ;;
  61)  LoC="gb1"
       echo -e "nameserver "$DNSgb1" \nnameserver "$DNSgb3"" >> $DNSresl
  ;;
  *)
       echo ""
  ;;
esac 
chattr +i $DNSresl

# --
# -- Append FQDN to hostname
# --
cp ${SysConf}{,.$$}
sed -i '/^HOSTNAME=/ s/$/.xchangingcloud.local/' $SysConf
chattr +i $SysConf

# --
# --  Install & check packages
# --
RPMs=(
http://GB3MGMTSRV25.xchangingcloud.local/repo/xchangingcloud/xchangingcloud.repo-1-0.noarch.rpm
http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
)
for PackAges in "${RPMs[@]}"; do
   rpm -ih $PackAges
done
if [ ! -r "$PupRepo" ] || [ ! -r "$XCRepo" ];
  then
    exit 1
fi

# --
# -- Configure puppet agent
# --
yum install puppet -y
if [ ! -x "$PupExec" ] || [ ! -r "$PupConf" ];
  then
    exit 1
  else
    cp ${PupConf}{,.$$}
    sed -i -e '/#/d' -e '/^$/d' $PupConf
    chattr +i $PupConf
fi

# --
# -- Schedule puppet agent via root cron (every 5 minutes)
# --
puppet resource cron puppet-agent ensure=present user=root minute=5 command='/usr/bin/puppet agent --onetime --no-daemonize --splay'
