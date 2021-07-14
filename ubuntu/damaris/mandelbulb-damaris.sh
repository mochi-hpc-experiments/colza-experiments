#!/bin/bash
JOB_ID=`tr -dc A-Za-z0-9 </dev/urandom |  head -c 14`
MAIN_LOG="mb-damaris-$JOB_ID.out"

HERE=`dirname "$0"`
HERE=`realpath $HERE`

source $HERE/settings.sh

CONFIG=$HERE/damaris-config.xml
SCRIPT=$HERE/../vtk/src/mini-apps/example/MandelbulbColza/pipeline/mbrender_64_iso.py
CLIENT_PROCS=2
SERVER_PROCS=2

TOTAL_PROCS=4

STEP=6
LOG_DIR=logs-$JOB_ID
mkdir $LOG_DIR

OUT_LOG=$LOG_DIR/mb-damaris.$JOB_ID.out

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

print_log "Staring application"

mpirun -n $TOTAL_PROCS \
    $HERE/../vtk/sw/mini-apps/bin/example/MandelbulbDamaris/mbclient_damaris \
    -c $CONFIG -t $STEP \
    -s $SCRIPT &> $OUT_LOG
print_log "Completed"
