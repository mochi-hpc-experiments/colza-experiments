#!/bin/bash

INCR=${1:-1}
START=${2:-${INCR}}

JOB_ID=`tr -dc A-Za-z0-9 </dev/urandom |  head -c 14`

HERE=`dirname "$0"`
source $HERE/settings.sh

SSG_FILENAME=colza.$JOB_ID.ssg
LOG_DIR=logs-$JOB_ID
mkdir $LOG_DIR

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

function add_instance () {
    INSTANCE_NUMBER=$1
    WAITTIME=$2
    CREATE_GROUP=$3
    OUTFILE=$LOG_DIR/overhead.$INSTANCE_NUMBER.$JOB_ID.out
    print_log "Starting process $INSTANCE_NUMBER of staging area"
    NP=$INCR
    if [ "$CREATE_GROUP" -eq "1" ]; then
        JOIN=""
        NP=$START
    else
        JOIN="-j"
    fi
    mpirun -np $NP colza-dist-server $JOIN \
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
mpirun -np 1 colza-dist-client \
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

for (( P=$START+$INCR; P <= 63;  P=$P+$INCR ))
do
    add_instance $P 15 0
done

print_log "Killing client"
kill $CLIENT_PID

print_log "Shutting down the staging area"
mpirun -np 1 colza-dist-admin \
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
