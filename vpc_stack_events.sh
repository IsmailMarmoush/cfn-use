#!/bin/bash
aws cloudformation describe-stack-events --stack-name mwest-${AWS_DEFAULT_PROFILE}-vpc
