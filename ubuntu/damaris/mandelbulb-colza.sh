#!/bin/bash

JOB_ID=`tr -dc A-Za-z0-9 </dev/urandom |  head -c 14`
MAIN_LOG="mb-colza-$JOB_ID.out"

HERE=`dirname "$0"`
HERE=`realpath $HERE`
source $HERE/settings.sh

METHOD=${1:-mona} # can be changed to mpi
CONFIG=mb-$METHOD-pipeline.json

CLIENT_PROCS=2
SERVER_PROCS=2

STEP=6
PROTOCOL=tcp
SSG_FILENAME=colza-$JOB_ID.ssg
SSG_SWIM_PERIOD=5000
LOG_DIR=logs-$JOB_ID
mkdir $LOG_DIR

BLOCKLENW=64
BLOCKLENH=64
BLOCKLEND=64
BLOCKNUM=8 # total, so 4 per client

SERVERS_OUT_LOG=$LOG_DIR/mb-${METHOD}.servers.$JOB_ID.out
CLIENTS_OUT_LOG=$LOG_DIR/mb-${METHOD}.clients.$JOB_ID.out

export ABT_THREAD_STACKSIZE=2097152
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/../vtk/sw/mini-apps/lib

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG" | tee -a $MAIN_LOG
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

print_log "Staring servers on $SERVER_PROCS processes"

mpirun -n $SERVER_PROCS \
    $HERE/../vtk/sw/mini-apps/bin/example/MandelbulbColza/mbserver \
    -a $PROTOCOL \
    -s $SSG_FILENAME \
    -c $CONFIG -t 1 \
    -p $SSG_SWIM_PERIOD &> $SERVERS_OUT_LOG &
COLZA_PID=$!
print_log "Waiting for all the servers processes to start"

servers_ready=0
while [ $servers_ready -ne $SERVER_PROCS ]
do
    servers_ready=$(cat $SERVERS_OUT_LOG | grep "Server running at" | wc -l)
    sleep 1
    print_log "$servers_ready servers are ready"
done

print_log "Start clients on  $CLIENT_PROCS processes"

mpirun  -n $CLIENT_PROCS \
    $HERE/../vtk/sw/mini-apps/bin/example/MandelbulbColza/mbclient \
    -a $PROTOCOL \
    -s $SSG_FILENAME \
    -p vtk \
    -b $BLOCKNUM \
    -t $STEP \
    -w $BLOCKLENW \
    -d $BLOCKLEND \
    -e $BLOCKLENH &> $CLIENTS_OUT_LOG

print_log "Client done"
kill $COLZA_PID
print_log "All done!"

