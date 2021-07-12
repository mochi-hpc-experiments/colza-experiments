#!/bin/bash

JOB_ID=`tr -dc A-Za-z0-9 </dev/urandom |  head -c 14`

HERE=`dirname "$0"`
HERE=`realpath $HERE`
source $HERE/settings.sh

NUM_NODES=32
NUM_PROCS=$NUM_NODES

ITERATIONS=100
MSG_SIZES=(8 128 2048 32768 524288)
TRANSPORT=ofi+tcp

LOG_DIR=logs-$JOB_ID
mkdir $LOG_DIR

LOG=$LOG_DIR/result.$JOB_ID

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

for MSG_SIZE in ${MSG_SIZES[@]}; do

    print_log "Staring Allreduce benchmark using MPI with message size = ${MSG_SIZE}"

    mpirun -np $NUM_PROCS \
        mona-allreduce-benchmark \
        -m mpi -s $MSG_SIZE -i $ITERATIONS >> $LOG.mpi

    print_log "Staring Allreduce benchmark using MoNA with message size = ${MSG_SIZE}"

    mpirun -np $NUM_PROCS \
        mona-allreduce-benchmark \
        -m mona -t $TRANSPORT -s $MSG_SIZE -i $ITERATIONS >> $LOG.mona

done

print_log "Benchmarks completed"
