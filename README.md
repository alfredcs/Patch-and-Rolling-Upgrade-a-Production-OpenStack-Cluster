Add README
HA Release 1.10.1

    Openstack  Version "openstack-install3-1.10.1"
        OS Kernel Version
        New Features
        Package Name
        Package Location
        HA and Healthy Checks
        New Dependency List
        Bug Fixes
        Known Issues
        Suggested QA and CI Uptake Process
        Installation Changes
        Installation Steps
    Contrail SDN  Version "SDN-install3-1.10.1"
        OS Kernel Version
        Package Name
        Package Location
        HA and healthy checks
        New Dependency List
        Bug Fixes
        Known Issues
        Suggested QA and CI Uptake Process
        Installation Changes
        Installation Steps
    OpenStack/Contrail  Version "compute-install3-1.10.1"
        OS Kernel Version
        Package Name
        Package Location
        HA and healthy checks
        New Dependency List
        Bug Fixes
        Known Issues
        Suggested QA and CI Uptake Process
        Installation Changes
            Install Steps
    HA Release 1.10.2
        Openstack  Version "openstack-install3-1.10.2"
            OS Kernel Version
            New Features
            Package Name
            Package Location
            HA and Healthy Checks
            New Dependency List
            Bug Fixes
            Known Issues ( to be addressed in the next sdn-patches)
            Suggested QA and CI Uptake Process
            Installation Changes
        Contrail SDN  Version "sdn-install3-1.10.2"
            OS Kernel Version
            New Features
            Package Name
            Package Location
            HA and Healthy Checks
            New Dependency List
            Bug Fixes
            Known Issues ( to be addressed in the next sdn-patches)
            Suggested QA and CI Uptake Process
            Installation Changes
        OpenStack/Contrail Version "compute-install3-1.10.2"
            OS Kernel Version
            New Features
            Package Name
            Package Location
            HA and Healthy Checks
            New Dependency List
            Bug Fixes
            Known Issues ( to be addressed in the next sdn-patches)
            Suggested QA and CI Uptake Process
            Installation Changes
    Patch Release 1.21
        OS Kernel Version
        CentOS6.5 with 2.6.32-358.123.2.openstack.el6.x86_64 RDO kernel
            New Features
        Package Name
        sdn-patches-1.21-4-2014.12.04.x86_64.rpm sdn-patches-1.21-5-2014.12.19.x86_64.rpm
        Package Location
        wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo110
        Repo Location
        wpc0005.svc.lab.pls.wd:/opt/repos/havana/contrail_install_repo121.65
        HA and Healthy Checks
        check_ifmap on SDN control nodes listening on port 60126 as a part of the  xinetd services
            Bug Fixes
                OpenStack Fixes
                 
                Contrail fixes
            Known Issues ( any additional fixes, if needed will be scoped in for the next version of sdn-patches release)
            Suggested QA and CI Uptake Process
            Installation Step
            Suggested Patch Life Cycle Management and Development Process
        Patch Release 1.21 - v6
            OS Kernel Version
            New Features
            Package Name
            Package Location
            Repo Location
            HA and Healthy Checks
            Bug Fixes
            Known Issues
            Suggested QA and CI Uptake Process
            Installation Steps
        Patch Release 1.21 - v6.1

HA Release 1.10.1
Openstack  Version "openstack-install3-1.10.1"

This OpenStack installation package contains codes to install and configure a 3-node OpenStack control cluster based on the architecture detailed out in the SDN POC page.  The package will install Keystone, Glance and Nova components along with Neutron configuration on a 3-node cluster based on Havana 2013.2.2  code release. Additional components such as RabbitMQ, Keepalived, Haproxy and MySQL/Galera will also be installed to support the cluster operation.

A separated glusterfs cluster is required to serve glance image repository and other shared services. The cluster is essential for nova instance images if to support VM migration across different hypervisor. The glusterfs cluster is recommended to be built on a 2-node cluster with minimum 500G storage space. A installation script gluster_install.sh is included to standup such a cluster.

    OS Kernel Version
    CentOS6.4 2.6.32-358.123.2.openstack.el6.x86_64

    New Features
        To further ensure rabbitmq cluster reliability 
        Added health check scripts for Keystone, Glance, Nova and Rabbitmq
        Enforced Layer 7 health check on haproxy by using the enhanced health check scripts
        Integrate with xinetd to allow remote health check interface with other monitoring tools such as Nagios
        Allow filesystem clustering for glance image files based on glustergfs
        Enforce SSL on all APi services including Keystone, Glance, Nova and Neutron
        Bug fixes

    Package Name

    openstack-install3-1.10.1-2014.09.23.x86_64.rpm

    Package Location
    wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo106

    HA and Healthy Checks

    Following health check scripts have been added to ensure services are indeed healthy, rather than simply listening on the service port. Default haproxy only checks is a port is listening or not and often it causes false positive particularly for OpenStack services. In addition to the haproxy integration, all services are embedded with xinetd which allows remote service to connect. Simply  make calls (i.e. via telnet. curl, httplib and etc) to the designate ports should receive the status answer for the health status. Refer to /etc/services for port assignment of the individual health check services.

    For rabbitmq, new exchange and queue for health check are added. Under normal operation the queue length for health check should stay at 0.

     
        /usr/local/bin/check_keystone.py
        /usr/local/bin/check_glance.py
        /usr/local/bin/check_nova_api.py
        /usr/local/bin/check_rabbitmq.py
        /etc/xinetd.s/check_keystone
        /etc/xinetd.s/check_glance
        /etc/xinetd.s/check_nova_api
        /etc/xinetd.s/check_rabbitmq
        /etc/services

    New Dependency List
        xinetd >= 2.3.14
        haproxy-1.5-2014.07.09.x86_64.rpm
        libSM-1.2.1-2.el6.x86_64.rpm
        glusterfs-{server,rdma,fuse,cli,api,geo-replication,*}-3.5.2.el6.x86_64.rpm
        gmp-6.0.0-2014.08.26.x86_64.rpm
        libibverbs1-1.1.6-5.1.x86_64.rpm
        librdmacm1-1.0.17-3.1.x86_64.rpm

    Bug Fixes
        auth_token.py: For SSL support
        greenio.py: For close up socket after job is completed
        http.py: To allow Horizon to call glance image API with SSl enabed.

    Known Issues
        Nova calls to Contrail experience longer than ussual delay. THis is under investigation.

    Suggested QA and CI Uptake Process

        Check in to the local git

        Deploy on both virtual and bare metal servers

        Verify all components

        Failure injection tests

        Modify in needed and check in git afterward

        CI to uptake and Chef integration
    Installation Changes
    Two new cli options have been added for glusterfs server VIP and volume name.
         -e -- Glusterfs VIP
        -m -- Gluasterfs mount point volume name

        Example:

                openstack_install3.sh [-L] -v openstack_controller_vip   -c contrail_controller_vip  -F first_openstack_controller -S second_openstack_controller -T third_openstack_controller [ -e glusterfs_vip] [-m glusterfs_volume_name]

          Both are optional however without glusterfs, Glance images files are stored at local volume by default and not synced. API calls to extract image content might return data unavailable error.

 
Installation Steps

 
OpenStack HA Installation Steps
1. Make sure all control nodes' clock are synced and iptables rules allow needed connection requests
2. Make sure all Openstack controller nodes have needed entries in /etc/hosts, including VIPs
3. Make sure appropriate repos are specified in /etc/yum.repos.d4
4. Yum install openstack-install3 package
5. Identify an existing glusterfs cluster or configure a new one with following script
    Example: gluster_install.sh -c glusterfs_vip [-m mount_point] [-b brick_name] [-v volume_name] [-d device_name] ......
6. Install OpenStack components on the first OpenStack controller node
    i.e. openstack_install3.sh [-L] -v openstack_controller_vip   -c contrail_controller_vip  -F first_openstack_controller -S second_openstack_controller -T third_openstack_controller [ -e glusterfs_vip] [-m glusterfs_volume_name]
 
7. Repeat step 4 on the second OpenStack controller node
8. Repeat step 4 on the third OpenStack controller node
9. If needed, restart following services:
 
service rabbitmq-server start|stop|restart
service mysql start|stop|restart
service keepalived start|stop|restart
service haproxy start|stop|restart
service openstack-keystone start|stop|restart
service openstack-glance-api start|stop|restart
service openstack-glance-registry start|stop|restart
service openstack-nova-api start|stop|restart
service openstack-nova-cert start|stop|restart
service openstack-nova-conductor start|stop|restart
service openstack-nova-consoleauth start|stop|restart
service openstack-nova-novncproxy start|stop|restart
service openstack-nova-scheduler start|stop|restart
service httpd start|stop|restart
  
That's about it for OpenStack !
Icon

    Make sure that repositories are named correctly (havana_install_repo110)
    Make sure that hostname entries in the /etc/hosts file does not a underscore character.
    Before installing OpenStack controller on node 2 and node 3, make sure that iptables is flushed on the OpenStack controller node 1 installation.

        iptables -F
        service iptables save

 

 

 
Contrail SDN  Version "SDN-install3-1.10.1"

 

The SDN installation package contains codes to install, configure and provision Contrail services on a 3-node cluster based on V1.1 release. The package will install Contrail Database, UI, Control, Analytics and Config components on the 3-code cluster with multi-tenancy enabled. Contrail replaces Neutron by providing SDn solution to the native NaaS in OpenStack. By integrating with OpenStack, Contrail services interact with the already installed OpenStack cluster for credential and message queue services while OpenStack call Contrail API for network services. All interactions are through RESTful API calls.

     

    OS Kernel Version

    CentOS6.4 2.6.32-358.123.2.openstack.el6.x86_64
    New Features
        Eliminate Contrail "virtual" Python runtime environment to maintain Python runtime library and code simplicity.
        Optimize Cassandra data modelings
        Configuration parameter consistency
        Neutron v2 API compatibility, including allowed address pair.

        Openstack HA support

        Multiple L3 & L2 services in a chain.

        Server management via CLI.

        Enhanced vDNS features.

        Ceph support.

        syslog ingest and export support.

        Route target filtering.

        DKMS support.

    Package Name
    sdn-install3-1.10.1-2014.09.23.x86_64.rpm

    Package Location

        wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo106 for installation packages

        wpc0005.svc.lab.pls.wd:/opt/repos/contrail/contrail_install_repo110 for Contrail v1.1 codes and dependencies.
    HA and healthy checks

    Following health check scripts have been added to ensure services are indeed healthy, rather than simply listening on the service port. Default haproxy only checks is a port is listening or not and often it causes false positive particularly for OpenStack services. In addition to the haproxy integration, all services are embedded with xinetd which allows remote service to connect. Simply  make calls (i.e. via telnet. curl, httplib and etc) to the designate ports should receive the status answer for the health status. Refer to /etc/services for port assignment of the individual health check services.

    For rabbitmq, new exchange and queue for health check are added. Under normal operation the queue length for health check should stay at 0.

     
        /usr/local/bin/check_cassandra.py
        /usr/local/bin/check_neutron.py
        /usr/local/bin/check_contrail_api.py
        /usr/local/bin/check_analytics.py
        /usr/local/bin/check_discovery.py
        /etc/xinetd.s/check_cassandra
        /etc/xinetd.s/check_neutron
        /etc/xinetd.s/check_contrail_api
        /etc/xinetd.s/check_analytics
        /etc/xinetd.s/check_discovery
        /etc/services

    New Dependency List
        xinetd > 2.3.24
        haproxy-1.5-2014.07.09.x86_64.rpm
        libSM-1.2.1-2.el6.x86_64.rpm
        gmp-6.0.0-2014.08.26.x86_64.rpm
        ...and all other packages included in the repo directory

    Bug Fixes
        vnc_api.py: For Keystone SSL support
        greenio.py: For close up socket after job is completed
        vnc_auth_keystone.py: To allow Contrail API to call SSL enabled OpenStack services.
        contrail_plugin.py: To support SSL enabled Neutron API.
        Provisioning scripts to modify Contrail config templates and parameters.

    Known Issues

         Double failure of HA proxy is not supported in the beta release.

         Node failures cases require some settling down period before operations are done on the controller cluster. This period for beta drop is 6 minutes.

        Manual intervention may be needed in case of Node Shutdown and Isolation case if operations are performed in transient state.

        1¹st VM Spawn after node failure sometimes fails and requires a retry.

        Cold Reboot of Config nodes sometimes causes nova-scheduler to be dead.

        It is timing issue with MySQL that gets fixed by a restart of nova-scheduler.

        Multi-tenancy with HA is under test and may have issues.

        Contrail API does not support SSL

        Contrail UI shows "Control Node , Configuration unavailable"

        IntroSpec shows Discovery port down while the service and port are both up.


    Suggested QA and CI Uptake Process

        Check in to the local git

        Deploy on both virtual and bare metal servers

        Verify all components

        Failure injection tests

        Modify in needed and check in git afterward

        CI to uptake and Chef integration
    Installation Changes
     No changes was made since last release of sdn-install3. The script requires OpeStack cluster VIP and the ip address or hostnames of the 3 Contrail controll nodes.

        Example:

                contrail_neutron_install3.sh [-L] -o openstack_controller_vip   -F first_contrail_controller -S second_contrail_controller -T third_contrail_controller

          The installation script will fetch encrypted credential file from the specified OpenStack controller.

    Installation Steps

     
    Contrail HA Installation Steps
    1. Make sure all control nodes' clock are synced with OpenStack control nodes and iptables rules allow needed connection requests
    2. Make sure all Openstack controller nodes have needed entries in /etc/hosts, including VIPs
    3. Make sure appropriate repos are specified in /etc/yum.repos.d
    4. Yum install sdn-install3 package
    5. Install Contrail components on the first Contrail controller node
        i.e. ./contrail_neutron_install3.sh [-L] -o openstack_controller_vip  -F first_contrail_controller -S second_contrail_controller -T third_contrail_controller
     
    6. Repeat step 4 on the second Contrail controller node
    7. Repeat step 4 on the third Contrail controller node
    8. Restart all services list below all on the 3 Contrail controller nodes
        service keepalived restart
        service haproxy restart
        service zookeeper restart
        service supervisor-analytics restart
        service supervisor-config restart
        service supervisor-control restart
        service supervisor-webui restart
        service supervisord-contrail-database restart
        service neutron-server restart
     
    Now you have NaaS with SDN. Almost there......

 
OpenStack/Contrail  Version "compute-install3-1.10.1"

 

The compute installation package install, configure and provision Nova compute and vrouter services on a compute node. It fetch credentials from OpenStack controller and insert configuration parameters. This version on compute install supports two network interface allocation model for all-in-one and separation of admin and data services with or without NIC bonding. 

 

    OS Kernel Version
    CentOS6.4 2.6.32-358.123.2.openstack.el6.x86_64

     
    New Features
        Eliminate Contrail "virtual" Python runtime environment to maintain Python runtime library and code simplicity.
        Configuration parameter consistency
        OpenStack and Contrail HA support.

        Support MPLSoGRE, MPLSoUDP or VXLAN tunnels
        Supports mutiple vgws and multiple IP blocks

    Package Name
    compute-install3-1.10.1-2014.09.23.x86_64.rpm

    Package Location
    wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo106 for installation packages

    HA and healthy checks
    N/A

    New Dependency List
        xinetd >= 2.3.14
        haproxy-1.5-2014.07.09.x86_64.rpm
        libSM-1.2.1-2.el6.x86_64.rpm
        gmp-6.0.0-2014.08.26.x86_64.rpm
        ...and all other packages included in the Havana and Contrail repo directories listed

    Bug Fixes
        vnc_api.py: For Keystone SSL support
        greenio.py: For close up socket after job is completed
        vnc_auth_keystone.py: To allow Contrail API to call SSL enabled OpenStack services.
        contrail_plugin.py: To support SSL enabled Neutron API.
        Provisioning scripts to modify Contrail config templates and parameters.

    Known Issues

         Can only connect to 2 out of 3 services even max_control_nodes is defined as 3
    Suggested QA and CI Uptake Process

        Check in to the local git

        Deploy on both virtual and bare metal servers

        Verify all components

        Failure injection tests

        Modify in needed and check in git afterward

        CI to uptake and Chef integration
    Installation Changes
     No changes was made since last release of compute-install3. The script requires OpenStack cluster VIP from cli input.

        Example:

                compute_install3.sh [-L] -o openstack_controller_vip   

          The installation script will fetch encrypted credential file from the specified OpenStack controller.

 

    Install Steps

    Compute Installation Steps
    1. Make sure all compute node's clock is synced with OpenStack/Contrail control nodes
    2. Make sure all Openstack controller nodes have needed entries in /etc/hosts, including VIPs
    3. Make sure appropriate repos and specified in /etc/yum.repos.d
    4. make sure the OS kernel matches the prerequisite
    5. Yum install compute-install3 package
    6. Install Compute components on the designate compute node
        i.e. compute_install3.sh [-L] -o openstack_controller_vip
     
    7. Reboot the compute node
     
     
    The cluster should be up, Have fun!

 
HA Release 1.10.2

The 1.10.2 release is to enable WPC2.4 deployment based on CentOS 6.5 with RDO kernel, Havana 2013.2.3 and Contrail V1.1.2 with bug fixes. It is a upgrade version from the previous 1.10.1 release. Ceph will be included as an addition to the existing features as storage backend for for Glance and VMs. All required RPM packages are stored in the new havana_install_repo110 on wpc0005 in PLS lab.
Openstack  Version "openstack-install3-1.10.2"

    OS Kernel Version
    CentOS6.5 with 2.6.32-358.123.2.openstack.el6.x86_64 RDO kernel

    New Features
        Upgrade keepalived to support garp for better fault tolerance
        Support Cinder/Ceph backend for Glance ( to be done by Chef on after initial installation)
        Upgrade qemu-kvm to 0.12.1.2-2.415
        Upgrade OpenStack to 2013.2.3 for bug fixes on 20+ reported issues
        Open up iptable rules for needed ports

    Package Name
    openstack-install3-1.10.2-2014.10.15.x86_64.rpm ( For CentOS 6.4)
    openstack-install3-1.10.2-2014.10.23.x86_64.rpm ( For CentOS 6.5 with RDO kernel)

    Package Location

    wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo110

    Installation requires a predefined repo in etc/yum.repos.d with following entries
    Havana repo file
    [havana_install_repo110]
    name=havana_install_repo
    baseurl=http://<repo_server_name_or_ip>/havana110/
    enabled=1
    priority=1
    gpgcheck=0
    HA and Healthy Checks
    Add ssl to check_contrail_api.py

    New Dependency List
        libibverbs1-1.1.6-5.1.x86_64.rpm
        librdmacm1-1.0.17-3.1.x86_64.rpm
        gmp-devel-4.3.1-7.el6_2.2.x86_64.rpm


    Bug Fixes
    Known Issues ( to be addressed in the next sdn-patches)
        #1362854 Incorrect regex on rootwrap for encrypted volumes ln creation
        #1219658 Wrong image size using rbd backend for libvirt
        #1370191 db deadlock on service_update()
        Nova novncproxy  works only on one out of 3 attempts. 

    Suggested QA and CI Uptake Process
    (same)

    Installation Changes
    Openstack-install3 installation Steps
    1. Make sure all control nodes' clock are synced and iptables rules allow needed connection requests
    2. Make sure all Openstack controller nodes have needed entries in /etc/hosts, including VIPs. Use IP address and avoid using special charater such as _|*|- as hostname.
    3. Make sure appropriate repos are specified in /etc/yum.repos.d
    4. Yum install openstack-install3 package
    5. Identify an existing glusterfs cluster or configure a new one with following script
        Example: gluster_install.sh -c glusterfs_vip [-m mount_point] [-b brick_name] [-v volume_name] [-d device_name] ......
    6. Install OpenStack components on the first OpenStack controller node
        
     
    Example:
      
     openstack_install3.sh [-L] -v openstack_controller_vip   -c  contrail_controller_vip  -F first_openstack_controller -S  second_openstack_controller -T  third_openstack_controller
     
    7. Repeat step 4 on the second OpenStack controller node
    8. Repeat step 4 on the third OpenStack controller node
      
    That's about it for OpenStack !

Contrail SDN  Version "sdn-install3-1.10.2"

    OS Kernel Version
    CentOS6.5 with 2.6.32-358.123.2.openstack.el6.x86_64 RDO kernel

    New Features
        Upgrade keepalived to support garp for better fault tolerance
        Upgrade to Contrail v1.1.0fcs
        Enable SSL for Contrail API

    Package Name
    sdn-install3-1.10.2-2014.10.15.x86_64.rpm ( for CentOS 6.4)
    sdn-install3-1.10.2-2014.10.23.x86_64.rpm (for CentOS 6.5 with RDO kernel)

    Package Location

    wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo110
    For CentOS 6.5, the Contrail install repo file need to point to a new location which contains binaries build on C6.5 image. The installation requires following entries in the contrail_install_repo. The contrail110.65 dir a directory alias defined in Apache's httpd.conf.

     
    Contrail install repo
    [contrail_install_repo110]
    name=contrail_install_repo110
    baseurl=http://<repo_server_name_or_ip>/contrail110.65
    enabled=1
    priority=1
    gpgcheck=0
    HA and Healthy Checks
    New Dependency List
        libibverbs1-1.1.6-5.1.x86_64.rpm
        librdmacm1-1.0.17-3.1.x86_64.rpm

    Bug Fixes
        #1364908 [1.10-30] Traffic Drop seen in a transparent service-chain case when one of the Service VMs is deleted
        #1333810 [ubuntu-havana-R1.06-50] ECMP: instance cleanup failed after deleting SI
        #1328842 vnswad crashed after setup_all in virtual testbed
        #1329250 more than one port of a VN can be attached to a router
        #1332487 Creating a port with a name which already present is giving internal server error
        #1338425 R1.06-Build-59: Control-node crash seen when MX configured with advertise-default option
    Known Issues ( to be addressed in the next sdn-patches)
        #1372312 One ore more logs in svc_monitor.err is not having timestamps
        Contrail WebUI issues
        Provision_control.py on no-opt when providing ASN from CLI
        WebUI can not modify global router configuration
        WebUI displays incorrect interfaces even after VMs have been deleted.

    Suggested QA and CI Uptake Process
    (same)

    Installation Changes
    Contrail HA installation Steps
    1. Make sure all control nodes' clock are synced with OpenStack control nodes and iptables rules allow needed connection requests
    2. Make sure all Openstack controller nodes have needed entries in /etc/hosts, including VIPs. Use IP address and avoid using special charater such as _|*|- as hostname.
    3. Make sure contrail_install_repo110 is in /etc/yum.repos.d
    4. Yum install sdn-install3 package
    5. Install Contrail components on the first Contrail controller node with root privilege
        i.e.
        #cd /opt/sdn-install3
        #./contrail_neutron_install3.sh [-L] -o openstack_controller_vip  -F first_contrail_controller -S second_contrail_controller -T  third_contrail_controller [-n ASN_number]
       
        Where ASN is the number provided by the INF Network team to peer with the local MX pair. Default is 64512
      
    6. Repeat step 4 on the second Contrail controller node
    7. Repeat step 4 on the third Contrail controller node
    8. Restart all services list below all on the 3 Contrail controller nodes
        service keepalived restart
        service haproxy restart
        service zookeeper restart
        service supervisor-analytics restart
        service supervisor-config restart
        service supervisor-control restart
        service supervisor-webui restart
        service supervisord-contrail-database restart
        service neutron-server restart
      
    Now you have NaaS with SDN. Almost there......

OpenStack/Contrail Version "compute-install3-1.10.2"

    OS Kernel Version
    CentOS6.5 with 2.6.32-358.123.2.openstack.el6.x86_64 RDO kernel

    New Features
        Support Cinder/Ceph backend for VMs
        Upgrade qemu-kvm to 0.12.1.2-2.415
        Upgrade OpenStack to 2013.2.3 for bug fixes on 20+ reported issues

    Package Name
    compute-install3-1.10.2-2014.10.15.x86_64.rpm (For bother CentOS 6.4 and 6.5)

    Package Location
    wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo110

    HA and Healthy Checks
    N/A

    New Dependency List
        libibverbs1-1.1.6-5.1.x86_64.rpm
        librdmacm1-1.0.17-3.1.x86_64.rpm
        qemu-kvm-0.12.1.2-2.415.el6.x86_64.rpm

    Bug Fixes
    Known Issues ( to be addressed in the next sdn-patches)
        #1362854 Incorrect regex on rootwrap for encrypted volumes ln creation
        https://bugs.launchpad.net/juniperopenstack/+bug/1382220
        Discovery reports inconsistent XMPP servers a given vrouter is connecting to ( 2 sessions per vrouter) 

    Suggested QA and CI Uptake Process
    (same)
    Installation Changes
    Compute-install3
    1. Make sure all compute node's clock is synced with OpenStack/Contrail control nodes
    2. Make sure all Openstack controller nodes have needed entries in /etc/hosts, including VIPs
    3. Make sure to include havana_install_repo110 in /etc/yum.repos.d
    4. make sure the OS kernel matches the prerequisite
    5. Yum install compute-install3 package
    6. Install Compute components on the designate compute node with root privilege
        i.e. #cd /opt/compute-install3; ./compute_install3.sh [-L] -o openstack_controller_vip
      
    7. Reboot the compute node
      
      
    The cluster should be up, Have fun!

Patch Release 1.21

The sdn-patches-1.21 was released to perform rolling upgrades on a working OpenStack/SDN cluster. The patch utility will upgrade Contrail codes from V1.1 to V1.21 build 73 without impacting existing virtual machine and network configurations. The patch tool included in this release will install extra bug fixes, SSL enabled services and security enhancements, IFMAP optimization configuration on OpenStack control nodes, SDN control nodes and compute nodes. In addition, a newly developed IFMAP health check utility will also be installed on SDN control nodes to check and validate the consistency among cassandra, IFMAP and SDN Controller. The patch utility will apply changes on top of a operational cluster based on Contrail V1.1 release without manually changes made to the configuration files. The patch tool can be executed multiple times on any single node if needed.

    OS Kernel Version
    CentOS6.5 with 2.6.32-358.123.2.openstack.el6.x86_64 RDO kernel
    New Features
        Redis lock down using iptables
        Replace http based admin service with unix socks to prevent remote access to admin ports without credential validation. 
        Lock down rabbitmq with non-default credential
        Allow only root and privileged accounts ( i.e. nova) to view the contents of configuration files (i.e. nova.conf)
        Able to perform rolling upgrade on a working cluster
        Cassandra data snapshot for disaster recovery if needed during upgrade.
        Enable IFMAP verbose logs and reduce Analytics data retention duration from default 48 hours to 8 hours  
        Continuously support SSL on all customer facing RESTful APIs such as Nova and Contrail API. 
        Fixed a horizon permission issue on OpenStack controllers

    Package Name
    sdn-patches-1.21-4-2014.12.04.x86_64.rpm sdn-patches-1.21-5-2014.12.19.x86_64.rpm
    Package Location
    wpc0005.svc.lab.pls.wd:/opt/repos/havana/havana_install_repo110
    Repo Location
    wpc0005.svc.lab.pls.wd:/opt/repos/havana/contrail_install_repo121.65
    HA and Healthy Checks
    check_ifmap on SDN control nodes listening on port 60126 as a part of the  xinetd services
    Bug Fixes
        OpenStack Fixes

        #1370191	

        db deadlock on service_update()
        	Medium

        CLOUD-5292

        CLOUD-5471
        	Enforce Keystone token check for Glance API	

        High

        CLOUD-4951

        CLOUD-5294
        	Enforce RabbitMQ servcie account password	High
        CLOUD-5290	Remove encryption key after installation	High

        CLOUD-5295
        CLOUD-5299

        CLOUD-5300

        CLOUD-5303

        CLOUD-5306
        	Lockdown access permission for configuration and log files which contain credentials
        	High
        JIRA #	Increase Percona MySQL buffer and log size	Medium

         
         
        Contrail fixes
        #1374282	glance url in keystone catalog is set to localhost	Critical
        #1323204	Doing a interface-detach shuts down the VM 	High
        #1365277	Support transit VN to provide transitive connectivity between VNs/VPNs	High
        #1365322	Route towards SNAT SI continued to be present even after removing the subnet from router	High
        #1365839	schema crashes with NoIdError for a SI during gateway-related tests	High
        #1366210	Provision Storage UI based on webui role	High
        #1366216	Multiple storage-master roles not supported [HA requirement]	High
        #1366599	python-pbr package not installed on config nodes 	High
        #1367208	Std python neutronclient 2.3.7 module fails to authenticate with contrail-provisioned-keystone	High
        #1367227	router-list and show operations fail on icehouse	High
        #1368664	LB changes like healthmonitor, member addition/deletion does not update existing netns SI	High
        #1372384	[1.11-38] 'No more IP addresses available on network' Error seen on creating a router-interface, when allocation pool is specified without a gateway	High
        #1372875	Api Server uve shown as Non-functional on some setups	High
        #1373257	During tempest run on centos/icehouse, adding interface to router failed 	High
        #1373303	service monitor repeatedly crashing after tempest run	High
        #1373330	Snat not working Build 38 Ubuntu havana	High
        #1373739	On custom projects, Unable to view/delete lb-members	High
        #1373849	User can associate FIP in his project to a port in any other project	High
        #1373864	Disassociating health-monitor from a pool which is not associated throws internal server error	High
        #1374195	lb-vip-update: updating the vip with pool id throws internal server error 	High
        #1374401	Creating a second vip to a pool does not work	High
        #1375553	[centos64-icehouse-R1.10-#44] provision failure due to keepalived	High
        #1376129	health-monitor show doesn't list the LB pools it is associated with	High
        #1377511	livem provisioning fails as cinder.conf in openstack node points to openstack rabbitmq instead of the control node	High
        #1377758	Servermanager fails to start beause of missing directory	High
        #1378077	quota update is failing on icehouse	High
        #1378630	link local service tests failing on Build 1.10 48	High
        #1378729	vip-delete when the vip is bound to a FIP results in internal server error	High
        #1379240	[centos65-havana-R1.10-50] kernel panic during sanity	High
        #1381324	Creating a port by using fixed-ip is failing	High
        #1354919	In Contrail UI, need option to set limit on number of routers	Medium
        #1367183	[Contrail UI] any update of a VN causes address allocation to start from the end of the subnet	Medium
        #1369690	Support Upgrade from 1.10 to 1.20 for havana and icehouse	Medium
        #1372272	Mainline 2337:Contrail-status time out value too small	Medium
        #1376133	Incorrect error when LB Healthmonitor delete is tried when it is in use	Medium
        #1361520	fixed_ips field has two extra attributes port_id and net_id	Low
        #1372274	R1.10 build 37: Cassandra was started [default Cluster name ³Test"] before provisioning the database node	Undecided
        #1381779	VM launch fails . Subnet uuids different in API server and neutron	Undecided
        #1384034	Hardcoded Keys - Password in RndcSecret	Undecided
        #1367046	Wrong disk associated as Journal Disk	Critical
        #1363914	Quota Reset not working 	High
        #1373233	[1.10-Build 34]Inconsistent state is occurred between WebUI and Control node.	Medium
        #1365463	security-group-rule quota limit is set per security group not per tenant 	Undecided
        #1384335	Insecure Supervisor Deployment	Critical
        #1383896	Contrail-Analytics-API returns some stale UVEs	High
        #1392434	Unconfig_storage is not removing storage-stats daemon	High
        #1393201	Kernel crash while validating the multicast nexthop	High
        #1374114	Cannot chain multiple in-network services with a single compute node	Undecided
        #1376757	GW port should not be visible from users	Undecided
        #1377139	SVC monitor cannot show hidden resources	Undecided
        #1382235	Contrail does not enforce Neutron's RBAC	Undecided
        #1383101	config: api-server does not populate VN details in ifmap	Undecided
        #1384034	Hardcoded Keys - Password in RndcSecret	Undecided
        #1384338	Missing licensing in DNS package	Undecided
        #1386471	config-neutron: 'external_gateway_info' in router should be a dictionary	Undecided
        #1389183	SVC monitor cannot create VMI on 1.10	Undecided
        #1392132	SDN 1.1: IFMAP not updated on VN creation	Undecided
        #1392545	ACL duplicate rule check does not consider CIDR addresses	Undecided
        #1385541	config-neutron: security-group list with filter by name not working	Undecided
        CLOUD-5264 	Redis server port bound to the local real IP	Medium



    Known Issues ( any additional fixes, if needed will be scoped in for the next version of sdn-patches release)
        WebUI does not report the correct service status. Configuration functions within WebUI are not working properly (fixed).
        IFMAP irond generates large quantity of logs and disk space usage needs to be monitored.
        Only one of the svc_schema and svc_monitoring are active per SDN cluster (#1398567Contrail-status output inconsistency)
        #1398441Security policies cann't be associated if the name contains space for v1.21 
        #1398528 vnc_cfg_ifmap.py throws IOerror: Socket Closed (fixed)
        Deadlock on Sqlarchemy under high concurrency API requests. Nova's api.log  will log error and retry
        Cassandra stack size needs to be greater than 256k. Check cassandra.ymal file and modify or edit /etc/cassandra/cassandra-env.sh by changing JVM_OPTS="$JVM_OPTS -Xss256k"

    Suggested QA and CI Uptake Process
        Complete functional tests on virtual machines
        Complete integration tests with other post-1.1 additions
        Complete integration tests with Chef, Nagios and other INF services for operation readiness
        Complete integration on bare metal servers.
    Installation Step
    sdn-patches-1.21
    1. Make sure the target node has a functioning installation either as a OpenStack controller, SDN controller or Compute node.
    2. Make sure the /etc/yum.repos.d/contrail_install.repo contains following lines.  For example in AZ environment [root@compute1 sdn-patches-1.21]# cat /etc/yum.repos.d/contrail_install.repo [contrail_install_repo121] name=contrail_install_repo121 baseurl=http://10.52.224.34/contrail/contrail_install_repo121.65/ enabled=1 priority=1 gpgcheck=0
    3. Make the repo server has the latest sdn-patches-1.21 rpm packages.
    4. Install Compute components on the designate compute node with root privilege i.e. #yum -y install sdn-patches-1.21; cd /opt/sdn-patches-1.21; ./patch_tool.bash -i
    5. Repeat 1-4 on other nodes. Same step for OpenStack control nodes, SDN control nodes and Compute nodes
    Suggested Patch Life Cycle Management and Development Process

    Patch Release 1.21 - v6

    This release was inteneded to improve HA failure recovry time for compute nodes after the primary OpenStack controller fail-over to a standby node. HA failure injection tests have found that in PDX BMs, the auto recovery window for compute node after the primary controller failed could linger up to 2 hours  closed to the kernel's 7200 seconds tcp keep alive. During this transient state,  the down state cause impacts to admin modification tasks but not to admin query or VM operations.  This is  a known issue by the community and a detail description has been captured in this. With SDN, the kernel TCP tuning is more complex than other use cases particularly when Contrail services require persistent connections to rabbitmq. By tuning some parameters, we have brought down the auto recovery window to ~ 30 mins  but the result was not always consistent.  The alternative solution I'd like to propose is to introduce a healthy check daemon on compute node to periodically check for hypervisor status/uptime. It will issue a light way API call to NOVA API and has a built retry and timeout mechanism. The daemon will restart openstack-nova-compute if it detects 3 consecutive failures. A compute node should join the cluster automatically in a few minutes ( i.e. < 6 minutes ).

    Additional health checks for Contrail and Compute service have been added in the purpose of precisly discribe the status and service depedencies. The verbose output should help cloud administrator to quickly triage the root cause of operational issues whith little efforts. The health check could also be leveraged by dsahboard monitoring tolls such as Nagios. 

    OS Kernel Version
    CentOS6.5 with 2.6.32-358.123.2.openstack.el6.x86_64 RDO kernel

    New Features
        Contrail health check on Collector. Xinetd process check_collector listens on port 60127.
        Contrail health check on Controller. Xinetd process check_controller listens on port 60128.
        Contrail health check on API. Xinetd process check_api listens on port 60129.
        Compute  health check on Vrouter. Xinetd process check_vrouter listens on port 60130.
        Compute hypervisor health check daemon to ensure communication with Openstack controller is healthy. Daemon process check status every 60 seconds and it is added to chkconfig for auto restart.
        Enabled haproxy logging and log rotation on Openstack  and SDN controllers.
        Reconfigured Nova API to user active-standby MySQL to alliviate deadlock mentioned in v5
        Changed Haproxy L7 health check interval from 2 seconds to 12 seconds to reduce probing fregency and token validation requests
        Adjusted timeout allowance on pycassandra, haproxy and health check to enasure a job is completed before timeout.

    Package Name
    sdn-patches-1.21-6-2015.01.28.x86_64.rpm  sdn-patches-1.21-6-2015.02.07.x86_64.rpm

    Package Location
    wpc0034.svc.eng.pdx.wd:/data/repo_dev/havana/havana.231.65

    Repo Location

    The build 77 repo location: wpc0034.svc.eng.pdx.wd:/data/repo_dev/contrail/contrail.121.77

    Need to update the contrail install repo file with following repo name to differnciate build 77 from previous version.
    Contrail V1.21 B77 Repo
    [contrail_install_repo121.77]
     
    name=contrail_install_repo121.77
    baseurl=http://10.52.224.34/contrail_dev77  <-- Alias to the 1,21 b77 directory
    enabled=0
    priority=1
    gpgcheck=0
    HA and Healthy Checks
        Added check_mysql to probe Galera replication state as a part of L7 health check on port 60114.

    Bug Fixes

         Bumped up Nova quota limits on cores, cpus and ram high watermarks.
        Changes check_X.py to print out more meaningful contents.
        Ensured all required Openstack and contrail service are added to chkconfig for auto restart .
        Ensured xinetd is installed and configured in chkconfig.

        Changes included in the Contrail 1.21 Build 77

        187b262   fix the parameter to _port_list

        8f45fcb   config: Increase cassandra pool timeout values for api-server

        0579ca1   Merge "config-openstack: Optimize port-list by tenant-id" into R1.10

        86d83f2   Merge "config-openstack: reduce roundtrip in port-list by device-id fi

        9996097   Merge "Do not read subnet-uuid from useragent kv if not necessary." in

        a23e48e   allow large URL in HTTP request. Request from neutron plugin to api se

        eb402d0   config-openstack: reduce roundtrip in port-list by device-id filter

        ef9b1aa   config-openstack: Optimize port-list by tenant-id

        5b75350   Do not read subnet-uuid from useragent kv if not necessary.

        a8b320b   Check vrouter release before schedule VM SI

        2607526   Fix vrouter agent log files leakage Closes-bug: #1412305

        6bb5d55   Fix deadlock in RibOutUpdates::TailDequeue/PeerDequeue

        31a300b   Merge "Return const ref to RouteDistinguisher" into R1.10

        896ad0b   Merge "* Path preference change was enqueued every time, interface con

        5b13a69   ci_unittests.json lib LICENSE README.md SConscript src styleguide.rst

        45bb4f7   Merge "Pass contrail_extensions_enabled for DBInterface.__init__" into

        fad6f2e   Return const ref to RouteDistinguisher

        4869b8a   Merge "Allow for presence of reserved chars of >,<,& in name of object

        d7a8d32   Merge "Optimization fix in {resource}_count plugin_db APIs" into R1.10

        5410e89   Merge "Fix corner case in SchedulingGroup::UpdatePeerQueue logic" into

        55389c9   Allow for presence of reserved chars of >,<,& in name of object.

        e01fbd7   Merge "Disallow illegal xml chars and additonal restricted xml chars i

        71fb0ec   Merge "For classic user security-group-rule_list does not work properl

        e12740b   Fix corner case in SchedulingGroup::UpdatePeerQueue logic

        6706867   Merge "Handling no-security-group on VMIs" into R1.10

        6d02e43   Merge "Fix the compiler warnings in the contrail agent test cases" int

        31aacf0   Pass contrail_extensions_enabled for DBInterface.__init__

        dd16fb8   Fix the compiler warnings in the contrail agent test cases

        0dedc2e   Merge "Fix libtbb_debug issue - Leverage new UseSystemTBB() method to

        27177ec   For classic user security-group-rule_list does not work properly

        9c4d990   Merge "Automatic copy constructor for MacAddress doesn't work as expec

        ef1771d   Automatic copy constructor for MacAddress doesn't work as expected. Ad

        ad84c27   Delete the lb configuration files during cleanup

        a3c3f08   Issue: When both discovery IP and service IP is configured in contrail

        ef1b912   Fix libtbb_debug issue - Leverage new UseSystemTBB() method to use sys

        6f0646c   Merge "Fix compilation error with new compiler" into R1.10

        3db6b08   Merge "Use libraries available in centos 7.0" into R1.10

        6a90501   Merge "Do not compile third-party libraries available on ubuntu" into

        38b74f8   Merge "Commit on behalf of pedro" into R1.10

        360fcc7   Merge "task_test is only needed for test targets" into R1.10

        9547b63   Merge "Call getpid() directly instead of using an internal API." into

        cff7668   Merge "monotonic_deadline_timer replaces by steady_timer in boost 1.49

        ac310e5   Merge "Use Cpp{Enable,Disable}Exceptions macro" into R1.10

        8460901   Merge "boost::asio::monotonic_deadline_timer replaced by steady_timer

        fb03d3b   Merge "Close all the fds of the child before exec" into R1.10

        5b9bbcc   Close all the fds of the child before exec

        4f476e6   Optimization fix in {resource}_count plugin_db APIs

        beb31bd   Ignore deleted network during port-list as it may have disappeared.

        939b1b4   Handling no-security-group on VMIs

        ab9f9ea   Disallow illegal xml chars and additonal restricted xml chars in name.

        f3ff9fd   Fix compilation error with new compiler

        6668618   Use libraries available in centos 7.0

        8a60923   Do not compile third-party libraries available on ubuntu

        d53efb5   Commit on behalf of pedro

        eea5cad   task_test is only needed for test targets

        bfee2ee   Call getpid() directly instead of using an internal API.

        bb62843   monotonic_deadline_timer replaces by steady_timer in boost 1.49

        8bfcacf   Use Cpp{Enable,Disable}Exceptions macro

        d05c68a   boost::asio::monotonic_deadline_timer replaced by steady_timer in boos

        083875d   Cleanup the packet pointer from packet node the moment we start using

        b017e15   Cache more than one packet in the flow hold queue (3 to be precise)

        e8a02ba   Fix a double free error in vr_message_process_response

        ffd40b9   Avoid repeatedly allocating StreamHandler for SandeshLogger

        657aab6   Merge "Filtered certain messages as debug message and printed only whe

        45c04e3   Use CppDisableExceptions macro

        08359bd   Filtered certain messages as debug message and printed only when vrout

        d54ed18   Closes-Bug:#1399831 - Add DNS Record

         
    Known Issues
        Activa-standby HA for MySQL might reduce the load and prolong HA failover recovery window.
        Nova request might take longer to execute due to the extra hops required when querying MySQL.
        When using Contrail for DNS, the network requires twi IPAMs in order to propagate FQN and domainnsme correctly. Such configuration will produce 2 duplicate IP address columns when runn 'nova list'.  This issue is under investigation. A workaround is found to allow a single IPAm association by forcing dhclient to restart and using the default hostname defined in /etc/sysconfig/network.
        Make sure to follow proper procedures to recover/start/stop MySQL PXC (Percona XtraDB Cluster)
        Single transformer worker caused CPU pegged at high concurrency.
        Dual IP addresses were assigned to a VM during boot under high concurrecy due to Nova to Neutron API call retry. 
        Nova list might exceed timeout set on Haproxy at high load when the tenant owns large number of VMs ( i.e. > 450)

    Suggested QA and CI Uptake Process

        Check in Gerrit and integrate with CI process.

        Leverage Jenkins and Bamboo for automatic builds.
    Installation Steps
        Update Contrail repo file as siggested
        Same command and syntext from previous releases. The patch is self sufficient without depending on previous releases. The patch can be re-applied multiple times if needed.
        Suggest to apply on the 3rd OpenStack controller first then move to the 3rd SDN controller after all OpenStack controllers have been patched and verified. Move to all compute nodes after SDN controllers are done.

Patch Release 1.21 - v6.1


This hot patch was released to fix a bug in check_nova_compute on looping and increasing timeout, to install Ceph required qemu pkgs after Contrail upgrade and to insert a cron job on all OpenStack controller nodes to force token flush once every 10 minutes. The patch package name has been changed to wpc-patches from original sdn-patches as suggested and agreed by WPC team. The new RPM wpc-patches-1.21-6.1-2015.02.18.x86_64.rpm has been potsed at the same repo location as the previous ones.

 

Following post-installation verification steps are recommended.

1) On all three OpenStack controller nodes, run "contab -l" to make sure one single entry keystone-manage has been inserted. Make sur ethis entry will not be overwritten by chef or others.

2) On all Compute nodes, run "rpm -qa| grep qemu" to make sure both qemu-img and qemu-kvm contain Ceph reuired rpms.

3) Make sure service check_nova_compute is up and no more than one check_nova_compute.py is ruuning. 

4) Users are able to access existing VMs and able to spwn off new ones.
