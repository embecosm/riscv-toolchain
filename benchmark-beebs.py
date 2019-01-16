#!/usr/bin/env python3

import datetime
import itertools
import logging
import os
import shutil
import subprocess
import sys

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))
TOP_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..'))
BEEBS_DIR = os.path.join(TOP_DIR, 'beebs')

HOSTS = { 'riscv': 'riscv32-unknown-elf', 'arm': 'arm-none-eabi', 'arc': 'arc-elf32' }

CONFIGS = [ 'baseline', 'nocrt', 'nolibc', 'nolibc-nolibgcc', 'nolibc-nolibgcc-nolibm' ]

log = logging.getLogger()

def setup_logging(logfile):
    log.setLevel(logging.DEBUG)
    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.INFO)
    log.addHandler(ch)
    fh = logging.FileHandler(logfile)
    fh.setLevel(logging.DEBUG)
    log.addHandler(fh)

class RunCommandError(RuntimeError):
    '''Exception raised when something went wrong with execution of command.'''
    pass

def run_command(args, *, timeout, work_dir, toolchain_dir):
    log.debug('Running %s' % " ".join(args))
    path = toolchain_dir + os.pathsep + os.environ['PATH']
    env = { 'PATH': path }
    try:
        cp = subprocess.run(args, capture_output=True, check=True, timeout=timeout, cwd=work_dir, env=env)
        log.info('Process exited normally')
        log.debug('Stdout:\n\n%s\n\n' % cp.stdout.decode())
        log.debug('Stderr:\n\n%s\n\n' % cp.stderr.decode())
        return
    except subprocess.TimeoutExpired as e:
        log.info('Execution timeout (%ss) expired') % timeout
        log.info('Stdout:\n\n%s\n\n' % e.stdout.decode())
        log.info('Stderr:\n\n%s\n\n' % e.stderr.decode())
        raise RunCommandError
    except subprocess.CalledProcessError as e:
        log.info('Process exited abnormally with code %s' % e.returncode)
        log.info('Stdout:\n\n%s\n\n' % e.stdout.decode())
        log.info('Stderr:\n\n%s\n\n' % e.stderr.decode())
        raise RunCommandError

def build(host, config):
    build_dir = os.path.join(TOP_DIR, 'build-%s' % host, 'beebs-%s' % config)
    log.info('Building in %s' % build_dir)
    if os.path.exists(build_dir):
        if os.path.isdir(build_dir):
            shutil.rmtree(build_dir)
        else:
            os.remove(build_dir)
    try:
        os.mkdir(build_dir)
    except FileExistsError:
        log.info('Using existing build dir')
    configure = os.path.join(BEEBS_DIR, 'configure')
    host_arg = '--host=%s' % HOSTS[host]
    toolchain_dir = os.path.join(TOP_DIR, 'install-%s' % host, 'bin')
    try:
        log.info('Configuring...')
        chip_arg = '--with-chip=compare-%s' % config
        board_arg = '--with-board=generic'
        config_args = [ configure, host_arg, chip_arg, board_arg ]
        run_command(config_args, timeout=30, work_dir=build_dir, toolchain_dir=toolchain_dir)
        log.info('Building...')
        run_command(['make', '-j9'], timeout=120, work_dir=build_dir, toolchain_dir=toolchain_dir)
        log.info('Benchmarking...')
        run_command(['make', 'check'], timeout=60, work_dir=build_dir, toolchain_dir=toolchain_dir)
    except RunCommandError:
        log.info('Aborting due to error in command execution.')
        raise

def main():
    log_name = 'benchmark-beebs-%s.log' % datetime.datetime.now().strftime('%Y-%m-%d-%H%M')
    log_path = os.path.join(TOP_DIR, 'logs', log_name)
    setup_logging(log_path)

    log.info('Top dir: %s', TOP_DIR)
    for host, config in itertools.product(HOSTS, CONFIGS):
        log.info('\nBuilding %s on %s' % (config, host))
        try:
            build(host, config)
        except RunCommandError:
            return 1

    return 0

if __name__ == '__main__':
    sys.exit(main())
