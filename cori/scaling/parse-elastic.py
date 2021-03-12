"""
This file parses the log files resulting from a run of elastic-scaling.sbatch.
The logs of this run consist of a file produced by the script itself, named
elastic-scaling-<jobid>.out, and a list of files named static.<N>.<jobid>.out
produced by the Nth server of the deployment.

This script looks for the following types of lines in the script's output:
[2021-03-10 15:53:33.504092869] Starting process 1 of staging area
(starting a process for the staging area)

The script looks for the following types of lines in the staging area logs:
[2021-03-10 15:54:05.538] [trace] Mona addresses have been updated, group size is now 2
(printed when the process has successfully added a member to its group)

The time to rescale from N processes to N+1 is measure as the time
between the "Starting process N+1" message in the script's log file,
and the last "Mona addresses have been updated" message from all the
processes running at this scale.

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

def find_ready_times(filename, rank, expected_num_lines):
    result = []
    for line in open(filename):
        if 'Mona addresses have been updated' not in line:
            continue
        t = parse_time(line)
        result.append(t)
    if len(result) < expected_num_lines:
        print("WARNING: adding %d line for process %d" % (expected_num_lines - len(result), rank))
    while len(result) < expected_num_lines:
        result.append(result[-1])
    return result

def find_last_ready_times(ready_times, num_procs):
    times = [ ready_times[i][num_procs-1-i] for i in range(0, num_procs) ]
    return max(times)

if len(sys.argv) != 2:
    print('Usage: python parse-elastic.py <job-id>')
    sys.exit(-1)

job_id = int(sys.argv[1])
job_out_filename = 'elastic-scaling-%d.out' % job_id

start_times = []
for line in open(job_out_filename):
    if 'Starting process' in line:
        t = parse_time(line)
        start_times.append(t)

ready_times = []
for i in range(1, len(start_times)+1):
    logfile = 'elastic.%d.%d.out' % (i, job_id)
    ts = find_ready_times(logfile, i, len(start_times)-i+1)
    ready_times.append(ts)

for i in range(1, len(start_times)+1):
    ready_time = find_last_ready_times(ready_times, i)
    t = (ready_time - start_times[i-1]).total_seconds()
    print('%d,%f' % (i, t))
