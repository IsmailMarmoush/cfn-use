#!/usr/bin/env python
'''create shell script to login to bastion host

TODO:
    functions are duplicated in ssh_tunnel_redshift_create_script.py
    create a library/module of cfn outputs and exports

Example:
    call as script with optional -v argument
    -v will enable debug mode for verbose output
    -vv will enable very verbose output

      $ python ssh_ec2_create_script.py [-vv]

'''
import os
import sys
import boto3
import logging
import argparse
import platform


# plan to convert this to an object later
# these will be properties / construtor items
# uses cfn exports instead now
# has functions to support either way
EC2_IDENTIFIER = 'i-98d90b45'
cfn_client = boto3.client('cloudformation')
cloudformation = boto3.resource('cloudformation')
response = cfn_client.list_exports()

# use dict comprehention to extract out key, values from cloudformation exports
exports = { x['Name']: x['Value'] for x in response['Exports'] }

prefix = '{0}-{1}'.format(os.environ['OWNER'], os.environ['AWS_DEFAULT_PROFILE'])


def get_ec2_public_ip_from_cfn_export():
    ''' Get public ip of bastion host

         Returns (String) - public IP
    '''
    log.debug('START get_ec2_public_ip_from_cfn_export')
    stack = cloudformation.Stack('{0}-ec2'.format(prefix))
    outputs = { x['OutputKey']: x['OutputValue'] for x in stack.outputs }
    log.debug('END get_ec2_public_ip_from_cfn_export')
    return outputs['PublicIP']


def get_ec2_public_ip_from_identifier():
    ''' Get ec2 instance public ip from identifier

         Returns (String) - public IP
    '''
    log.debug('START get_ec2_public_ip_from_identifier')

    ec2_instance = boto3.resource('ec2').Instance(EC2_IDENTIFIER)

    log.debug('END get_ec2_public_ip_from_identifier')
    return ec2_instance.public_ip_address


def main():
    '''entry function runs when script is executed.'''
    log = logging.getLogger(__file__)
    log.info('python version is: {0}'.format(platform.python_version()))

    # parse command line arguments
    parser = argparse.ArgumentParser(description='python template does nothing')
    # count the number of verbose options
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='increase output detail')

    args = parser.parse_args()
    # set loglevel to DEBUG if verbose
    if args.verbose >= 2:
        log.info('setting loglevel to DEBUG globally')
        logging.getLogger().setLevel(logging.DEBUG)
    elif args.verbose == 1:
        log.info('setting loglevel to DEBUG locally')
        logging.getLogger(__file__).setLevel(logging.DEBUG)

    log.debug('system version is: {0}'.format(sys.version))
    log.debug('python path is: {0}'.format(sys.path))

    # create ssh tunnel shell script
    with open('ssh_ec2.sh', 'w') as f:
        f.writelines(['#!/bin/sh \n',
                      'ssh ec2-user@{0} \\\n'.format(get_ec2_public_ip_from_cfn_export()),
                      '\t-i ~/.ssh/{0}.pem \n'.format(prefix)
                      ])

    # python 3 0o775
    # python 2 0775
    os.chmod('ssh_ec2.sh', 0o775)


if __name__ == '__main__':
    try:
        logging.basicConfig(format='%(asctime)s %(message)s',
                            level=logging.INFO)
        log = logging.getLogger(__file__)
        main()
    except Exception:
        log.exception('FAILED: script {0})'.format(__file__))
        raise
