#!/bin/bash
aws s3 cp ec2.yaml s3://${S3BUCKET}/cloudformation/ec2.yaml --sse AES256
