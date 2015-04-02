#!/bin/bash
set -x
[[ `id -u` -ne 0 ]] && { echo  "Must be root!"; exit 0; }
REDIS_PORT=6379
LO="127.0.0.1"
#####################################################################################################
# Redis iptables stop gap fix till https://bugs.launchpad.net/juniperopenstack/+bug/1392113 is fixed
#####################################################################################################
if [[ -f /etc/redis.conf ]]; then
     # Accept from local
     sudo iptables -A INPUT -p tcp --dport $REDIS_PORT -s $LO -j ACCEPT
     grep  contrail-api- /etc/haproxy/haproxy.cfg | awk '{print $3}'| cut -d: -f1 | while read aa
            do
                  sudo iptables -A INPUT -p tcp --dport $REDIS_PORT -s $aa -j ACCEPT
            done

# Drop from any other IP
sudo iptables -A INPUT -p tcp --dport $REDIS_PORT -j DROP
# Save the iptable rules 
sudo service iptables save
fi

