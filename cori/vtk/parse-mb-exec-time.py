import sys
import glob
import os
import re

def main(argv):
    if len(sys.argv)!=2:
        print("parse-mb-exec-time <log dir name>")
        return
    logdir=str(sys.argv[1])
    # open client file
    clientlog=logdir+"/"+"*.clients.*"
    execution_time_list=[]
    for filename in glob.glob(clientlog):  
        print("client_file: ", filename)
        with open(filename, 'r') as f:
            for line in f:
                line = line.rstrip('\n')
                if(line.find("execution time")!=-1):
                    print(line)
                    extract_str = re.findall("\d+\.\d+", line)
                    execution_time_list.append(float(extract_str[0]))


    print("avg execution time without first step:")
    print(sum(execution_time_list[1:]) / (len(execution_time_list)-1))


if __name__ == "__main__":
    main(sys.argv[1:])
