#!/bin/bash
set -x
[[ `id -u` -ne 0 ]] && { echo  "Must be root!"; exit 0; }
[ $# -ne 1 ] && exit
service_name=$1
service_port=`cat compute/patches/${service_name}| grep port| grep -v ^#|cut -d= -f2|sed 's/^\s*//'`
[[ `rpm -qa | grep xinetd | wc -l` -lt 1 ]] && yum -y install --disablerepo=* --enablerepo=havana_install_repo110 xinetd
if [[ -f  /etc/contrail/contrail-vrouter-agent.conf &&  -f /etc/nova/nova.conf ]]; then
	[[ `grep ${service_name} /etc/services |grep -v ^#|wc -l` -lt 1 ]] && echo -e ${service_name} '\t' ${service_port}/tcp '\t\t' "#Layer 7 health check" >> /etc/services	
	[[ -f compute/patches/${service_name} ]] && cp -pr compute/patches/${service_name} /etc/xinetd.d/
fi
