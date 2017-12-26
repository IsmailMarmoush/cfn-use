#!/bin/bash
# sample connection script
# can I install a .pgpass at ec2 initilization?
# consider grabbing the hostname from exports to create this script from template
/usr/bin/psql --dbname=test --port=5439 --username=billybob \
 --host=get export from rs.yaml cloudformation \
 -f $1
