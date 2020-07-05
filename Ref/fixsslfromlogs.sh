#!/bin/bash
pushd `dirname $0` > /dev/null
PROGDIR=`pwd`
CURRENTDATE=`date +"%Y%m%d%H%M"`
popd > /dev/null

foldername=`ls -1 /var/cpanel/logs/autossl|tail -n 1`
if [ "${foldername}" == "" ]; then
  echo "no autossl logs!";
  exit;
fi;

path="/var/cpanel/logs/autossl/${foldername}"

if [ -d ${path} ]; then
  for domain in `cat ${path}/txt|grep "system failed to determine"|awk -F '(' '{print $3}'|awk -F '/' '{print $1}'|awk '{print $1}'|sort|uniq`; do
    count=`cat /etc/userdomains|grep -c "^${domain}:"`;
    if [ $count -eq 1 ]; then
      ${PROGDIR}/installssl.sh ${domain}
    fi;
  done;
fi;
