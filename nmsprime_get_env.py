#!/usr/bin/env python3

import os
import os.path
from pprint import pprint
import sys

nmsprime_path = '/var/www/nmsprime'

tasks = ['db', 'db_ccc', 'host', 'host_ccc', 'user', 'user_ccc', 'password', 'password_ccc']
envs = ['local', 'global']
env_path = '/etc/nmsprime/env'

def error():
    print('Usage: {} [{}] [{}]'.format(sys.argv[0], '|'.join(tasks), '|'.join(envs)))
    sys.exit(1)

if (len(sys.argv) is not 3):
    error()

if sys.argv[1] not in tasks:
    error()

if sys.argv[2] not in envs:
    error()

env_files = []
if sys.argv[2] == 'local' or sys.argv[2] == 'global':
    for f in os.listdir(env_path):
        if f.endswith('.env'):
            env_files.append(f)


def getValue(rawData):
    data = rawData.strip()
    data = data.replace('"', '')
    data = data.replace("'", "")
    data = data.replace(",", "")
    return data


lines = []
for env_file in env_files:
    with open(os.path.join(env_path, env_file), 'r') as fh:
        newlines = fh.readlines()
        for l in newlines:
            lines.append(l)

data = {}
for line in lines:
    line = line.strip()

    # ignore comments
    if line.startswith('#'):
        continue

    parts = line.split('=')
    if 'DB_DATABASE' == parts[0]:
        data['db'] = getValue(parts[1])
    elif 'CCC_DB_DATABASE' == parts[0]:
        data['db_ccc'] = getValue(parts[1])
    elif 'DB_HOST' == parts[0]:
        data['host'] = getValue(parts[1])
    elif 'CCC_DB_HOST' == parts[0]:
        data['host_ccc'] = getValue(parts[1])
    elif 'DB_USERNAME' == parts[0]:
        data['user'] = getValue(parts[1])
    elif 'CCC_DB_USERNAME' == parts[0]:
        data['user_ccc'] = getValue(parts[1])
    elif 'DB_PASSWORD' == parts[0]:
        data['password'] = getValue(parts[1])
    elif 'CCC_DB_PASSWORD' == parts[0]:
        data['password_ccc'] = getValue(parts[1])

print(data[sys.argv[1]])
