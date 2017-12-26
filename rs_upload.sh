#!/bin/bash
aws s3 cp rs.yaml s3://${S3BUCKET}/cloudformation/rs.yaml --sse AES256
