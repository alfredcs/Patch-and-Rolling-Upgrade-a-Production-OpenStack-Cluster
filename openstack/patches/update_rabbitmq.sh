#!/bin/bash
set -x
[[ `id -u` -ne 0 ]] && { echo  "Must be root!"; exit 0; }
if [[ -f  /etc/nova/nova.conf ]]; then
	wpc_rabbit_passwd=`cat /etc/nova/nova.conf|grep neutron_admin_password| grep -v ^# | cut -d\= -f2|sed 's/^\s*//'`
	if [[ `rabbitmqctl list_users| grep wpc|wc -l` -lt 1 && `rabbitmqctl cluster_status| grep running |wc -l` -gt 0 ]]; then
		rabbitmqctl change_password guest ${wpc_rabbit_passwd}
	fi

	[[ -f /etc/glance/glance-api.conf ]] && openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_userid guest
	if [[ -f /etc/glance/glance-api.conf ]]; then
		openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_password ${wpc_rabbit_passwd}
        	openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_host `ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
        	openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_port 5673
	fi
        openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_userid guest
        [[ -d /etc/cinder ]] && openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_userid guest
        openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_password ${wpc_rabbit_passwd}
        [[ -d /etc/cinder ]] && openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_password ${wpc_rabbit_passwd}
	[[ -f /etc/haproxy/haproxy.cfg && `grep 48h /etc/haproxy/haproxy.cfg | grep -v ^# | wc -l` -lt 1 ]] && sed -i "s/.*server rabbitmq-api-1.*/    timeout  client 48h\n    timeout server 48h\n&/" /etc/haproxy/haproxy.cfg
	[[ -f /etc/openstack-dashboard/local_settings ]] && sed -i "/OPENSTACK_SSL_NO_VERIFY/ s/OPENSTACK_SSL_NO_VERIFY.*/OPENSTACK_SSL_NO_VERIFY = True/" /etc/openstack-dashboard/local_settings
	if [[ -f /etc/my.cnf ]]; then
		sed -i "/innodb_log_buffer_size/ s/innodb_log_buffer_size.*/innodb_log_buffer_size = 64M/" /etc/my.cnf
		[[ `grep innodb_thread_concurrency /etc/my.cnf |wc -l` -lt 1 ]] &&  sed -i "/innodb_buffer_pool_size/ s/innodb_buffer_pool_size.*/innodb_buffer_pool_size = 64G\ninnodb_thread_concurrency=8/" /etc/my.cnf
		[[ `grep innodb_thread_concurrency /etc/my.cnf |wc -l` -gt 0 ]] &&  sed -i "/innodb_buffer_pool_size/ s/innodb_buffer_pool_size.*/innodb_buffer_pool_size = 64G/" /etc/my.cnf
	fi

	[[ -f /usr/lib64/python2.6/site-packages/SQLAlchemy-0.7.8-py2.6-linux-x86_64.egg/sqlalchemy/orm/session.py ]] && sed -i "405s/raise.*/raise TypeError('Exception during transaction commit. Rolling back transaction.')/" /usr/lib64/python2.6/site-packages/SQLAlchemy-0.7.8-py2.6-linux-x86_64.egg/sqlalchemy/orm/session.py
	[[ ! -d /var/lib/nova/instances ]] && { mkdir -p /var/lib/nova/instances; chown nova:nova /var/lib/nova/instances; }
	[[ `lsmod | grep vrouter| wc -l` -gt 0 ]] && chkconfig openstack-nova-compute on
	sed -i '/^quota_instances/ s/quota_instances=.*/quota_instances=5000/g' /etc/nova/nova.conf
	sed -i '/^quota_cores/ s/quota_cores=.*/quota_cores=50000/g' /etc/nova/nova.conf
	sed -i '/^quota_ram/ s/quota_ram=.*/quota_ram=5120000000/g' /etc/nova/nova.conf
	sed -i '/^quota_security_groups/ s/quota_security_groups=.*/quota_ssisecurity_groups=5120000000/g' /etc/nova/nova.conf
	local_ip_addr=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'|tr -d ' '`
	openstack_vip=`grep auth_host /etc/nova/nova.conf | grep -v ^# | head -1 | cut -d= -f2|tr -d ' '`
	#####
	# Concurrency opertimizer
	####
	openstack-config --set /etc/nova/nova.conf DEFAULT heal_instance_info_cache_interval 0
	openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url_timeout 100
	
	#####
	# Adjust timeout to allow up to 180s response time
	#####
	sed -i '/5000/ s/timeout connect/#timeout connect/' /etc/haproxy/haproxy.cfg
	sed -i '/timeout connect/ s/10s/180s/' /etc/haproxy/haproxy.cfg
	sed -i '/http-request/ s/10s/180s/' /etc/haproxy/haproxy.cfg
	sed -i '/http-keep-alive/ s/10s/180s/' /etc/haproxy/haproxy.cfg
	sed -i '/timeout check/ s/10s/180s/' /etc/haproxy/haproxy.cfg
	sed -i '/50000/ s/timeout client/#timeout client/' /etc/haproxy/haproxy.cfg
	sed -i '/50000/ s/timeout server/#timeout server/' /etc/haproxy/haproxy.cfg

	######
	# Insert cron job on OpenStack controller to purge toekn every 10 minutes
	######
	if [[ -f /etc/glance/glance-api.conf ]]; then
		[[ -f /etc/haproxy/haproxy.cfg && ${local_ip_addr} == `grep horizon-api-1 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'|tr -d ' '` ]] &&  crontab -l | { cat; [[ `crontab -l| grep keystone-manage| wc -l` -lt 1 ]] && echo "3,33 * * * *  /usr/bin/keystone-manage token_flush >/dev/null 2>&1"; } | crontab -
		[[ -f /etc/haproxy/haproxy.cfg && ${local_ip_addr} == `grep horizon-api-2 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'|tr -d ' '` ]] &&  crontab -l | { cat; [[ `crontab -l| grep keystone-manage| wc -l` -lt 1 ]] && echo "13,43 * * * *  /usr/bin/keystone-manage token_flush >/dev/null 2>&1"; } | crontab -
		[[ -f /etc/haproxy/haproxy.cfg && ${local_ip_addr} == `grep horizon-api-3 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'|tr -d ' '` ]] &&  crontab -l | { cat; [[ `crontab -l| grep keystone-manage| wc -l` -lt 1 ]] && echo "23,53 * * * *  /usr/bin/keystone-manage token_flush >/dev/null 2>&1"; } | crontab -
	fi

	######
	# Active-passive for nova-api calls to avoid deadlock
	######
	if [[ -f /etc/haproxy/haproxy.cfg && `grep mysql-api /etc/haproxy/haproxy.cfg | grep -v ^# | grep 3307 |wc -l` -lt 1 ]]; then
		sed -i '/server/ s/inter 2000/inter 12000/g' /etc/haproxy/haproxy.cfg
		echo  >> /etc/haproxy/haproxy.cfg 
		echo "listen mysql-api 0.0.0.0:3307" >> /etc/haproxy/haproxy.cfg
		echo "    balance leastconn" >> /etc/haproxy/haproxy.cfg
		echo "    mode tcp" >> /etc/haproxy/haproxy.cfg
		echo "    option tcplog" >> /etc/haproxy/haproxy.cfg
		echo "    option contstats" >> /etc/haproxy/haproxy.cfg
		echo "    option httpchk HEAD / HTTP/1.1\r\n" >> /etc/haproxy/haproxy.cfg
		echo "    server mysql-active-standby-1 `grep horizon-api-1 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'`:3306 check port 60114 inter 12000 fall 4 rise 3" >> /etc/haproxy/haproxy.cfg
		echo "    server mysql-active-standby-2 `grep horizon-api-2 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'`:3306 check port 60114 inter 12000 fall 4 rise 3 backup" >> /etc/haproxy/haproxy.cfg
		echo "    server mysql-active-standby-3 `grep horizon-api-3 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'`:3306 check port 60114 inter 12000 fall 4 rise 3 backup" >> /etc/haproxy/haproxy.cfg
	fi
	if [[  -f /etc/haproxy/haproxy.cfg && `grep mysql-2-api /etc/haproxy/haproxy.cfg | grep -v ^# | grep 3308 |wc -l` -lt 1 ]]; then
                echo  >> /etc/haproxy/haproxy.cfg
                echo "listen mysql-2-api 0.0.0.0:3308" >> /etc/haproxy/haproxy.cfg
                echo "    balance leastconn" >> /etc/haproxy/haproxy.cfg
                echo "    mode tcp" >> /etc/haproxy/haproxy.cfg
                echo "    option tcplog" >> /etc/haproxy/haproxy.cfg
                echo "    option contstats" >> /etc/haproxy/haproxy.cfg
                echo "    option httpchk HEAD / HTTP/1.1\r\n" >> /etc/haproxy/haproxy.cfg
                echo "    server mysql-active-active-1 `grep horizon-api-1 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'`:3306 check port 60114 inter 12000 fall 4 rise 3" >> /etc/haproxy/haproxy.cfg
                echo "    server mysql-active-active-2 `grep horizon-api-2 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'`:3306 check port 60114 inter 12000 fall 4 rise 3" >> /etc/haproxy/haproxy.cfg
                echo "    server mysql-active-active-3 `grep horizon-api-3 /etc/haproxy/haproxy.cfg |cut -d: -f1| awk '{print $3}'`:3306 check port 60114 inter 12000 fall 4 rise 3" >> /etc/haproxy/haproxy.cfg
	fi
	if [[ ${local_ip_addr} && ${openstack_vip} ]]; then
		# Use Load Balanced IP has caused Keystone sluggishness, Reset back to use local MySQL. Keep syntext for future change when/if needed.
		# sed -i "/[^connection && mysql]/ s/${local_ip_addr}\/keystone/${openstack_vip}:3308\/keystone/" /etc/keystone/keystone.conf
		sed -i "/[^connection && mysql]/ s/${local_ip_addr}\/keystone/${openstack_vip}:3308\/keystone/" /etc/keystone/keystone.conf
		sed -i "/[^connection && mysql]/ s/${local_ip_addr}:3306\/keystone/${openstack_vip}:3308\/keystone/" /etc/keystone/keystone.conf
                sed -i "/[^sql_connection && mysql]/ s/${local_ip_addr}\/glance/${openstack_vip}:3308\/glance/" /etc/glance/glance-api.conf
                sed -i "/[^sql_connection && mysql]/ s/${local_ip_addr}:3306\/glance/${openstack_vip}:3308\/glance/" /etc/glance/glance-api.conf
                sed -i "/[^sql_connection && mysql]/ s/${local_ip_addr}\/glance/${openstack_vip}:3308\/glance/" /etc/glance/glance-registry.conf
                sed -i "/[^sql_connection && mysql]/ s/${local_ip_addr}:3306\/glance/${openstack_vip}:3308\/glance/" /etc/glance/glance-registry.conf
		sed -i "/[^connection && mysql]/ s/${openstack_vip}\/nova/${openstack_vip}:3307\/nova/" /etc/nova/nova.conf 
		sed -i "/[^connection && mysql]/ s/${local_ip_addr}\/nova/${openstack_vip}:3307\/nova/" /etc/nova/nova.conf 
	fi
fi

#########
# Force Glance API to check tokens
#########
[[ -f /etc/glance/glance-api.conf ]] && { openstack-config --set /etc/glance/glance-api.conf paste_deploy config_file /etc/glance/glance-api-paste.ini; openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone; } 

#########
# If this is a SDN controller
#########
if [[ -f  /etc/contrail/contrail-api.conf &&  -f /etc/neutron/neutron.conf ]]; then
	#####
        # Adjust timeout to allow up to 180s response time
        #####
        sed -i '/5000/ s/timeout connect/#timeout connect/' /etc/haproxy/haproxy.cfg
        sed -i '/timeout connect/ s/10s/180s/' /etc/haproxy/haproxy.cfg
        sed -i '/http-request/ s/10s/180s/' /etc/haproxy/haproxy.cfg
        sed -i '/http-keep-alive/ s/10s/180s/' /etc/haproxy/haproxy.cfg
        sed -i '/timeout check/ s/10s/180s/' /etc/haproxy/haproxy.cfg
        sed -i '/50000/ s/timeout client/#timeout client/' /etc/haproxy/haproxy.cfg
        sed -i '/50000/ s/timeout server/#timeout server/' /etc/haproxy/haproxy.cfg	
	wpc_rabbit_passwd=`cat /etc/neutron/neutron.conf|grep admin_password| grep -v ^# | cut -d\= -f2|sed 's/^\s*//'`
	openstack-config --set /etc/contrail/contrail-api.conf DEFAULTS rabbit_user guest
        openstack-config --set /etc/contrail/contrail-api.conf DEFAULTS rabbit_password ${wpc_rabbit_passwd}
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_userid guest
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_password ${wpc_rabbit_passwd}
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_port 5672
	[[ -d /var/log/contrail ]] && chmod -R o-rwx /var/log/contrail
	[[ -d /data/var/log/contrail ]] && chmod -R o-rwx /data/var/log/contrail
	[[ -f /etc/redis.conf ]] && sed -i "/127.0.0.1/ s/^Bind/#Bind/i" /etc/redis.conf

	####
	# Changes related to cincurrency boost
	####
	sed -i "/^MAX_REQUEST_LINE/ s/MAX_REQUEST_LINE.*/MAX_REQUEST_LINE = 65536/" /usr/lib64/python2.6/site-packages/gevent/pywsgi.py
	sed -i "/timeout/ s/timeout=.*/timeout=200,/" /usr/lib/python2.6/site-packages/cfgm_common/zkclient.py
	openstack-config --set /etc/neutron/neutron.conf quotas quota_items network
	openstack-config --set /etc/contrail/contrail-api.conf DEFAULTS list_optimization_enabled True
fi
#########
# Lock down the cred file access
#########
[[ -d /etc/keystone ]] && { chown keystone:keystone -R /etc/keystone; chmod o-rx -R /etc/keystone; }
[[ -d /etc/glance ]] && { chown -R glance:glance -R /etc/glance; chmod o-rx -R /etc/glance; }
[[ -d /etc/nova ]] && { chown -R nova:nova -R /etc/nova; chmod o-rx -R /etc/nova; }
[[ -d /etc/neutron ]] && { chown -R neutron:neutron -R /etc/neutron; chmod o-rx -R /etc/neutron; }
[[ -d /etc/cinder ]] && { chown -R cinder:cinder -R /etc/cinder; chmod o-rx -R /etc/cinder; }

#########
# Remove installation pkgs
#########
for pkg_inst in openstack-install3 sdn-install3 compute-install3
do
	pkg_name=`rpm -qa | grep ${pkg_inst}`
	[[ ${pkg_name} ]] && rpm -e --nodeps ${pkg_name}
	[[ -d /opt/${pkg_inst} ]] && rm -rf /opt/${pkg_inst}
done
