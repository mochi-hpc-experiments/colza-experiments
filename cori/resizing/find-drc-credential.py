"""This script takes a log file and search for a line in the form
[2021-03-30 03:06:11.936] [trace] Credential id is X
and print X on its standard output."""

import sys

credential_id = -1
for line in open(sys.argv[1]):
    if 'Credential id is' in line:
        credential_id = int(line.split()[-1])
        break

print(credential_id)
