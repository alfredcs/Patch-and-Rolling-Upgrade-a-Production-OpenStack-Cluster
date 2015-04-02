#!/bin/bash
set -x
[[ `id -u` -ne 0 ]] && { echo  "Must be root!"; exit 0; }
[ $# -ne 1 ] && exit
service_name=$1
echo $service_name
service_port=`cat contrail/patches/${service_name}| grep port| grep -v ^#|cut -d= -f2|sed 's/^\s*//'`
if [[ -f  /etc/contrail/contrail-api.conf &&  -f /etc/neutron/neutron.conf ]]; then
	[[ `grep ${service_name} /etc/services |grep -v ^#|wc -l` -lt 1 ]] && echo -e ${service_name} '\t' ${service_port}/tcp '\t\t' "#Haproxy Layer 7 health check" >> /etc/services	
	[[ -f contrail/patches/${service_name} ]] && cp -pr contrail/patches/${service_name} /etc/xinetd.d/
fi
