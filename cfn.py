#!/usr/bin/env python
'''cfn.py

manage cloudformation stacks

Example:
    $ cfn.py [-vvv] [-c|-u|-d] -t type

    --create  create stack
    --update  update stack
    --delete  delete stack

    --type_of_stack  type of stack
        * vpc
        * sg - security group
        * role
        * ar - aurora
        * rs - redshift
        * mysql
        * ec2

    call with optional -v argument
    -v will enable debug mode for this script
    -vv will enable debug mode for this script and cfn_manage namespace
    -vvv will enable debug output from everywhere

    TODO:
        * pass stack name parameter

'''
from __future__ import absolute_import, division, print_function, unicode_literals

import os
import sys
import yaml
import boto3
import logging
import argparse
import platform
import pystache
from os.path import expanduser, abspath, dirname, isfile, join
# cfn_manage comes from my github project
# https://github.com/quagly/cfn-manage
from cfn_manage.cloudformation import CfnStack


def validate_env_vars(expected):
    '''validate required enviornment variables exist
    currently only tests for existance of variables

    Args:
        expected (list): list of required enviornment variables

    Returns:
        List of missing environment variables
    '''
    log = logging.getLogger(__file__)
    log.debug('BEGIN validate_env_vars')
    missing = []

    for envvar in expected:
        if envvar not in os.environ:
            missing.append(envvar)

    log.debug('END validate_env_vars')
    return missing


def read_config(config_file, **kwargs):
    '''read config file {stack_type}_cfg.yaml from directory config_dir

    Args:
        config_file (String):  absolute path to configuration file to read
        **kwargs:  additional parameters to substitue in config file template

    Returns:
        dict of config
    '''
    log = logging.getLogger(__file__)
    log.debug('BEGIN read_config')
    log.info('configuration file is: {0}'.format(config_file))
    # note that pystache can use search paths to find templates
    # is that better than passing in the absolute path to the template file?
    renderer = pystache.Renderer()
    yaml_string = renderer.render_path(config_file, kwargs)
    log.debug('post mustache template process yaml is: {0}'.format(yaml_string))
    config = yaml.safe_load(yaml_string)
    log.debug('END read_config')
    return config


def main():
    """entry function runs when script is executed."""
    log = logging.getLogger(__file__)
    log.info('python version is: {0}'.format(platform.python_version()))

    # parse command line arguments
    parser = argparse.ArgumentParser(
        description='manage vpc cfn stack',
        epilog='one and only one of --create, --delete, --update required'
    )
    # count the number of verbose options
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='increase output detail')

    parser.add_argument('-t', '--type_of_stack', required=True, help='REQUIRED: type of stack to create, for example vpc')

    # one of create, update, delete,  is required
    # groups do not support custom help
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-c', '--create', action='store_true')
    group.add_argument('-d', '--delete', action='store_true')
    group.add_argument('-u', '--update', action='store_true')

    args = parser.parse_args()

    # set loglevel to DEBUG if verbose
    if args.verbose >= 3:
        log.info('setting loglevel to DEBUG globally')
        logging.getLogger().setLevel(logging.DEBUG)
    elif args.verbose == 2:
        # set cfn_manage namespace to debug
        # haven't tested this since I change the namespace name
        # maybe should be cloudformation?
        logging.getLogger('cfn_manage').setLevel(logging.DEBUG)
        logging.getLogger(__file__).setLevel(logging.DEBUG)
    elif args.verbose == 1:
        log.info('setting loglevel to DEBUG locally')
        logging.getLogger(__file__).setLevel(logging.DEBUG)

    log.debug('system version is: {0}'.format(sys.version))
    log.debug('python path is: {0}'.format(sys.path))
    log.debug("boto3 version is: {0}".format(boto3.__version__))

    missing = validate_env_vars(['S3BUCKET', 'AWS_DEFAULT_PROFILE', 'OWNER', 'PRODUCT'])
    if missing:
        raise ValueError('missing enviornment variables: {0}'.format(missing))

    stack_name = '{0}-{1}-{2}'.format(os.getenv('OWNER'), os.getenv('AWS_DEFAULT_PROFILE'), args.type_of_stack)
    template_url = 'https://s3-us-west-2.amazonaws.com/{0}/cloudformation/{1}.yaml'.format(
                                                                                            os.getenv('S3BUCKET'),
                                                                                            args.type_of_stack
                                                                                           )
    log.info('stack name is: {0}'.format(stack_name))

    param_dict = {
        'name': stack_name,
        'template_url': template_url,
        'Environment': os.getenv('AWS_DEFAULT_PROFILE'),
        'Owner': os.getenv('OWNER'),
        'Product': os.getenv('PRODUCT'),
    }

    # data to pass to config file templates
    config_dict = {
        'Environment': os.getenv('AWS_DEFAULT_PROFILE'),
        'Owner': os.getenv('OWNER'),
        'S3BucketHome': os.getenv('S3BUCKET'),
    }

    config_file = join(
        '{0}/etc'.format(dirname(abspath(__file__))),
        '{0}_cfg.yaml'.format(args.type_of_stack)
    )

    if isfile(config_file):
        config = read_config(config_file=config_file, **config_dict)
        log.debug('configuration file dict is: {0}'.format(config))
        # merge configs
        param_dict.update(config)

    secrets_file = join(
        expanduser('~/.aws/etc'),
        '{0}_cfg.yaml'.format(args.type_of_stack)
    )

    if isfile(secrets_file):
        config = read_config(config_file=secrets_file, **config_dict)
        log.debug('configuration file dict is: {0}'.format(config))
        # merge configs
        param_dict.update(config)

    log.debug('parameters are: {0}'.format(param_dict))
    stack = CfnStack(**param_dict)
    log.debug(stack)

    if args.create:
        stack.create_stack()
    elif args.update:
        stack.update_stack()
    elif args.delete:
        stack.delete_stack()
    else:
        # argparse mutually exclusive group guarantees this will never happen
        raise ValueError('one of create, update, or delete required')


if __name__ == '__main__':
    try:
        logging.basicConfig(format='%(asctime)s %(message)s',
                            level=logging.INFO)
        log = logging.getLogger(__file__)
        main()
    except Exception:
        log.exception('FAILED: script {0})'.format(__file__))
        raise
