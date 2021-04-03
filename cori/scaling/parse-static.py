"""
This file parses the log files resulting from a run of static-scaling.sbatch.
The logs of this run consist of a file produced by the script itself, named
static-scaling-<jobid>.out, and a list of files named static.<N>.<jobid>.out
produced by a deployment of the staging area with N servers.

This script looks for the following types of lines in the script's output:
[2021-03-10 14:41:03.452571842] Starting staging area on X processes
(printed right before a staging area is deployed)
[2021-03-10 14:41:33.464327656] Killing staging area
(printed right before a request to kill the staging area is done)

The script looks for the following types of lines in the staging area logs:
[2021-03-10 14:41:43.297] [info] Server running at address ofi+gni://...
(printed when the process is running and ready to accept requests from clients)

The time to rescale from N processes to M is measure as the time
between the "Killing staging area" message for a staging area of N processes,
and the last "Server running" message for a staging area of M processes.
except for initial deployment, where the time is measured between the
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
    """Get the timestamp from a line."""
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


def parse_file(filename):
    """Parse a single file, generate a list of tuples
    either in the form (t, 'starting', n) or (t, 'ready', 0),
    or (t, 'killed', 0)."""
    events = []
    for line in open(filename):
        if 'Starting staging area on' in line:
            t = parse_time(line)
            n = int(line.split()[6])
            events.append((t, 'starting', n))
        elif 'Killing staging area' in line:
            t = parse_time(line)
            events.append((t, 'killed', 0))
        elif 'Server running at address' in line:
            t = parse_time(line)
            events.append((t, 'ready', 0))
    return events


def parse_all_files(filenames):
    """Parse a list of files, sort and merge their events."""
    events = []
    for filename in sys.argv[1:]:
        events.extend(parse_file(filename))
    events.sort()
    return events


def purge_events(events):
    """Remove unnecessary events (and add one at the beginning)."""
    events.insert(0, (events[0][0], 'killed', 0))
    events_copy = []
    n = 0
    for i in range(0, len(events)):
        if events[i][1] == 'killed':
            events_copy.append(events[i])
        elif events[i][1] == 'starting':
            n = events[i][2]
        elif events[i][1] == 'ready':
            if events_copy[-1][1] == 'ready':
                events_copy[-1] = (events[i][0], 'ready', n)
            else:
                events_copy.append((events[i][0], 'ready', n))
    return events_copy

events =  purge_events(parse_all_files(sys.argv[1:]))
for i, j in zip(events[0::2], events[1::2]):
    t = (j[0]-i[0]).total_seconds()
    print(str(j[2])+','+str(t))
