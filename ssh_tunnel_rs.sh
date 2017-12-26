#!/bin/sh 
ssh -f ec2-user@52.88.96.45 \
	-i ~/.ssh/mwest-default.pem \
	-L localhost:5439:mwest-default-rs-redshift-1q4z2i49ttj0z.clnkwyz5uf9g.us-west-2.redshift.amazonaws.com:5439 \
	-o "ExitOnForwardFailure yes" -o "ServerAliveInterval 60" \
	-N