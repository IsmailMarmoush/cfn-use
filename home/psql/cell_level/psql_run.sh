#!/bin/bash
# sample connection script
# can I install a .pgpass at ec2 initilization?
# consider grabbing the hostname from exports to create this script from template
/usr/bin/psql --dbname=test --port=5439 --username=billybob \
 --host=r619185-lab-rs-redshift-aycq2lrvs5md.cp2b6xqxwhiv.us-west-2.redshift.amazonaws.com \
 -f $1
