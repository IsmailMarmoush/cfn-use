#!/bin/bash

##########
#
# ssh tunnel to connect my desktop to redshift
# assumes IdentifyFile and user in ssh config file for this host
#
# -f
#   ssh in background
#   do not accept input from STDIN
#
# -l bastion host user
#
# -L
#   port forwarding
#
# localhost:
#   only allow connection from my desktop
#   not creating a tunnel for everyone
#   see GatewayPorts ssh configuration option
#
# 5439:
#   listen on local port 5439
#
# redshift url:redshift port
#
# -o "ExitOnForwardFailure yes"
#   wait for forwarding to be established and error if it fails
#
# -o "ServerAliveInterval 60"
#   send null ever 60 seconds to keep connection alive
#
# -i /path/to/private/key/for/bastion.pem
#
# -N
#   do not execute remote commands
#
# Created by: Michael West
# Date: 2016-Jan-15
#
##########

ssh -f 34.216.210.81 \
    -l ec2-user \
    -L localhost:5439:mwest-default-rs-redshift-eflihtyyacto.clnkwyz5uf9g.us-west-2.redshift.amazonaws.com:5439 \
    -o "ExitOnForwardFailure yes" \
    -o "ServerAliveInterval 60" \
    -i ~/.ssh/mwest-default.pem \
    -N
