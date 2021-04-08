import sys

print('Iteration,Num Colza procs,start(sec),stage(sec),execute(sec),cleanup(sec)')
iteration = 1
num_procs = 2

s = ''

for line in open(sys.argv[1]):
    if 'start time' in line:
        s = str(iteration)+','+str(num_procs)+','
        s += line.split()[-1]+','
    elif ('stage time' in line) or ('execution time' in line):
        s += line.split()[-1]+','
    elif 'cleanup time' in line:
        s += line.split()[-1]
        iteration += 1
        print(s)
    elif 'warning' in line:
        num_procs += 1

