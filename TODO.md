## next steps to make cfn more useful at home

* add s3 bucket creation with role only access
* pass snapshot names as a parameters for all databases
  - hint, use mustache templates for config files in etc/
* create aurora for postgres as well as mysql
* remove cruft like these after restore from snapshot from config is confirmed working
** rs_create_stack_from_snapshot.py
** mysql_create_stack_from_snapshot.py

