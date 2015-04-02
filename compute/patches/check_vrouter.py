#!/usr/bin/env python
import sys,os,getopt,re
import ConfigParser
import httplib
from urllib import urlencode
from xml.dom import minidom

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
STATE_UNKNOWN = 3
verbose=0
default_listen_ip_addr="127.0.0.1"
default_listen_port="8085"
default_auth_protocol="http"
vrouter_conf_file="/etc/contrail/contrail-vrouter-agent.conf"

def _read_cfg(cfg_parser, section, option, default):
        try:
            val = cfg_parser.get(section, option)
        except (AttributeError,
                ConfigParser.NoOptionError,
                ConfigParser.NoSectionError):
            val = default

        return val
#end _read_cfg

def _get_keystone_token(admin_user, admin_tenant_name, admin_password, auth_protocol, auth_host, auth_port, insecure, region_name):
	from keystoneclient.v2_0 import client
	from keystoneclient import exceptions
	token_id=[]
	try:
    		c_keystone = client.Client(username=admin_user, tenant_name=admin_tenant_name, password=admin_password, 
                  	auth_url=auth_protocol+"://"+auth_host+":"+auth_port+"/v2.0", insecure=insecure, region_name=region_name)
    		if not c_keystone.authenticate():
        		raise Exception("Authentication failed")
	except Exception as e:
    		print str(e)
    		sys.exit(STATE_CRITICAL)
	token_id.append(c_keystone.auth_token)
	token_id.append(c_keystone.tenant_id)

	return token_id

def usage(message=None):
  print "Usage: %s [-h] [-f|--file <config_file>]" % (sys.argv[0])
  print "-h|--help: show this message"
  print "-v|--verbose: include details in output"
  print "-f|--file: dir and filename of the contrail collector config file"
  sys.exit(-1)

# end of _get_keystone_token

def getNodeText(node):
    nodelist = node.childNodes
    result = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            result.append(node.data)
    return ''.join(result)



# --- main()a ---

(opts, args) = getopt.getopt(sys.argv[1:], "f:hv", ["Vrouter agent config file", "help", "verbose"]) 

for o, a in opts:
  if o in ["-h", "--help"]:
	usage()
  elif o in ["-f", "--file"]:
	vrouter_conf_file=a
  elif o in ["-v", "--verbose"]:
        verbose=1

#import pdb;pdb.set_trace()
cfg_parser_contrail = ConfigParser.ConfigParser()
clen_contrail = len(cfg_parser_contrail.read(vrouter_conf_file))
listen_port=_read_cfg(cfg_parser_contrail, 'DEFAULT', 'http_server_port', default_listen_port)
listen_ip_addr=_read_cfg(cfg_parser_contrail, 'DEFAULT', 'listen_ip_addr', default_listen_ip_addr)

headers = { "Content-Type": "application/json" }
params=urlencode({})
conn = httplib.HTTPConnection(listen_ip_addr, port=listen_port, timeout=2)

try:
    action_str="/Snh_SandeshUVECacheReq?x=NodeStatus"
    conn.request("GET", action_str, params, headers)
    response = conn.getresponse().read()
    if not response:
        raise Exception("Query Vrouter agent failed. No response")
    elif '503' in response.lower() or re.search('unavailable', response, re.IGNORECASE):
	raise Exception("Query Vrouter agent service failed. Service unavailable")
    else:
	print "HTTP/1.1 200 OK"
	print "Content-Type: Content-Type: text/plain"
	if (verbose > 0 ):
		doc = minidom.parseString(response)
		staffs = doc.getElementsByTagName("ConnectionInfo")
		for staff in staffs:
        		typee = staff.getElementsByTagName("type")[0]
        		direct = staff.getElementsByTagName("name")[0]
        		nickname = staff.getElementsByTagName("element")[0]
        		status = staff.getElementsByTagName("status")[0]
        		print("     Service:%s, Dependency: %s, Element:%s, Status: %s" %
              			(getNodeText(typee), getNodeText(direct), getNodeText(nickname), getNodeText(status)))
	print
	print "Vrouter agent checked!"
    	sys.exit(STATE_OK)
except Exception as e:
    print "HTTP/1.1 503 Service Unavailable"
    print "Content-Type: Content-Type: text/plain"
    print
    print "<html><body><h1>503 Vrouter Agent Unavailable</h1></body></html>"
    print str(e)
    print "Vrouter agent check failed!"
    sys.exit(STATE_CRITICAL)
