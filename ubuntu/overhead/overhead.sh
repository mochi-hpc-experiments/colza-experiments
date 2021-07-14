#!/bin/bash

JOB_ID=`tr -dc A-Za-z0-9 </dev/urandom |  head -c 14`

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

SSG_FILENAME=colza.$JOB_ID.ssg
LOG_DIR=logs-$JOB_ID
mkdir $LOG_DIR

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

function get_node_list() {
    START_LINE=$1
    NUM_NODES=$2
    hosts=$(readarray -t ARRAY < <(tail -n+$START_LINE $HOSTFILE | head -n$NUM_NODES); \
           IFS=','; echo "${ARRAY[*]}")
    echo $hosts
}

function add_instance () {
    INSTANCE_NUMBER=$1
    WAITTIME=$2
    CREATE_GROUP=$3
    OUTFILE=$LOG_DIR/overhead.$INSTANCE_NUMBER.$JOB_ID.out
    HOST=$(get_node_list $INSTANCE_NUMBER 1)
    print_log "Starting process $INSTANCE_NUMBER of staging area on $HOST"
    if [ "$CREATE_GROUP" -eq "1" ]; then
        JOIN=""
    else
        JOIN="-j"
    fi
    mpirun -np 1 --hosts $HOST colza-dist-server $JOIN \
              -a ofi+tcp \
              -v trace \
              -p 500 \
              -s $SSG_FILENAME \
              -c $HERE/pipeline.json \
              -t 1 > $OUTFILE 2>&1 &
    SRUN_PID=$!
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Done!"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

print_log "Starting first server instance"
add_instance 1 30 1

print_log "Starting client"
colza-dist-client \
            -a ofi+tcp \
            -v trace \
            -s $SSG_FILENAME \
            -p abc \
            -i 10000 \
            --no-execute \
            --no-stage \
            -w 1 > $LOG_DIR/overhead.client.$JOB_ID.out 2>&1 &
CLIENT_PID=$!

sleep 15
print_log "Starting more servers"

for (( P=2; P <= $NUM_NODES;  P=$P+1 ))
do
    add_instance $P 15 0
done

print_log "Killing client"
kill $CLIENT_PID

print_log "Shutting down the staging area"
colza-dist-admin \
            -a ofi+tcp \
            -v trace \
            -s $SSG_FILENAME \
            -x shutdown
print_log "Experiment complete"

rm $SSG_FILENAME

print_log "Parsing results and creating CSV file"
python $HERE/parse-logs.py \
    $LOG_DIR/overhead.client.$JOB_ID.out \
    > overhead-$JOB_ID.csv

print_log "All done!"
