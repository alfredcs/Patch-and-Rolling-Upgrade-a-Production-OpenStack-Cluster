#!/usr/bin/env python
import sys,time,os,commands,signal,json,re,socket,getopt,ConfigParser,httplib,logging
from urllib import urlencode
from contextlib import contextmanager
STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
STATE_UNKNOWN = 3
DELAY=1
logging.basicConfig(filename="/var/log/nova/check_nova_compute.log", level=logging.WARNING, format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')
logger = logging.getLogger(__name__)

class TimeoutException(Exception): pass
@contextmanager
def time_limit(seconds):
    def signal_handler(signum, frame):
        raise TimeoutException, "Timed out!"
    signal.signal(signal.SIGALRM, signal_handler)
    signal.alarm(seconds)
    try:
        yield
    finally:
        signal.alarm(0)

class check_nova_compute(object):

  def __init__(self, args_str=None):
	conf_file=""
	(opts, args) = getopt.getopt(sys.argv[1:], "f:hv", ["nova API config file", "help", "verbose"])
	for o, a in opts:
  	  if o in ["-h", "--help"]:
            self.usage()
  	  elif o in ["-f", "--file"]:
            conf_file=a
  	  elif o in ["-v", "--verbose"]:
            verbose=1
	global DELAY,STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
	default_nova_password="None"
	default_nova_user="nova"
	default_nova_tenant_name="service"
	default_keystone_auth_url=""
	default_insecure="False"
	default_osapi_compute_listen_port="8774"
  	retries=0
	time_out=16
	cfg_parser_nova = ConfigParser.ConfigParser()
	clen_nova = len(cfg_parser_nova.read(conf_file or  "/etc/nova/nova.conf"))
	nova_user=self._read_cfg(cfg_parser_nova, 'keystone_authtoken', 'admin_user', default_nova_user)
	nova_password=self._read_cfg(cfg_parser_nova, 'keystone_authtoken', 'admin_password', default_nova_password)
	nova_tenant_name=self._read_cfg(cfg_parser_nova, 'DEFAULT', 'admin_tenant_name', default_nova_tenant_name)
	bool_insecure=self._read_cfg(cfg_parser_nova, 'DEFAULT', 'neutron_api_insecure', default_insecure)
	osapi_compute_listen_port=self._read_cfg(cfg_parser_nova, 'DEFAULT', 'osapi_compute_listen_port', default_osapi_compute_listen_port)
	keystone_auth_url=self._read_cfg(cfg_parser_nova, 'DEFAULT', 'neutron_admin_auth_url', default_keystone_auth_url)
	local_hostname=socket.gethostname()

	#import pdb;pdb.set_trace()
	# Retries=3
  	for i in range(0,3):
    	  while True:
      	    try:
		# Set 50 seconds as the connection limit
        	with time_limit(50):
          	  if self._check_hypervisor_uptime(nova_user, nova_password, nova_tenant_name, keystone_auth_url, local_hostname, bool_insecure, time_out, osapi_compute_listen_port):
                	retries = 0
          	  else:
                	retries += 1
		  time.sleep(2)
      	    except TimeoutException, msg:
          	logger.warning("Openstack-nova-compute status check timed out %s!" % i)
          	retries += 1
          	#continue
      	    break

	if retries > 2 :
   	  logger.info("Retried %s times! Restart openstack-nova-compute" % retries)
   	  status,start_msg = commands.getstatusoutput('service openstack-nova-compute restart')
	  logger.warning(start_msg)
	else :
	  logger.info("Checked openstack-nova-compute OK!")
	  if verbose == 1 :
	    logger.warning("Checked openstack-nova-compute OK!")

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

  def _get_keystone_token(self, nova_user, nova_password, nova_tenant_name, keystone_auth_url, bool_insecure):
	from keystoneclient.v2_0 import client
	from keystoneclient import exceptions
	token_id=[]
	global STATE_OK,STATE_WARNING,STATE_CRITICAL,STATE_UNKNOWN
	try:
    		c_keystone = client.Client(username=nova_user, tenant_name=nova_tenant_name, password=nova_password, 
                  	auth_url=keystone_auth_url, insecure=bool_insecure)
    		if not c_keystone.authenticate():
        		raise Exception("Authentication failed")
	except Exception as e:
    		print str(e)
    		sys.exit(STATE_CRITICAL)
	token_id.append(c_keystone.auth_token)
	token_id.append(c_keystone.tenant_id)

	return token_id

  def _check_hypervisor_uptime(self, nova_user, nova_password, nova_tenant_name, keystone_auth_url, local_hostname, bool_insecure, time_out,osapi_compute_listen_port):
	from novaclient.v1_1 import client
	mt=client.Client(nova_user, nova_password, nova_tenant_name, auth_url=keystone_auth_url, insecure=bool_insecure, timeout=time_out)
	hypervisor_id=mt.hypervisors.search(local_hostname, servers=False)
	auth_token_id_nova=self._get_keystone_token(nova_user, nova_password, nova_tenant_name, keystone_auth_url, bool_insecure)
	headers = { "X-Auth-Project-Id": nova_tenant_name, "Content-Type": "application/json", "X-Auth-Token": auth_token_id_nova[0] }
	params=urlencode({})
	auth_host=keystone_auth_url.split(':', 2)[1].replace('//', '')
	if bool_insecure:
		conn = httplib.HTTPSConnection(host=auth_host, port=osapi_compute_listen_port, timeout=time_out)
	else:
		conn = httplib.HTTPConnection(host=auth_host, port=osapi_compute_listen_port, timeout=time_out)
	action_str="/v2/"+auth_token_id_nova[1]+"/os-hypervisors/"+str(hypervisor_id).strip('[]<>').split(':')[1].lstrip()+"/uptime"
	conn.request("GET", action_str, params, headers)
    	response = conn.getresponse()
	#if mt.hypervisors.uptime(hypervisor_id[0]):
	if "uptime" in response.read():
		return True
	else:
		return False

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
	#fpid = os.fork()
	#if fpid!=0:
  	#	# Running as daemon now. PID is fpid
  	#	sys.exit(0)
	#while True:
	#	check_nova_compute(args_str) 
	#	time.sleep(30)
	check_nova_compute(args_str) 

if __name__ == "__main__":
  	main()
