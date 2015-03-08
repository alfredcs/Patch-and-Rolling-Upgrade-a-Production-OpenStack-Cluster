#!/bin/bash
function usage() {
cat <<EOF
usage: $0 options

This script will patch desired patch release to an openstack, sdn or compute node

Example:
        patch_tool.bash [-i|-n|-b|-h] 

OPTIONS:
  -b -- backout a patch
  -h -- Help Show this message
  -v -- Verbose Verbose output
  -n -- Dry run
  -i -- Install patches

EOF
}

service_running() {
    service $1 status >/dev/null 2>&1
}
ECHO_FLAG="";ECHO_FLAG_END=""
back_out=0;install_flag=0
[[ `id -u` -ne 0 ]] && { echo  "Must be root!"; exit 0; }
[[ $# -lt 1 ]] && { usage; exit 1; }
while getopts "inbhv" OPTION; do
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
elif [[ `rpm -qa |grep -i contrail-vrouter|wc -l` -gt 0 ]]; then
	echo "Patching compute node"
	target_dir="compute"
else
	echo "Do nothing!"
fi
[[ ! -d $TOP_DIR/${target_dir}/actions ]] && exit 0 
for action_fd in `ls $TOP_DIR/${target_dir}/actions/*.README`
do
        source_file=`grep __source__ ${action_fd} | grep -v ^# | cut -d= -f2|sed 's/^[ \t]*//'|sed 's/[ \t]*$//'`
        dest_file=`grep __destination__ ${action_fd} | grep -v ^# | cut -d= -f2|sed 's/^[ \t]*//'|sed 's/[ \t]*$//'`
        exec_cmd=`grep __execution__ ${action_fd} | grep -v ^# | cut -d= -f2|sed 's/^[ \t]*//'|sed 's/[ \t]*$//'`
	dest_dir=$(dirname ${dest_file})
	[[ ! -d ${dest_dir} ]] && mkdir -p ${dest_dir}
        if [[ ${install_flag} == 1 ]]  ; then
		[[ ! -f ${dest_file} ]] && echo "Target ${dest_file} does not exist! Will create a new copy!!"
                [[ -f ${dest_file} ]] && ${ECHO_FLAG} /bin/cp -fp ${dest_file} ${dest_file}.backout
		[[ ! -f ${TOP_DIR}/${target_dir}/${source_file} ]] && { echo "Source file ${TOP_DIR}/${target_dir}/${source_file} does not exist! Ignored it."; continue; }
                ${ECHO_FLAG} /bin/cp -pf ${TOP_DIR}/${target_dir}/${source_file} ${dest_file}
        elif [[ ${back_out} == 1 ]]; then
		[[ ! -f ${dest_file}.backout ]] && { echo "Backout source  ${dest_file}.backout does not exist!"; continue; }
                ${ECHO_FLAG} /bin/cp -fp ${dest_file}.backout ${dest_file}
        else
                echo "/bin/cp -pf ${TOP_DIR}/${target_dir}/${source_file} ${dest_file}"
        fi
	[[ ! -z ${exec_cmd} ]] && ${ECHO_FLAG} eval ${exec_cmd}
done

[[ ${ECHO_FLAG} == "echo " ]] && exit 0
if [[ ${target_dir} == "openstack" ]]; then
        echo "Restarting Openstack controller ......"
	if service_running mysql; then  service mysql restart; fi
	if service_running rabbitmq-server; then  service rabbitmq-server restart; fi
	if service_running haproxy; then  service haproxy restart; fi
	if service_running keepalived; then  service keepalived restart; fi
	if service_running keepalived; then  service keepalived restart; fi
	if service_running openstack-keystone; then  service openstack-keystone restart; fi
	if service_running openstack-glance-api; then  service openstack-glance-api restart; fi
	if service_running openstack-glance-registry; then  service openstack-glance-registry restart; fi
	if service_running openstack-glance-scrubber; then  service openstack-glance-scrubber restart; fi
	if service_running openstack-nova-api; then  service openstack-nova-api restart; fi
	if service_running openstack-nova-cert; then  service openstack-nova-cert restart; fi
	if service_running openstack-nova-conductor ; then  service openstack-nova-conductor restart; fi
	if service_running openstack-nova-consoleauth; then  service openstack-nova-consoleauth restart; fi
	if service_running openstack-nova-novncproxy; then  service openstack-nova-novncproxy restart; fi
	if service_running openstack-nova-scheduler; then  service openstack-nova-scheduler restart; fi
	if service_running httpd; then  service httpd  restart; fi
elif  [[ ${target_dir} == "contrail" ]]; then
        echo "Restarting Contrail controller ......"
	if service_running supervisor-analytics; then  service supervisor-analytics restart; fi
	if service_running supervisor-config; then  service supervisor-config restart; fi
	if service_running supervisor-control; then  service supervisor-control restart; fi
	#service supervisor-dns restart; fi
	if service_running supervisor-webui; then  service supervisor-webui restart; fi
	if service_running supervisord-contrail-database; then  service supervisord-contrail-database	restart; fi
	if service_running neutron-server; then  service neutron-server restart; fi
elif [[ ${target_dir} == "compute" ]]; then
        echo "Restarting Compute ......"
	if service_running openstack-nova-compute; then  service openstack-nova-compute restart; fi
	if service_running supervisor-vrouter; then  service supervisor-vrouter restart; fi
else
        echo "Do nothing!"
fi
