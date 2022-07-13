#!/bin/bash
#COBALT -A radix-io
#COBALT -t 0:10:00
#COBALT --mode script
#COBALT -n 4
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

NUM_HOSTS=$COBALT_JOBSIZE
NUM_AMRWIND_HOSTS=${1:-2}
NUM_COLZA_HOSTS=${2:-2}

if (( $NUM_AMRWIND_HOSTS + $NUM_COLZA_HOSTS > $NUM_HOSTS )); then
    print_log "ERROR: Not enough hosts to run $NUM_AMRWIND_HOSTS AMR-WIND processes and $NUM_COLZA_HOSTS Colza processes"
    exit -1
fi
if (( $NUM_AMRWIND_HOSTS < $NUM_COLZA_HOSTS )); then
    print_log "ERROR: Cannot run with NUM_AMRWIND_HOSTS ($NUM_AMRWIND_HOSTS) < NUM_COLZA_HOSTS ($NUM_COLZA_HOSTS)"
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
cd $exp_dir

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/sw/colza-ascent-pipeline/lib

print_log "Starting Bedrock daemon"
MPI_WRAPPERS=`spack location -i mochi-mona`/lib/libmona-mpi-wrappers.so
aprun -cc none -n $NUM_COLZA_HOSTS -N 1 -e LD_PRELOAD=$MPI_WRAPPERS -p ${COLZA_PROTECTION_DOMAIN} \
    bedrock $PROTOCOL -c $BEDROCK_CONFIG -v trace 1> $BEDROCK_OUT 2> $BEDROCK_ERR &
BEDROCK_PID=$!

print_log "Waiting for SSG file to become available"
while [ ! -f $BEDROCK_SSG_FILE ]
do
    ensure_bedrock_is_alive
    sleep 1
done
sleep 1

ensure_bedrock_is_alive
print_log "Servers are ready"

print_log "Starting AMR-WIND"
AMR_WIND=$COLZA_EXP_PREFIX_PATH/amr-wind/bin/amr_wind
AMR_WIND_INPUT=$HERE/input/laptop_scale.damBreak.i

aprun -n $NUM_AMRWIND_HOSTS -N 1 -cc none -p $COLZA_PROTECTION_DOMAIN $AMR_WIND $AMR_WIND_INPUT

print_log "Shutting down servers"
aprun -n 1 -N 1 -cc none -p $COLZA_PROTECTION_DOMAIN bedrock-shutdown $PROTOCOL -s $BEDROCK_SSG_FILE

print_log "Destroying protection domain"
apmgr pdomain -r -u ${COLZA_PROTECTION_DOMAIN}

print_log "Terminating"
