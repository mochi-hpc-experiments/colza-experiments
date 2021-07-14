#!/bin/bash

JOB_ID=`tr -dc A-Za-z0-9 </dev/urandom |  head -c 14`
MAIN_LOG=static-resizing-$JOB_ID.out

HERE=`dirname "$0"`
HERE=`realpath $HERE`

source $HERE/settings.sh

HOSTFILE=$HERE/nodes.txt
if [ ! -f "$HOSTFILE" ]; then
    echo "$HOSTFILE does not exist."
    echo "Please create this file with a list of nodes to use."
    exit -1
fi

NUM_NODES=`cat $HOSTFILE | wc -l`
NUM_PROCS=$NUM_NODES

SSG_FILENAME=colza-$JOB_ID.ssg
LOG_DIR=logs-$JOB_ID
mkdir $LOG_DIR

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG" | tee -a $MAIN_LOG
}

function run_instance () {
    NPROCS=$1
    WAITTIME=$2
    OUTFILE=$LOG_DIR/static.$NPROCS.$JOB_ID.out
    print_log "Starting staging area on $NPROCS processes"
    mpirun -n $NPROCS -f $HOSTFILE colza-dist-server \
              -a ofi+tcp \
              -v trace \
              -s $SSG_FILENAME \
              -p 500 \
              -c $HERE/pipeline.json \
              -t 1 > $OUTFILE 2>&1 &
    SRUN_PID=$!
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Killing staging area"
    kill $SRUN_PID
    print_log "Waiting for staging area to shut down"
    wait $SRUN_PID
    print_log "Done!"
    rm $SSG_FILENAME
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

for (( NPROCS=1; NPROCS <= $NUM_NODES;  NPROCS=$NPROCS+1 ))
do
    run_instance $NPROCS 60
done

print_log "Experiment done"

print_log "Parsing results and creating CSV file"
python $HERE/parse-static.py static-resizing-$JOB_ID.out $LOG_DIR/*.out > static-$JOB_ID.csv

print_log "Moving log files"
mv static-resizing-$JOB_ID.out $LOG_DIR
