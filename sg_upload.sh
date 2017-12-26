#!/bin/bash
aws s3 cp sg.yaml s3://${S3BUCKET}/cloudformation/sg.yaml  --sse AES256
