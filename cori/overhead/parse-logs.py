"""This script is parsing the client log file
(name overhead.client.<jobid>.out) and looking for
lines in the following format:
[2021-04-05 04:15:26.317] [trace] Done calling start(45), took 0.40437912940979004 seconds
It extracts the iteration number passed to the start call
as well as the duration of the call. It generates CSV data
on its standard output.
"""

import sys

print("#iteration,duration(sec)")

iteration = 0
change = ''

for line in open(sys.argv[1]):
    if '[warning] Invalid group hash detected, group view needs to be updated' in line:
        change = '1'
    if 'Done calling start(' not in line:
        continue
    words = line.split()
    print(str(iteration)+','+words[7]+','+change)
    iteration += 1
    change = ''
