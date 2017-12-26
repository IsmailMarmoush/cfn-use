#!/bin/bash
set -u
set -e
aws cloudformation validate-template --template-body file:///Users/mike/Documents/code/cloudformation/$1
