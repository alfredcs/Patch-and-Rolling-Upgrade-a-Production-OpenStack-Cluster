#!/usr/bin/env python
import time,os,subprocess

while True:
	with open(os.devnull, 'wb') as devnull:
    		#subprocess.check_call(['/usr/local/bin/check_nova_compute.py', '-v'], stdout=devnull, stderr=subprocess.STDOUT)
		os.system('/usr/local/bin/check_nova_compute.py -v')
		time.sleep(60)
