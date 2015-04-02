#!/usr/bin/python
import getopt, sys,MySQLdb,logging,ConfigParser
from contextlib import contextmanager

default_nova_user="nova"
default_nova_password="password"
default_connection=""
nova_conf_file=""
verbose=0

logging.basicConfig(filename="/var/log/nova/check_mysql.log", level=logging.WARNING, format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')
logger = logging.getLogger(__name__)

def usage(message=None):
  print "Usage: %s [-h] [-f|--file <config_file>]" % (sys.argv[0])
  print "-h|--help: show this message"
  print "-v|--verbose: include details in output"
  print "-f|--file: dir and filename of the neutron config file"
  sys.exit(-1)

def _read_cfg(cfg_parser, section, option, default):
      try:
          val = cfg_parser.get(section, option)
      except (AttributeError,
              ConfigParser.NoOptionError,
              ConfigParser.NoSectionError):
          val = default

      return val
#end _read_cfg

(opts, args) = getopt.getopt(sys.argv[1:], "f:hv", ["Nova config file", "help", "verbose"])
for o, a in opts:
  if o in ["-h", "--help"]:
        usage()
  elif o in ["-f", "--file"]:
        nova_conf_file=a
  elif o in ["-v", "--verbose"]:
        verbose=1

cfg_parser_nova = ConfigParser.ConfigParser()
clen_nova = len(cfg_parser_nova.read(nova_conf_file or  "/etc/nova/nova.conf"))
sql_connection=_read_cfg(cfg_parser_nova, 'database', 'connection', default_connection)

nova_user=sql_connection.split(":")[1].replace("//", "")
nova_password=sql_connection.split(":")[2].split('@')[0]
try:
    db = MySQLdb.connect(host="127.0.0.1", user=nova_user, passwd=nova_password, db="nova")
    cursor = db.cursor() 
    #cursor.execute("SELECT VERSION()")
    cursor.execute("SHOW STATUS LIKE 'wsrep_local_state'")
    results = cursor.fetchone()
    # Check if anything at all is returned
    if results[1] == "4" :
	print "HTTP/1.1 200 OK"
	print "Content-Type: Content-Type: text/plain"
	if verbose == 1 :
		print
		print "Local MySql Status: %s=%s" % (results[0], results[1])
	print
	print "MySql is available!"
    else:
	print "HTTP/1.1 503 MySql Service Unavailable"
        print "Content-Type: Content-Type: text/plain"
        print
        print "MySql is unavailable!"
	logger.warning("HTTP/1.1 503 MySql Service Unavailable")

except MySQLdb.Error, e:
    print "HTTP/1.1 404 MySql connection Unavailable"
    print "Content-Type: Content-Type: text/plain"
    print
    logger.warning(str(e))
    sys.exit(1)
