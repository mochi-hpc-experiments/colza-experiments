#!/bin/bash
#COBALT -A radix-io
#COBALT -t 1:00:00
#COBALT --mode script
#COBALT -n 8
#COBALT -q debug-flat-quad
#COBALT --attrs filesystems=home,grand,eagle,theta-fs0

export MPICH_GNI_NDREG_ENTRIES=1024

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG" | tee -a $MAIN_LOG
}

HERE=`dirname $0`
HERE=`realpath $HERE`

NUM_HOSTS=${COBALT_JOBSIZE}

NUM_AMRWIND_HOSTS=4
NUM_COLZA_HOSTS_MIN=1
NUM_COLZA_HOSTS_MAX=4
NUM_NEW_COLZA_PER_STEP=4 #Change this if required
TIME_BETWEEN_INCREASES=300

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

print_log "Activating environment"
source $HERE/settings.sh
source $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh
spack env activate $COLZA_EXP_SPACK_ENV

print_log "Setting up protection domain"
apstat -P | grep ${COLZA_PROTECTION_DOMAIN} || apmgr pdomain -c -u ${COLZA_PROTECTION_DOMAIN}

PROTOCOL=ofi+gni

BEDROCK_CONFIG=$HERE/config/config.json
BEDROCK_OUT="bedrock.out"
BEDROCK_ERR="bedrock.err"
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
export AMS_WORKING_DIR=/home/sramesh/MOCHI/colza-experiments/theta/amr-wind #Change this
export AMS_ACTIONS_FILE=/home/sramesh/MOCHI/colza-experiments/theta/amr-wind/actions/default.yaml #Change this
cd $exp_dir

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/sw/colza-ascent-pipeline/lib

print_log "Starting Bedrock daemon"
COLZA_NUM_PROCS_MIN=4 #Change this if required
COLZA_NUM_PROCS_PER_NODE=4 #Change this if required
MPI_WRAPPERS=`spack location -i mochi-mona`/lib/libmona-mpi-wrappers.so
aprun -cc none -n $COLZA_NUM_PROCS_MIN -N $COLZA_NUM_PROCS_PER_NODE -e LD_PRELOAD=$MPI_WRAPPERS -p ${COLZA_PROTECTION_DOMAIN} \
    bedrock $PROTOCOL -c $BEDROCK_CONFIG -v trace 1> $BEDROCK_OUT 2> $BEDROCK_ERR &
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
AMR_WIND_INPUT=$HERE/input/240_process_scale.damBreak.i
AMR_WIND_NUM_PROCS=240 #Change this if required
AMR_WIND_NUM_PROCS_PER_NODE=60 #Change this if required

aprun -n $AMR_WIND_NUM_PROCS -N $AMR_WIND_NUM_PROCS_PER_NODE -cc none -p $COLZA_PROTECTION_DOMAIN $AMR_WIND $AMR_WIND_INPUT &

print_log "Ready for elastic expansion" 

N=$(($NUM_COLZA_HOSTS_MIN + 1))
M=$NUM_COLZA_HOSTS_MAX
S=$NUM_NEW_COLZA_PER_STEP
for K in $(seq $N 1 $M)
do
    sleep $TIME_BETWEEN_INCREASES
    print_log "Adding $S new Colza server(s)"
    aprun -cc none -n $S -N $COLZA_NUM_PROCS_PER_NODE -e LD_PRELOAD=$MPI_WRAPPERS -p ${COLZA_PROTECTION_DOMAIN} \
        bedrock $PROTOCOL -c $BEDROCK_CONFIG -v trace 1> $BEDROCK_OUT 2> $BEDROCK_ERR &
done

wait

print_log "Shutting down servers"
aprun -n 1 -N 1 -cc none -p $COLZA_PROTECTION_DOMAIN bedrock-shutdown $PROTOCOL -s $BEDROCK_SSG_FILE

print_log "Destroying protection domain"
apmgr pdomain -r -u ${COLZA_PROTECTION_DOMAIN}

print_log "Terminating"
