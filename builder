#!/usr/bin/python

import sys
import gnsq
import json
import logging

if len(sys.argv) != 1:
    sys.stderr.write("Invalid number of arguments\n")
    sys.stderr.write("Usage: %s\n" % sys.argv[0])
    sys.exit(1)

logging.basicConfig()
logger = logging.getLogger('logger')
conn = gnsq.Nsqd(address='localhost', http_port=4151)

reader = gnsq.Reader('series_applied', 'build', 'localhost:4150')

@reader.on_message.connect
def handler(reader, message):
    series = json.loads(message.body)
    if series['apply_success']:
        if "unbuildable" in series['patch_list']:
            series['build_success'] = False
            series['build_log'] = "driver.c:83:7: error: expected '}' before 'else'"
        else:
            series['build_success'] = True
        conn.publish('series_built', json.dumps(series))
    message.finish()

reader.start()
