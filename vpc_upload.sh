#!/bin/bash
aws s3 cp vpc.yaml s3://${S3BUCKET}/cloudformation/vpc.yaml --sse AES256
