#!/bin/bash
set -x
[[ `id -u` -ne 0 ]] && { echo  "Must be root!"; exit 0; }
[[ $# -lt 2 ]] && { echo "upgrade_contrail.sh <contrail_repo_name> <opensatck_repo_name>"; exit 1; }
this_ip=`grep $HOSTNAME /etc/hosts| grep -v ^#|head -1|awk '{print $1}'`
to_day=`date '+%Y%m%d%H%M%S'`
if [[ -f /etc/contrail/contrail-api.conf ]]; then
	[[ `nodetool status| grep ${this_ip}|grep ^UN|wc -l` -gt 0 ]] && nodetool snapshot
	service keepalived stop
	service haproxy stop
	service zookeeper stop
	service redis stop
	service supervisor-analytics stop
	service supervisor-config stop
	service supervisor-control stop
	service supervisor-webui stop
	service supervisord-contrail-database	stop
	service neutron-server stop
elif [[ -f /etc/contrail/contrail-vrouter-agent.conf ]]; then
	service supervisor-vrouter stop
	service openstack-nova-compute stop
fi
[[ -d /etc/contrail ]] && { [[ -d /etc/contrail.${to_day} ]] && rm -rf /etc/contrail.${to_day}; cp -pr /etc/contrail /etc/contrail.${to_day}; }
[[ -d /etc/neutron ]] && { [[ -d /etc/neutron.${to_day} ]] && rm -rf /etc/neutron.${to_day}; cp -pr /etc/neutron /etc/neutron.${to_day}; }
[[ -d /etc/nova ]] && { [[ -d /etc/nova.${to_day} ]] && rm -rf /etc/nova.${to_day}; cp -pr /etc/nova /etc/nova.${to_day}; }
[[ -f /etc/contrail/contrail-api.conf ]] && yum -y install --disablerepo=* --enablerepo=$2 rabbitmq-server

pkg_name_spec=`rpm -qa | grep  contrail-openstack-webui`
rpm -e --nodeps ${pkg_name_spec}
yum clean all
yum -y install --disablerepo=* --enablerepo=$1 contrail-openstack-webui
[[ $? -ne 0 ]] && { echo "Removaed and upgrade ${pkg_name_spec} failed"; exit 1; }

rpm -qa | grep contrail|grep -v contrail-openstack-vrouter | while read aa
do
	#[[ $aa =~ "contrail-openstack-webui" ]] && { rpm -e --nodeps $aa; yum -y install --disablerepo=* --enablerepo=$1 contrail-openstack-webui; }
	#if [[ $aa =~ "contrail-web-core" ]]; then
	#	pkg_name_spec=`rpm -qa | grep  contrail-openstack-webui`
	#	rpm -e --nodeps ${pkg_name_spec}
	#	yum -y upgrade --disablerepo=* --enablerepo=$1 $aa
	#	yum -y install --disablerepo=* --enablerepo=$1 ${pkg_name_spec}
	#else
	yum -y upgrade --disablerepo=* --enablerepo=$1 $aa
	#fi
	[[ $? -ne 0 ]] && { echo "Upgrade failed on yum repo. Please check local repo file!!"; exit 1; }
done

if [[ -f /etc/contrail/contrail-api.conf ]]; then
	yum -y upgrade --disablerepo=* --enablerepo=$1 supervisor
	[[ -f /etc/irond/log4j.properties ]] && sed -i '/^#log4j/ s/^#log4j/log4j/' /etc/irond/log4j.properties
	rpm -e --nodeps `rpm -qa | egrep 'rabbitmq|openstack-nova'`
fi
if [[ -f /etc/contrail/contrail-vrouter-agent.conf ]]; then
	rpm -e --nodeps openstack-nova-common openstack-nova-compute python-nova
	yum -y upgrade --disablerepo=* --enablerepo=$1 contrail-openstack-vrouter supervisor
	rpm -e --nodeps openstack-nova-common openstack-nova-compute python-nova
	yum clean all
	yum -y install --disablerepo=* --enablerepo=$2 openstack-nova-common openstack-nova-compute python-nova

	#####
	# Upgrade qemu for ceph
	####
	[[ `rpm -qa | grep -E 'qemu-img|qemu-kvm' | wc -l` -gt 1 ]] &&  rpm -e --nodeps qemu-img qemu-kvm
	yum clean all
	yum -y install --disablerepo=* --enablerepo=ceph --enablerepo=ceph-extra qemu-img qemu-kvm
	[[ $? -ne 0 ]] && { echo "Reinstall qemu for Ceph failed!! Please check repo files to make sure they have ceph and ceph-extra."; exit 1; }
fi




echo "Restore pre-patch config files!"
[[ -d /etc/contrail ]] && mv /etc/contrail /etc/contrail.new.${to_day}
[[ -d /etc/neutron ]] && mv /etc/neutron /etc/neutron.new.${to_day}
[[ -d /etc/nova ]] && mv /etc/nova /etc/nova.new.${to_day}
[[ -d /etc/contrail.${to_day} ]] && { mv -f /etc/contrail.${to_day} /etc/contrail; cp -p /etc/contrail.new.${to_day}/supervisord_*.conf /etc/contrail/; chmod o-rx -R /etc/contrail; }
[[ -d /etc/neutron.${to_day} ]] && { mv -f /etc/neutron.${to_day} /etc/neutron; chmod o-rx -R /etc/contrail; chgrp neutron -R /etc/neutron; }
[[ -d /etc/nova.${to_day} ]] && { mv -f /etc/nova.${to_day} /etc/nova; chmod o-rx -R /etc/nova; chgrp nova -R /etc/nova; }
###
# Increase size limit for http requests sent to API server.
#
#Currently, the limit is 100k. If the post request is larger than this, API server will throw exception.
#Increased it to 1M till a more permanent solution is implemented.
#
#Change-Id: Ia7e9150b274fff4b03a4c12ab63c444d25e78187
#Closes-Bug: 1394374
####
[[ -f /usr/lib/python2.6/site-packages/vnc_cfg_api_server/vnc_cfg_api_server.py && `grep request.MEMFILE_MAX /usr/lib/python2.6/site-packages/vnc_cfg_api_server/vnc_cfg_api_server.py |grep -v ^#|wc -l` -lt 1 ]] && sed -i '/from bottle import request/a request.MEMFILE_MAX=1024000'  /usr/lib/python2.6/site-packages/vnc_cfg_api_server/vnc_cfg_api_server.py

####
# IFMAp fixes
###
if [[ -f /etc/irond/basicauthusers.properties ]]; then
	dns_cred_str=`grep -w ^dns-user /etc/irond/basicauthusers.properties | head -1|cut -d: -f2`
	control_cred_str=`grep -w ^control-user /etc/irond/basicauthusers.properties |head -1| cut -d: -f2`
        dns_pub_id=`head -c10 <(echo $RANDOM$RANDOM$RANDOM)`
        control_pub_id=`head -c10 <(echo $RANDOM$RANDOM$RANDOM)`
	grep  contrail-api- /etc/haproxy/haproxy.cfg | awk '{print $3}'| cut -d: -f1 | while read aa
	do 
		host_name=`grep -w $aa /etc/hosts| grep -v ^# | awk '{print $2}'|cut -d\. -f1`
	 	[[ `grep -w dns-user-${host_name} /etc/irond/basicauthusers.properties | wc -l` -lt 1 ]] && echo "dns-user-${host_name}:${dns_cred_str}" >>  /etc/irond/basicauthusers.properties
	 	[[ -f /etc/irond/publisher.properties ]] && { sed -i "/^dns-user-${host_name}/d" /etc/irond/publisher.properties; echo "dns-user-${host_name}=dns-user-${host_name}-$dns_pub_id-1" >>  /etc/irond/publisher.properties; }
	 	[[ `grep -w control-user-${host_name} /etc/irond/basicauthusers.properties | wc -l` -lt 1 ]] && echo "control-user-${host_name}:${control_cred_str}" >>  /etc/irond/basicauthusers.properties
	 	[[ -f /etc/irond/publisher.properties ]] && { sed -i "/^control-user-${host_name}/d" /etc/irond/publisher.properties; echo "control-user-${host_name}=control-user-${host_name}-$control_pub_id-1" >>  /etc/irond/publisher.properties; }
                dns_pub_id=$((dns_pub_id + 1))
                control_pub_id=$((control_pub_id + 1))
	done
fi
local_host_name=`echo $HOSTNAME|cut -d\. -f1`
[[ -f /etc/contrail/contrail-control.conf && `grep -w control-user-${local_host_name} /etc/contrail/contrail-control.conf |wc -l` -lt 1 ]] && sed -i "/=control-user/ s/control-user/control-user-${local_host_name}/" /etc/contrail/contrail-control.conf
[[ -f /etc/contrail/dns.conf && `grep -w dns-user-${local_host_name} /etc/contrail/dns.conf |wc -l` -lt 1 ]] && sed -i "/=dns-user/ s/dns-user/dns-user-${local_host_name}/" /etc/contrail/dns.conf

#####################################################################################################
# Redis iptables stop gap fix till https://bugs.launchpad.net/juniperopenstack/+bug/1392113 is fixed
#####################################################################################################
#if [[ -f /etc/redis.conf ]]; then
#     # Accept from local
#     REDIS_PORT=`grep port /etc/redis.conf | grep -v ^# | head -1 |awk '{print $2}'`
#     [[ `iptables -L | grep $REDIS_PORT | grep localhost | wc -l` -lt 1 ]] && iptables -A INPUT -p tcp --dport $REDIS_PORT -s "127.0.0.1" -j ACCEPT
#     grep  contrail-api- /etc/haproxy/haproxy.cfg | awk '{print $3}'| cut -d: -f1 | while read aa
#            do
#		  HOST_NAME=`grep $aa /etc/hosts | grep -v ^#|head -1 |awk '{print $2}'| cut -d\. -f1`
#                  [[ `iptables -L | grep $REDIS_PORT | egrep '$HOST_NAME|$aa' | wc -l` -lt 1 ]] && iptables -A INPUT -p tcp --dport $REDIS_PORT -s $aa -j ACCEPT
#            done
#
## Save the iptable rules 
#service iptables save
#fi

#####
#  Restart services
#####
if [[ -f /etc/contrail/contrail-api.conf ]]; then
        service keepalived start
        service haproxy start
        service zookeeper start
        service redis start
        service supervisor-analytics start
        service supervisor-config start
        service supervisor-control start
        service supervisor-webui start
        service supervisord-contrail-database   start
        service neutron-server start
elif [[ -f /etc/contrail/contrail-vrouter-agent.conf ]]; then
	[[ -f /etc/init.d/supervisor-vrouter && `grep supervisor_killall /etc/init.d/supervisor-vrouter | wc -l ` -gt 0 ]] && sed -i "/\/usr\/bin\/supervisor_killall*/d" /etc/init.d/supervisor-vrouter
	rm -rf /var/log/nova; rm -rf /var/lib/nova
	ln -s /data/var/log/nova /var/log/nova
	ln -s /data/var/lib/nova /var/lib/nova
	[[ ! -d /var/lib/nova/instances ]] && { mkdir -p /var/lib/nova/instances; chown nova:nova /var/lib/nova/instances; }
	chkconfig openstack-nova-compute on
	chkconfig supervisor-vrouter on
        service openstack-nova-compute start
        service supervisor-vrouter start
fi
