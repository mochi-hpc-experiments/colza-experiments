#!/bin/bash

HERE=`dirname $0`
HERE=`realpath $HERE`

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG" | tee -a $MAIN_LOG
}

print_log "Activating environment"
source $HERE/activate.sh

PROTOCOL=ofi+tcp

BEDROCK_CONFIG=$HERE/config/config.json
BEDROCK_OUT="bedrock.%r.out"
BEDROCK_ERR="bedrock.%r.err"
BEDROCK_SSG_FILE=$(cat $BEDROCK_CONFIG | jq -r ".ssg|.[0]|.group_file")

function ensure_bedrock_is_alive() {
    $(kill -0 $BEDROCK_PID)
    BEDROCK_IS_DEAD=$?
    if [ $BEDROCK_IS_DEAD -ne 0 ];
    then
        print_log "Bedrock died, please see logs ($BEDROCK_OUT and $BEDROCK_ERR) for information"
        exit -1
    fi
}

if [ -z "$BEDROCK_SSG_FILE" ]
then
  print_log "ERROR: No SSG group file found in configuration"
  exit -1
fi

print_log "Generating UUID for experiment"
exp_id=$(uuidgen)
exp_id=${exp_id:0:8}
exp_date=$(date +"%Y-%m-%d-%H-%M")

exp_dir="exp-$exp_date-$exp_id"
print_log "Creating experiment's directory $exp_dir"
mkdir $exp_dir
cd $exp_dir

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/sw/colza-ascent-pipeline/lib

print_log "Starting Bedrock daemon"
MPI_WRAPPERS=`spack location -i mochi-mona`/lib/libmona-mpi-wrappers.so
mpirun -np 2 -env LD_PRELOAD $MPI_WRAPPERS \
       -outfile-pattern $BEDROCK_OUT \
       -errfile-pattern $BEDROCK_ERR \
    bedrock $PROTOCOL -c $BEDROCK_CONFIG -v info &
BEDROCK_PID=$!

print_log "Waiting for SSG file to become available"
while [ ! -f $BEDROCK_SSG_FILE ]
do
    ensure_bedrock_is_alive
    sleep 1
done

ensure_bedrock_is_alive
print_log "Servers are ready"

print_log "Starting AMR-WIND"
AMR_WIND=$COLZA_EXP_PREFIX_PATH/amr-wind/bin/amr_wind
AMR_WIND_INPUT=$HERE/input/laptop_scale.damBreak.i

mpirun -np 2 $AMR_WIND $AMR_WIND_INPUT

print_log "Shutting down servers"
mpirun -np 1 bedrock-shutdown $PROTOCOL -s $BEDROCK_SSG_FILE

print_log "Terminating"
