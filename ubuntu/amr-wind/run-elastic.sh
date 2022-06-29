#!/bin/bash

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG" | tee -a $MAIN_LOG
}

HERE=`dirname $0`
HERE=`realpath $HERE`

HOSTFILE=$HERE/hosts.txt
readarray -t HOSTS < $HOSTFILE
NUM_HOSTS=${#HOSTS[@]}

NUM_AMRWIND_HOSTS=${1:-4}
NUM_COLZA_HOSTS_MIN=${2:-1}
NUM_COLZA_HOSTS_MAX=${3:-4}
NUM_NEW_COLZA_PER_STEP=${4:-1}
TIME_BETWEEN_INCREASES=${5:-30}

if (( $NUM_AMRWIND_HOSTS + $NUM_COLZA_HOSTS_MAX > $NUM_HOSTS )); then
    print_log "ERROR: Not enough hosts in $HOSTFILE to run $NUM_AMRWIND_HOSTS AMR-WIND processes and $NUM_COLZA_HOSTS Colza processes"
    exit -1
fi
if (( $NUM_AMRWIND_HOSTS < $NUM_COLZA_HOSTS_MAX )); then
    print_log "ERROR: Cannot run with NUM_AMRWIND_HOSTS ($NUM_AMRWIND_HOSTS) < NUM_COLZA_HOSTS ($NUM_COLZA_HOSTS_MAX)"
    exit -1
fi
if (( $NUM_COLZA_HOSTS_MIN > $NUM_COLZA_HOSTS_MAX )); then
    print_log "ERROR: NUM_COLZA_HOSTS_MIN ($NUM_COLZA_HOSTS_MIN) > NUM_COLZA_HOSTS_MAX ($NUM_COLZA_HOSTS_MAX)"
    exit -1
fi

HOSTS_FOR_AMRWIND=$(printf ",%s" "${HOSTS[@]:0:$NUM_AMRWIND_HOSTS}")
HOSTS_FOR_AMRWIND=${HOSTS_FOR_AMRWIND:1}

print_log "Hosts for AMR-WIND: $HOSTS_FOR_AMRWIND"

HOSTS_FOR_COLZA_START=$(printf ",%s" "${HOSTS[@]:$NUM_AMRWIND_HOSTS:$NUM_COLZA_HOSTS_MIN}")
HOSTS_FOR_COLZA_START=${HOSTS_FOR_COLZA_START:1}

print_log "Initial hosts for Colza: $HOSTS_FOR_COLZA_START"

extra_start=$((NUM_AMRWIND_HOSTS + NUM_COLZA_HOSTS_MIN))
HOSTS_FOR_COLZA_EXTRA=(${HOSTS[@]:$extra_start:$NUM_COLZA_HOSTS_MAX})

print_log "Extra hosts for Colza: ${HOSTS_FOR_COLZA_EXTRA[@]}"

HOSTS_FOR_SHUTDOWN="${HOSTS[0]}"

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
mpirun -hosts $HOSTS_FOR_COLZA_START -np $NUM_COLZA_HOSTS_MIN -env LD_PRELOAD $MPI_WRAPPERS \
       -outfile-pattern $BEDROCK_OUT \
       -errfile-pattern $BEDROCK_ERR \
    bedrock $PROTOCOL -c $BEDROCK_CONFIG -v trace &
BEDROCK_PID=$!

print_log "Waiting for SSG file to become available"
while [ ! -f $BEDROCK_SSG_FILE ]
do
    ensure_bedrock_is_alive
    sleep 1
done

ensure_bedrock_is_alive
print_log "Initial servers are ready"

print_log "Starting AMR-WIND"
AMR_WIND=$COLZA_EXP_PREFIX_PATH/amr-wind/bin/amr_wind
AMR_WIND_INPUT=$HERE/input/laptop_scale.damBreak.i
AMRWIND_OUT="amrwind.%r.out"
AMRWIND_ERR="amrwind.%r.err"

mpirun -hosts $HOSTS_FOR_AMRWIND -np $NUM_AMRWIND_HOSTS \
       -outfile-pattern $AMRWIND_OUT \
       -errfile-pattern $AMRWIND_ERR \
    $AMR_WIND $AMR_WIND_INPUT &
AMRWIND_PID=$!

N=$(($NUM_COLZA_HOSTS_MIN + 1))
M=$NUM_COLZA_HOSTS_MAX
S=$NUM_NEW_COLZA_PER_STEP
for K in $(seq $N $S $M)
do
    sleep $TIME_BETWEEN_INCREASES
    BEDROCK_OUT="bedrock.$K.%r.out"
    BEDROCK_ERR="bedrock.$K.%r.err"
    NEW_HOSTS_FOR_COLZA=$(printf ",%s" "${HOSTS_FOR_COLZA_EXTRA[@]:0:$S}")
    NEW_HOSTS_FOR_COLZA=${NEW_HOSTS_FOR_COLZA:1} # remove leading comma
    print_log "Adding $S new Colza server(s) on host(s) $NEW_HOSTS_FOR_COLZA"
    mpirun -hosts $NEW_HOSTS_FOR_COLZA -np $S -env LD_PRELOAD $MPI_WRAPPERS \
       -outfile-pattern $BEDROCK_OUT \
       -errfile-pattern $BEDROCK_ERR \
    bedrock $PROTOCOL -c $BEDROCK_CONFIG -v trace &
    for i in $(seq 1 $S)
    do
        unset HOSTS_FOR_COLZA_EXTRA[0]
    done
done

print_log "Waiting for AMR-WIND to complete"
wait $AMRWIND_PID

print_log "Shutting down servers"
mpirun -hosts $HOSTS_FOR_SHUTDOWN -np 1 bedrock-shutdown $PROTOCOL -s $BEDROCK_SSG_FILE

print_log "Terminating"
