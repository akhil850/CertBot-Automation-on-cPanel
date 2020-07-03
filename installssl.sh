#!/bin/bash
pushd `dirname $0` > /dev/null
PROGDIR=`pwd`
CURRENTDATE=`date +"%Y%m%d%H%M"`
popd > /dev/null

if [ "$1" == "" ]; then
  echo "$0 domain"
  exit;
fi;

webroot=1;
if [ "$2" == "dns" ]; then
  webroot=0;
fi;

if [ ! -f ${PROGDIR}/certbot/certbot-auto ]; then
  echo "certbot missing!"
  exit;
fi;

dnscommand="dig +noall +answer A @8.8.8.8"
domain=${1}

count=`cat /etc/userdomains |grep -c "${domain}:"`
if [ $count -eq 0 ]; then
  echo "$domain does not exists!"
  exit;
fi;

user=`cat /etc/userdomains|grep "^${domain}:"|awk -F ':' '{print $2}'|tr -d '[:space:]'`
cd /var/cpanel/userdata/${user}/
domainFile=`grep -ilr "\ ${domain}"|egrep -v -e "cache$" -e "main$" -e "json$" -e "_SSL$"`;
path=`cat "${domainFile}"|grep documentroot|awk '{print $2}'`;

if [ ! -d ${path} ]; then
  echo ${path} does not exists!
  exit;
fi;

function dnsipcheck {
  local domain=$1

  dnsresult=`${dnscommand} ${domain}|grep IN|grep -v CNAME`;
  count=`echo ${dnsresult}|grep -c ""`;
  if [ $count -gt 0 ]; then
    ipaddress=`echo ${dnsresult}|awk '{print $5}'`;
    if [ "$ipaddress" != "" ]; then
      count=`ifconfig|grep inet|awk '{print $2}'|egrep -v -e "^127.0.0.1$" -e "^::1$"|grep -c ${ipaddress}`;
      if [ $count -gt 0 ]; then
        echo "$domain ok";
        return 1;
      fi;
    fi;
  fi;
  echo "$domain bad";
  return 0;
}

cd ${PROGDIR}/certbot/
if [ -f /var/cpanel/userdata/${user}/${domainFile} ]; then
  servername=`cat /var/cpanel/userdata/${user}/${domainFile}|grep "servername:"|awk -F ': ' '{print $2}'`
  serveraliases=`cat /var/cpanel/userdata/${user}/${domainFile}|grep "serveralias:"|awk -F ': ' '{print $2}'`

  basedomain=`cat /var/cpanel/userdata/${user}/main|grep ": ${servername}"|awk -F ': ' '{print $1}'|tr -d ' '|head -n 1`

  domainscommand="";
  if [ "${basedomain}" == "main_domain" ]; then
    basedomain=${servername};
  else
    serveraliases="${serveraliases} ${domainFile}";
  fi;

  if [ "${basedomain}" != "main_domain" ]; then
    dnsipcheck ${basedomain}
    if [ $? -eq 1 ]; then
      domainscommand="${domainscommand} -d ${basedomain}";
    fi;
  fi;

  for alias in `echo autodiscover cpanel webdisk webmail mail www`; do
    dnsipcheck ${alias}.${basedomain}
    if [ $? -gt 0 ]; then
      domainscommand="${domainscommand} -d ${alias}.${basedomain}"
    fi;
  done;

  for alias in `echo ${serveraliases}`; do
    dnsipcheck ${alias}
    if [ $? -gt 0 ]; then
      domainscommand="${domainscommand} -d ${alias}"
    fi;
  done;

  if [ "$domainscommand" == "" ]; then
    echo "no hosts resolved for $domainFile ssl!"
    exit;
  fi;

  firstdomain=`echo $domainscommand|awk '{print $2}'`;

  ./certbot-auto certonly -n ${domainscommand} --webroot -w ${path} --expand
fi;

cd ${PROGDIR}
cpapi1 --user=${user} SSL delete ${domainFile}
./installssl.pl $firstdomain $domain
