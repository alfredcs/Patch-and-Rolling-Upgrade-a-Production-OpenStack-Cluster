#!/usr/bin/env python
import sys,time,os,json,re,socket,getopt
import ConfigParser
import httplib
from urllib import urlencode
STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
STATE_UNKNOWN = 3
DELAY=1

class check_ifmap(object):

  def __init__(self, args_str=None):
	(opts, args) = getopt.getopt(sys.argv[1:], "f:hv", ["Contrail API config file", "help", "verbose"])
	for o, a in opts:
  	  if o in ["-h", "--help"]:
            self.usage()
  	  elif o in ["-f", "--file"]:
            conf_file=a
  	  elif o in ["-v", "--verbose"]:
            verbose=1
	global DELAY,STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
	default_region_name="regionOne"
	default_token="None"
	default_neutron_listen_port="9696"
	default_contrail_listen_port="8082"
	default_cassandra_listen_port="9160"
	default_ifmap_listen_port="8083"
	default_admin_password="None"
	default_admin_user="admin"
	default_admin_tenant_name="admin"
	default_auth_host="127.0.0.1"
	default_auth_port="35357"
	default_auth_protocol="http"
	default_insecure="False"
	auth_token_neutron=""
	conf_file="/etc/contrail/contrail-api.conf"
	verbose=0
	del_network_name="delMeXX"
	cfg_parser_contrail = ConfigParser.ConfigParser()
	clen_contrail = len(cfg_parser_contrail.read(conf_file))
	auth_port=self._read_cfg(cfg_parser_contrail, 'KEYSTONE', 'auth_port', default_auth_port)
	auth_protocol=self._read_cfg(cfg_parser_contrail, 'KEYSTONE', 'auth_protocol', default_auth_protocol)
	auth_host=self._read_cfg(cfg_parser_contrail, 'KEYSTONE', 'auth_host', default_auth_host)
	admin_user=self._read_cfg(cfg_parser_contrail, 'KEYSTONE', 'admin_user', default_admin_user)
	admin_password=self._read_cfg(cfg_parser_contrail, 'KEYSTONE', 'admin_password', default_admin_password)
	admin_tenant_name=self._read_cfg(cfg_parser_contrail, 'KEYSTONE', 'admin_tenant_name', default_admin_tenant_name)
	insecure=self._read_cfg(cfg_parser_contrail, 'KEYSTONE', 'insecure', default_insecure)
	neutron_listen_port=self._read_cfg(cfg_parser_contrail, 'DEFAULT', 'neutron_listen_port', default_neutron_listen_port)
	contrail_listen_port=self._read_cfg(cfg_parser_contrail, 'DEFAULT', 'contrail_listen_port', default_contrail_listen_port)
	cassandra_listen_port=self._read_cfg(cfg_parser_contrail, 'DEFAULT', 'cassandra_listen_port', default_cassandra_listen_port)
	ifmap_listen_port=self._read_cfg(cfg_parser_contrail, 'DEFAULT', 'ifmap_listen_port', default_ifmap_listen_port)
	region_name=self._read_cfg(cfg_parser_contrail, 'DEFAULT', 'region', default_region_name)
	local_hostname=socket.gethostname()

	#import pdb;pdb.set_trace()
	try:
	  auth_token_id=self._get_keystone_token(admin_user, admin_tenant_name, admin_password, auth_protocol, auth_host, auth_port, insecure, region_name)
	  # Clean any exisiting dummy network (s)
	  for neutron_respond_clean in self._query_network(auth_token_id[1], auth_token_id[0], local_hostname, del_network_name, neutron_listen_port):
	  	self._delete_dummy_network(auth_token_id[1], auth_token_id[0], neutron_respond_clean, local_hostname, contrail_listen_port)
	  # Create a new dummy network
	  neutron_respond=self._create_dummy_network(auth_token_id[1], auth_token_id[0], local_hostname, del_network_name, neutron_listen_port)
	  if self._check_cassandra("default-domain:"+admin_tenant_name+":"+del_network_name+":"+neutron_respond, local_hostname, cassandra_listen_port) < 1:
                raise Exception("Contrail API and Cassandra mismatch found at VN addition!")
	  time.sleep(DELAY)
	  ifmap_count_add=self._check_ifmap_count(auth_token_id[1], auth_token_id[0], local_hostname, del_network_name, ifmap_listen_port)
	  if ifmap_count_add < 1:
                raise Exception("IFMAP mismatch found at VN addition! Should be >=1 entries but shown %d." % ifmap_count_add)
	  time.sleep(DELAY)
	  controller_count=self._check_controllerRouteTable_count(auth_token_id[1], auth_token_id[0], local_hostname, del_network_name, ifmap_listen_port)
          if  controller_count < 1:
                raise Exception("Controller route table mismatch found at VN addition! Should be >=1 but showed %s." % controller_count)
	  self._delete_dummy_network(auth_token_id[1], auth_token_id[0], neutron_respond, local_hostname, contrail_listen_port)
	  cass_count=self._check_cassandra("default-domain:"+admin_tenant_name+":"+del_network_name+":"+neutron_respond, local_hostname, cassandra_listen_port)
          if cass_count > 0:
                raise Exception("Contrail API and Cassandra mismatch found at VN delete! Should be 0 but shown %s" % cass_count)
	  time.sleep(DELAY)
	  ifmap_count_del=self._check_ifmap_count(auth_token_id[1], auth_token_id[0], local_hostname, del_network_name, ifmap_listen_port)
	  if  ifmap_count_del > 1:
		raise Exception("IFMAP mismatch found after VN deletion! Should less than 1  entries but shown %d." % ifmap_count_del )
	  time.sleep(DELAY)
	  if self._check_controllerRouteTable_count(auth_token_id[1], auth_token_id[0], local_hostname, del_network_name, ifmap_listen_port) > 3:
		raise Exception("Controller route table mismatch found after VN deletion!")
	  else:
        	print "HTTP/1.1 200 OK"
        	print "Content-Type: Content-Type: text/plain"
        	if verbose > 0:
                  print
        	print
        	print "IFMAP/Cassandra consistency checked OK!"
        	sys.exit(STATE_OK)
	except Exception as e:
    		print "HTTP/1.1 503 Check IFMAP/Cassandra consistency failed. Please retry!"
    		print "Content-Type: Content-Type: text/plain"
    		print
    		print str(e)
    		sys.exit(STATE_CRITICAL)

  #end __init__


  def _read_cfg(self, cfg_parser, section, option, default):
        try:
            val = cfg_parser.get(section, option)
        except (AttributeError,
                ConfigParser.NoOptionError,
                ConfigParser.NoSectionError):
            val = default

        return val
  #end _read_cfg

  def _get_keystone_token(self, admin_user, admin_tenant_name, admin_password, auth_protocol, auth_host, auth_port, insecure, region_name):
	from keystoneclient.v2_0 import client
	from keystoneclient import exceptions
	token_id=[]
	global STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
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

  def _create_dummy_network(self,admin_tenant_name, auth_token, local_hostname, del_network_name, neutron_listen_port):
	global STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
	headers = {"X-Auth-Project-Id": admin_tenant_name, "Content-Type": "application/json", "X-Auth-Token": auth_token }
	params={"network":{"name":del_network_name,"admin_state_up":True}}
	conn_neutron = httplib.HTTPSConnection(host=local_hostname, port=neutron_listen_port, timeout=50)
	action_str="/v2.0/networks"
	try:
      	  conn_neutron.request("POST", action_str, json.dumps(params), headers)
      	  response_neutron = conn_neutron.getresponse().read()
	except Exception as e:
          print "HTTP/1.1 503 Create new network via Neutron API failed."
          print "Content-Type: Content-Type: text/plain"
          print
          print str(e)
          sys.exit(STATE_CRITICAL)
	return json.loads(response_neutron)['network']['id']

  def _query_network(self,admin_tenant_name, auth_token, local_hostname, del_network_name, neutron_listen_port):
	global STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
        headers = {"X-Auth-Project-Id": admin_tenant_name, "Content-Type": "application/json", "X-Auth-Token": auth_token }
        params=urlencode({})
	dummy_network_ids=[]
        conn_neutron = httplib.HTTPSConnection(host=local_hostname, port=neutron_listen_port, timeout=50)
        action_str="/v2.0/networks"
        try:
          conn_neutron.request("GET", action_str, params, headers)
          response_neutron = json.loads(conn_neutron.getresponse().read())
        except Exception as e:
          print "HTTP/1.1 503 Create new network via Neutron API failed."
          print "Content-Type: Content-Type: text/plain"
          print
          print str(e)
          sys.exit(STATE_CRITICAL)
	for i in range(0, len(response_neutron['networks'])):
	  if self._exact_string_match(response_neutron['networks'][i]['name'], del_network_name):
		dummy_network_ids.append(response_neutron['networks'][i]['id'])  
        return dummy_network_ids

  def _check_ifmap_count(self, admin_tenant_name, auth_token, local_hostname, del_network_name, ifmap_listen_port):
	global STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
	headers = {"X-Auth-Project-Id": admin_tenant_name, "Content-Type": "application/json", "X-Auth-Token": auth_token }
	conn_ifmap = httplib.HTTPConnection(host=local_hostname, port=ifmap_listen_port, timeout=50)
	params=urlencode({})
	action_str="/Snh_IFMapTableShowReq?table_name="
	try:
      	  conn_ifmap.request("GET", action_str, params, headers)
	  ifmap_count=conn_ifmap.getresponse().read().count(del_network_name)
	except Exception as e:
          print "HTTP/1.1 503 Querry IFMAP introspect failed."
          print "Content-Type: Content-Type: text/plain"
          print
          print str(e)
          sys.exit(STATE_CRITICAL)
	return ifmap_count

  def _check_controllerRouteTable_count(self, admin_tenant_name, auth_token, local_hostname, del_network_name, ifmap_listen_port):
        global STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
        headers = {"X-Auth-Project-Id": admin_tenant_name, "Content-Type": "application/json", "X-Auth-Token": auth_token }
        conn_ifmap = httplib.HTTPConnection(host=local_hostname, port=ifmap_listen_port, timeout=50)
        params=urlencode({})
        action_str="/Snh_ShowRoutingInstanceReq?name="
        try:
          conn_ifmap.request("GET", action_str, params, headers)
	  controller_count=conn_ifmap.getresponse().read().count(del_network_name)
        except Exception as e:
          print "HTTP/1.1 503 Querry Controller Route Table introspect failed."
          print "Content-Type: Content-Type: text/plain"
          print
          print str(e)
          sys.exit(STATE_CRITICAL)
        return controller_count

  def _check_cassandra(self, del_network_keyname, local_hostname, cassandra_listen_port):
	from pycassa.pool import ConnectionPool
	from pycassa.columnfamily import ColumnFamily

	pool1=ConnectionPool('config_db_uuid', [local_hostname+":"+cassandra_listen_port])
	col_fam=ColumnFamily(pool1, 'obj_fq_name_table')
        return col_fam.get_count('virtual_network', columns=[del_network_keyname])

  def _delete_dummy_network(self, admin_tenant_name, auth_token, dummy_network_id, local_hostname, contrail_listen_port):
	global STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
	headers = {"Content-Type": "application/json", "X-Auth-Token": auth_token }
	conn_contrail = httplib.HTTPSConnection(host=local_hostname, port=contrail_listen_port, timeout=50)
	params=urlencode({})
	action_str_del="/virtual-network/"+dummy_network_id
	try:
          conn_contrail.request("DELETE", action_str_del, json.dumps(params), headers)
          response_contrail = conn_contrail.getresponse().read()
	except Exception as e:
          print "HTTP/1.1 503 Delete network via Neutron API failed."
          print "Content-Type: Content-Type: text/plain"
          print
          print str(e)
          sys.exit(STATE_CRITICAL)

  def usage(self, message=None):
  	print "Usage: %s [-h|v] [-f|--file <config_file>]" % (sys.argv[0])
  	print "-h|--help: show this message"
  	print "-v|--verbose: include details in output"
  	print "-f|--file: dir and filename of the contrail api config file"
  	sys.exit(-1)

  def _exact_string_match(self, phrase, word):
	b = r'(\s|^|$)' 
	res = re.match(b + word + b, phrase, flags=re.IGNORECASE)
	return bool(res)


def main(args_str=None):
    check_ifmap(args_str)

if __name__ == "__main__":
    main()
