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

The time to rescale from N processes to M is measure as the time
between the "Starting process M" message in the script's log file,
and the last "Mona addresses have been updated, group size is now M" message
from all the processes.

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
    either in the form (t, 'starting', n) or (t, 'ready', n)."""
    events = []
    for line in open(filename):
        if 'Starting process' in line:
            t = parse_time(line)
            n = int(line.split()[4])
            events.append((t, 'starting', n))
        elif 'Mona addresses have been updated' in line:
            t = parse_time(line)
            n = int(line.split()[-1])
            events.append((t, 'ready', n))
    return events


def parse_all_files(filenames):
    """Parse a list of files, sort and merge their events."""
    events = []
    for filename in sys.argv[1:]:
        events.extend(parse_file(filename))
    events.sort()
    return events


def purge_events(events):
    """Remove events that are not needed (i.e. 'ready' events
    not corresponding to a 'starting' line)."""
    started = []
    kept = []
    for e in events:
        if e[1] == 'starting':
            started.append(e[2])
            kept.append(e)
        else:
            if e[2] in started:
                kept.append(e)
    return kept

def find_latest_times(events):
    """Build the dictionary associating a number of processes with
    the corresponding 'starting' time and the last 'ready' time."""
    timings = dict()
    for e in events:
        t = e[0]
        w = e[1]
        n = e[2]
        if n not in timings:
            timings[n] = [None, None]
        if w == 'starting':
            timings[n][0] = t
        else:
            timings[n][1] = t
    return timings


def print_as_csv(timings):
    """Takes the timings dictionary computed by find_latest_times
    and print the result as CSV on stdout."""
    for n in sorted(timings.keys()):
        v = timings[n]
        t = (v[1] - v[0]).total_seconds()
        print(n, t)

print_as_csv(
    find_latest_times(
        purge_events(
            parse_all_files(sys.argv[1:])
        )
    )
)
