#!/usr/bin/env python
"""manage_key_pair.py

create, delete, or rotate an ec2 keypair
write private key to file $HOME/.ssh/{keypair}.pem

Example:
    call as script with optional -v argument
    -v will enable debug mode for verbose output
    -vv will enable very verbose output

      $ manage_keypair.py -vv [-k keypair]

"""
from __future__ import absolute_import, division, print_function

import os
import sys
import stat
import boto3
import platform
import logging
import argparse


def get_pem_filename(keyname):
    """get pem filename from keyname

    Args:
        keyname (String): name of keypair

    Returns:
        absolute path filename

    """
    log = logging.getLogger(__file__)
    log.debug('BEGIN get_pem_filename')
    log.debug('arg keyname is: {0}'.format(keyname))
    log.debug('END get_pem_filename')
    return os.path.join(os.path.expanduser('~'), '.ssh', keyname + '.pem')


def delete_keypair(keyname):
    """delete ec2 keypair and delete private key file

    Args:
        keyname (String): name of keypair to delete

    Returns:
        response (dict)

    """
    log = logging.getLogger(__file__)
    log.debug('BEGIN delete_keypair')
    log.debug('parameter keyname is: {0}'.format(keyname))

    client = boto3.client('ec2')

    log.debug('deleting keypair: {0}'.format(keyname))
    # returns success if keypair does not exist
    response = client.delete_key_pair(
        KeyName=keyname
    )
    log.debug('delete response is: {0}'.format(response))

    filename = get_pem_filename(keyname)
    # remove file if it exists.
    if os.path.isfile(filename):
        os.remove(filename)

    log.debug('END delete_keypair')
    return response


def write_pem(keyinfo):
    """write private pem to file in $HOME/.ssh directory
    with appropriate permissions
    assumes .ssh directory exists for now

    Args:
        keyinfo (Dict): response from creating key

    """
    log = logging.getLogger(__file__)
    log.debug('BEGIN write_pem')
    log.debug('arg keyinfo is: {0}'.format(keyinfo))
    filename = get_pem_filename(keyinfo['KeyName'])
    log.debug('filename to write is: {0}'.format(filename))

    # since we are working with keys let's be very careful that file permissions are correct
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL  # Refer to "man 2 open".
    mode = stat.S_IRUSR | stat.S_IWUSR  # This is 0o600 in octal

    # remove file if it exists.  This avoids inheriting file permissions of existing file
    if os.path.isfile(filename):
        os.remove(filename)

    # don't let current umask interfere with permissions by setting to 0
    # but preserve umask setting and restore it when done with file
    umask_original = os.umask(0)

    # get file descriptor with permissions set
    try:
        fdesc = os.open(filename, flags, mode)
    finally:
        os.umask(umask_original)

    with os.fdopen(fdesc, 'w') as keyfile:
        keyfile.write(keyinfo['KeyMaterial'])

    log.debug('END write_pem')


def create_keypair(keypair_name):
    """create an ec2 keypair and write private key to file

    Args:
        keypair_name (String): name of keypair to create

    Returns:
        response (Dict): includes pem and keypair_name

    """
    log = logging.getLogger(__file__)
    log.debug('BEGIN create_keypair')

    client = boto3.client('ec2')
    response = client.create_key_pair(
        KeyName=keypair_name
    )

    log.debug('keypair create response is: {0}'.format(response))
    log.debug('END create_keypair')
    # just return keypair name for testing
    return response


def main():
    """entry function runs when script is executed."""
    log = logging.getLogger(__file__)
    log.info('python version is: {0}'.format(platform.python_version()))

    # parse command line arguments
    parser = argparse.ArgumentParser(description='create keypair and write pem file')
    # count the number of verbose options
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='increase output detail')
    parser.add_argument('-k', '--keypair', required=True,
                        help='name of ec2 keypair to create')
    # one of create, delete, or rotate is required
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-c', '--create', action='store_true')
    group.add_argument('-d', '--delete', action='store_true')
    group.add_argument('-r', '--rotate', action='store_true')

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
    log.debug('boto3 version is: {0}'.format(boto3.__version__))

    if args.create:
        response = create_keypair(args.keypair)
        log.debug('create returned: {0}'.format(response))
        write_pem(response)
    elif args.delete:
        response = delete_keypair(args.keypair)
        log.debug('delete returned: {0}'.format(response))
    elif args.rotate:
        response = delete_keypair(args.keypair)
        log.debug('delete returned: {0}'.format(response))
        response = create_keypair(args.keypair)
        log.debug('create returned: {0}'.format(response))
        write_pem(response)
    else:
        # argparse mutually exclusive group guaruntees this will never happen
        raise ValueError('one of create, delete, or rotate was not passes as argument' +
                         'but somehow argument parser allowed this')


if __name__ == '__main__':
    try:
        logging.basicConfig(format='%(asctime)s %(message)s',
                            level=logging.INFO)
        log = logging.getLogger(__file__)
        main()
    except Exception:
        log.exception('FAILED: script {0})'.format(__file__))
        raise
