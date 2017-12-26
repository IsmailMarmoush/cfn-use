#!/bin/bash
aws s3 cp role.yaml s3://${S3BUCKET}/cloudformation/role.yaml --sse AES256
