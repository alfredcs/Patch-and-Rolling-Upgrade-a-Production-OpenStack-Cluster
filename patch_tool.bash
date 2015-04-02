#!/bin/bash
function usage() {
cat <<EOF
usage: $0 options

This script will patch desired patch release to an openstack, sdn or compute node

Example:
        patch_tool.bash [-i|-n|-b|-h|-r] 

OPTIONS:
  -b -- backout a patch
  -h -- Help Show this message
  -v -- Verbose Verbose output
  -n -- Dry run
  -r -- Repo name for patch upgrades
  -i -- Install patches

EOF
}

service_running() {
    service $1 status >/dev/null 2>&1
}
ECHO_FLAG="";ECHO_FLAG_END="e";contrail_repo_name=""
back_out=0;install_flag=0
[[ `id -u` -ne 0 ]] && { echo  "Must be root!"; exit 0; }
[[ $# -lt 1 ]] && { usage; exit 1; }
while getopts "inbhvr:" OPTION; do
case "$OPTION" in
b)
	back_out=1
	;;
h)
        usage
        exit 0
        ;;
n)
        ECHO_FLAG="echo " 
        ;;
r)
        contrail_repo_name="$OPTARG"
        ;;
i)
        install_flag=1
        ;;
v)
        set -x
        ;;
\?)
        echo "Invalid option: -"$OPTARG"" >&2
        usage
        exit 1
        ;;
:)
        usage
        exit 1
        ;;
esac
done
[[ ${install_flag} == 1 && ${back_out} == 1 ]] && { usage; exit 1; }
[[ ${install_flag} == 0 && ${back_out} == 0 ]] && { usage; exit 1; }
TOP_DIR=`pwd`
if [[ `rpm -qa |grep -i openstack-nova-api|wc -l` -gt 0 && `rpm -qa |grep -i contrail-openstack-database |wc -l` -lt 1 ]]; then
	echo "Patch Openstack controller"
	target_dir="openstack"
elif [[ `rpm -qa |grep -i contrail-openstack-database |wc -l` -gt 0 ]]; then
	echo "Patch Contrail controller node"
	target_dir="contrail"
	[[ ${contrail_repo_namne} ]] && upgrade_contrail
elif [[ `rpm -qa |grep -i contrail-vrouter|wc -l` -gt 0 ]]; then
	echo "Patching compute node"
	target_dir="compute"
else
	echo "Do nothing!"
fi
[[ ! -d $TOP_DIR/${target_dir}/actions ]] && exit 0 
##
# Upgrade first!
##!
for action_fd in `ls $TOP_DIR/${target_dir}/actions/*.README`
do
        exec_cmd=`grep __execution__ ${action_fd} | grep -v ^# | cut -d= -f2|sed 's/^[ \t]*//'|sed 's/[ \t]*$//'`
        [[ ! -z ${exec_cmd} ]] && ${ECHO_FLAG} eval ${exec_cmd}
done

##
# Always patch individuals afterward!!
##
for action_fd in `ls $TOP_DIR/${target_dir}/actions/*.README`
do
        source_file=`grep __source__ ${action_fd} | grep -v ^# | cut -d= -f2|sed 's/^[ \t]*//'|sed 's/[ \t]*$//'`
        dest_file=`grep __destination__ ${action_fd} | grep -v ^# | cut -d= -f2|sed 's/^[ \t]*//'|sed 's/[ \t]*$//'`
	[[ ${dest_file} ]] && dest_dir=$(dirname ${dest_file})
	[[ ! -d ${dest_dir} && ${dest_dir} ]] && mkdir -p ${dest_dir}
        if [[ ${install_flag} == 1 ]]  ; then
		[[ ${dest_file} && ! -f ${dest_file} ]] && echo "Target ${dest_file} does not exist! Will create a new copy!!"
                [[ ${dest_file} && -f ${dest_file} ]] && ${ECHO_FLAG} /bin/cp -fp ${dest_file} ${dest_file}.backout
		[[ ${source_file} && ! -f ${TOP_DIR}/${target_dir}/${source_file} ]] && { echo "Source file ${TOP_DIR}/${target_dir}/${source_file} does not exist! Ignored it."; continue; }
                [[ ${source_file} && ${dest_file} ]] && ${ECHO_FLAG} /bin/cp -pf ${TOP_DIR}/${target_dir}/${source_file} ${dest_file}
        elif [[ ${back_out} == 1 ]]; then
		[[ ! -f ${dest_file}.backout ]] && { echo "Backout source  ${dest_file}.backout does not exist!"; continue; }
                ${ECHO_FLAG} /bin/cp -fp ${dest_file}.backout ${dest_file}
        else
                echo "/bin/cp -pf ${TOP_DIR}/${target_dir}/${source_file} ${dest_file}"
        fi
done

[[ ${ECHO_FLAG} == "echo " ]] && exit 0
if [[ ${target_dir} == "openstack" ]]; then
        echo "Restarting Openstack controller ......"
	chkconfig xinetd on; service xinetd restart
	chkconfig rsyslog on; service rsyslog restart
	if service_running mysql; then  chkconfig mysql on; service mysql restart; fi
	if service_running rabbitmq-server; then  chkconfig rabbitmq-server on; service rabbitmq-server restart; fi
	if service_running haproxy; then  chkconfig haproxy on; service haproxy restart; fi
	if service_running keepalived; then  chkconfig keepalived on; service keepalived restart; fi
	if service_running xinetd; then  chkconfig xinetd on; service xinetd restart; fi
	if service_running openstack-keystone; then  chkconfig openstack-keystone on; service openstack-keystone restart; fi
	if service_running openstack-glance-api; then  chkconfig openstack-glance-api on; service openstack-glance-api restart; fi
	if service_running openstack-glance-registry; then  chkconfig openstack-glance-registry on; service openstack-glance-registry restart; fi
	if service_running openstack-glance-scrubber; then  chkconfig openstack-glance-scrubber on; service openstack-glance-scrubber restart; fi
	if service_running openstack-nova-api; then  chkconfig openstack-nova-api on; service openstack-nova-api restart; fi
	if service_running openstack-nova-cert; then  chkconfig openstack-nova-cert on; service openstack-nova-cert restart; fi
	if service_running openstack-nova-conductor ; then chkconfig openstack-nova-conductor on;  service openstack-nova-conductor restart; fi
	if service_running openstack-nova-consoleauth; then chkconfig openstack-nova-consoleauth on; service openstack-nova-consoleauth restart; fi
	if service_running openstack-nova-novncproxy; then chkconfig openstack-nova-novncproxy on; service openstack-nova-novncproxy restart; fi
	if service_running openstack-nova-scheduler; then chkconfig openstack-nova-scheduler on; service openstack-nova-scheduler restart; fi
	if service_running httpd; then chkconfig httpd on; service httpd  restart; fi
	if service_running openstack-cinder-api; then chkconfig openstack-cinder-api on; service openstack-cinder-api restart; fi
	if service_running openstack-cinder-scheduler; then chkconfig openstack-cinder-scheduler on; service openstack-cinder-scheduler  restart; fi
	if service_running openstack-cinder-volume; then chkconfig openstack-cinder-volume on; service openstack-cinder-volume  restart; fi
	if service_running openstack-cinder-backup; then chkconfig openstack-cinder-backup on; service openstack-cinder-backup  restart; fi
	service xinetd restart
elif  [[ ${target_dir} == "contrail" ]]; then
        echo "Restarting Contrail controller ......"
	chkconfig xinetd on; service xinetd restart
        chkconfig rsyslog on; service rsyslog restart
        if service_running haproxy; then  chkconfig haproxy on; service haproxy restart; fi
        if service_running keepalived; then  chkconfig keepalived on; service keepalived restart; fi
	if service_running supervisor-analytics; then chkconfig supervisor-analytics on; service supervisor-analytics restart; fi
	if service_running supervisor-config; then chkconfig supervisor-config on; service supervisor-config restart; fi
	if service_running supervisor-control; then chkconfig supervisor-control on; service supervisor-control restart; fi
	#service supervisor-dns restart; fi
	if service_running supervisor-webui; then chkconfig supervisor-webui on; service supervisor-webui restart; fi
	if service_running supervisord-contrail-database; then chkconfig supervisord-contrail-database on; service supervisord-contrail-database restart; fi
	if service_running neutron-server; then chkconfig neutron-server on; service neutron-server restart; fi
elif [[ ${target_dir} == "compute" ]]; then
        echo "Restarting Compute ......"
	chkconfig xinetd on; service xinetd restart
	if service_running openstack-nova-compute; then chkconfig openstack-nova-compute on; service openstack-nova-compute restart; fi
	if service_running supervisor-vrouter; then chkconfig supervisor-vrouter on; service supervisor-vrouter restart; fi
	sleep 10
	chkconfig check_nova_compute on; service check_nova_compute restart
else
        echo "Do nothing!"
fi
