#!/bin/bash
aws s3 cp ar.yaml s3://${S3BUCKET}/cloudformation/ar.yaml --sse AES256
