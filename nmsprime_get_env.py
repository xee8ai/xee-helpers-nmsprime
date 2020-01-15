#!/usr/bin/env python3

import os
import os.path
from pprint import pprint
import sys

nmsprime_path = '/var/www/nmsprime'

tasks = {
        'db' : 'DB_DATABASE',
        'host' : 'DB_HOST',
        'password' : 'DB_PASSWORD',
        'user' : 'DB_USERNAME',

        'db_ccc' : 'CCC_DB_DATABASE',
        'host_ccc' : 'CCC_DB_HOST',
        'password_ccc' : 'CCC_DB_PASSWORD',
        'user_ccc' : 'CCC_DB_USERNAME',

        'db_cacti' : 'CACTI_DB_DATABASE',
        'host_cacti' : 'CACTI_DB_HOST',
        'password_cacti' : 'CACTI_DB_PASSWORD',
        'user_cacti' : 'CACTI_DB_USERNAME',

        'db_icinga2' : 'ICINGA2_DB_DATABASE',
        'host_icinga2' : 'ICINGA2_DB_HOST',
        'password_icinga2' : 'ICINGA2_DB_PASSWORD',
        'user_icinga2' : 'ICINGA2_DB_USERNAME',
}
mappings = {v: k for k, v in tasks.items()}

envs = ['local', 'global']
env_path = '/etc/nmsprime/env'

def error():
    print('Usage: {} [{}] [{}]'.format(sys.argv[0], '|'.join(tasks.keys()), '|'.join(envs)))
    sys.exit(1)

if (len(sys.argv) is not 3):
    error()

if sys.argv[1] not in tasks.keys():
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
    key = parts[0].strip()
    if key in mappings.keys():
        data[mappings[key]] = getValue(parts[1])

print(data[sys.argv[1]])
