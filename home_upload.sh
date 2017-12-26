#!/bin/bash

cd ./home
tar -zcf ../home.tar.gz .
cd -

aws s3 cp home.tar.gz s3://${S3BUCKET}/cloudformation/home.tar.gz --sse AES256
