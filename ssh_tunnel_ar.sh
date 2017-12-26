#!/bin/sh 
ssh -f ec2-user@52.88.96.45 \
	-i ~/.ssh/mwest-default.pem \
	-L localhost:3306:mwest-default-ar-auroracluster-pnca1fte3h07.cluster-cbhoquc0oni1.us-west-2.rds.amazonaws.com:3306 \
	-o "ExitOnForwardFailure yes" -o "ServerAliveInterval 60" \
	-N