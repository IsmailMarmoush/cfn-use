#!/bin/sh

# connect to redshift thorugh ssh tunnel
# psql --dbname=test --port=5439 --password --username=billybob

# use password from .pgpass
psql --dbname=test --port=5439 --username=billybob
