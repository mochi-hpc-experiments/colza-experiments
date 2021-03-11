"""
This file parses the log files resulting from a run of static-scaling.sbatch.
The logs of this run consist of a file produced by the script itself, named
static-scaling-<jobid>.out, and a list of files named static.<N>.<jobid>.out
produced by a deployment of the staging area with N servers.

This script looks for the following types of lines in the script's output:
[2021-03-10 14:41:03.452571842] Starting staging area on 1 processes
(printed right before a staging area is deployed)
[2021-03-10 14:41:33.464327656] Killing staging area
(printed right before a request to kill the staging area is done)

The script looks for the following types of lines in the staging area logs:
[2021-03-10 14:41:43.297] [info] Server running at address ofi+gni://...
(printed when the process is running and ready to accept requests from clients)

The time to rescale from N processes to N+1 is measure as the time
between the "Killing staging area" message for a staging area of N processes,
and the last "Server running" message for a staging area of N+1 processes.
except for the case of 1 process, where the time is measure between the
"Starting staging area" message and the "Server running" message.

The script outputs CSV data on its standard output. Each line contains two
columns: <size>, <time>
where <size> is the size of the staging area, and <time> is the time to
transition from a staging area of size <size-1> and one of size <size>.
"""

import sys
import os
import re
import datetime

date_re = re.compile('^\[(\d\d\d\d)-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d.\d+)\]')

def parse_time(line):
    m = date_re.match(line)
    if m is None:
        return None
    year = int(m.group(1))
    month = int(m.group(2))
    day = int(m.group(3))
    hour = int(m.group(4))
    minute = int(m.group(5))
    second = float(m.group(6))
    date = datetime.datetime(
        year, month, day,
        hour, minute, int(second),
        int((second - int(second))*1000000))
    return date

def find_ready_time(filename):
    result = None
    for line in open(filename):
        if 'Server running at address' not in line:
            continue
        t = parse_time(line)
        if result is None:
            result = t
        elif t > result:
            result = t
    return result


if len(sys.argv) != 2:
    print('Usage: python parse-static.py <job-id>')
    sys.exit(-1)

job_id = int(sys.argv[1])
job_out_filename = 'static-scaling-%d.out' % job_id

start_times = []
kill_times = []
for line in open(job_out_filename):
    if 'Starting staging area' in line:
        t = parse_time(line)
        start_times.append(t)
    elif 'Killing staging area' in line:
        t = parse_time(line)
        kill_times.append(t)

ready_times = []
for i in range(1, len(start_times)+1):
    logfile = 'static.%d.%d.out' % (i, job_id)
    t = find_ready_time(logfile)
    ready_times.append(t)

for i in range(1, len(start_times)+1):
    if ready_times[i-1] is None:
        continue
    if i == 1:
        t = (ready_times[0] - start_times[0]).total_seconds()
    else:
        t = (ready_times[i-1] - kill_times[i-2]).total_seconds()
    print('%d,%f' % (i, t))
