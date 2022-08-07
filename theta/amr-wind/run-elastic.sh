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

NUM_NODES=$COBALT_JOBSIZE
NUM_AMRWIND_PROCS=${1:-240}
NUM_AMRWIND_PROCS_PER_NODE=${2:-60}
NUM_AMRWIND_NODES=$(( $NUM_AMRWIND_PROCS/$NUM_AMRWIND_PROCS_PER_NODE ))
NUM_COLZA_PROCS_MIN=${3:-4}
NUM_COLZA_PROCS_MAX=${4:-16}
NUM_COLZA_PROCS_INCR=${5:-4}
NUM_COLZA_PROCS_PER_NODE=${6:-4}
NUM_COLZA_NODES_MIN=$(( $NUM_COLZA_PROCS_MIN/$NUM_COLZA_PROCS_PER_NODE ))
NUM_COLZA_NODES_MAX=$(( $NUM_COLZA_PROCS_MAX/$NUM_COLZA_PROCS_PER_NODE ))
TIME_BETWEEN_INCREASES=120

if (( $NUM_COLZA_NODES_MAX < $NUM_COLZA_NODES_MIN )); then
    print_log "ERROR: NUM_COLZA_NODES_MAX < NUM_COLZA_NODES_MIN"
    exit -1
fi
if (( $NUM_AMRWIND_NODES + $NUM_COLZA_NODES_MAX > $NUM_NODES )); then
    print_log "ERROR: Not enough hosts to run $NUM_AMRWIND_NODES AMR-WIND nodes and $NUM_COLZA_NODES_MAX Colza nodes"
    exit -1
fi
if (( $NUM_AMRWIND_PROCS < $NUM_COLZA_PROCS_MIN )); then
    print_log "ERROR: Cannot run with NUM_AMRWIND_PROCS ($NUM_AMRWIND_PROCS) < NUM_COLZA_PROCS_MIN ($NUM_COLZA_PROCS_MIN)"
    exit -1
fi

print_log "Activating environment"
source $HERE/settings.sh
source $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh
spack env activate $COLZA_EXP_SPACK_ENV

PDOMAIN="colzamdorier"
print_log "Setting up protection domain"
apstat -P | grep ${PDOMAIN} || apmgr pdomain -c -u ${PDOMAIN}

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

tee -a setup.txt <<END
NUM_NODES=$NUM_NODES
NUM_AMRWIND_PROCS=$NUM_AMRWIND_PROCS
NUM_AMRWIND_PROCS_PER_NODE=$NUM_AMRWIND_PROCS_PER_NODE
NUM_AMRWIND_NODES=$NUM_AMRWIND_NODES
NUM_COLZA_PROCS_MIN=$NUM_COLZA_PROCS_MIN
NUM_COLZA_PROCS_MAX=$NUM_COLZA_PROCS_MAX
NUM_COLZA_PROCS_INCR=$NUM_COLZA_PROCS_INCR
NUM_COLZA_PROCS_PER_NODE=$NUM_COLZA_PROCS_PER_NODE
NUM_COLZA_NODES_MIN=$NUM_COLZA_NODES_MIN
NUM_COLZA_NODES_MAX=$NUM_COLZA_NODES_MAX
END

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/sw/colza-ascent-pipeline/lib

print_log "Starting Bedrock daemon with initial number of Colza instances"
MPI_WRAPPERS=`spack location -i mochi-mona`/lib/libmona-mpi-wrappers.so
K=$NUM_COLZA_PROCS_MIN
aprun -cc none -n $NUM_COLZA_PROCS_MIN -N $NUM_COLZA_PROCS_PER_NODE -e LD_PRELOAD=$MPI_WRAPPERS -e OMP_NUM_THREADS=60 -p ${PDOMAIN} \
    bedrock $PROTOCOL -c $BEDROCK_CONFIG -v trace 1> $BEDROCK_OUT.$K 2> $BEDROCK_ERR.$K &
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
AMR_WIND_INPUT=$HERE/input/240_process_scale.damBreak.i

AMRWIND_OUT="amrwind.out"
AMRWIND_ERR="amrwind.err"

aprun -n $NUM_AMRWIND_PROCS -N $NUM_AMRWIND_PROCS_PER_NODE -cc none -e OMP_NUM_THREADS=1 -p $PDOMAIN \
    $AMR_WIND $AMR_WIND_INPUT 1> $AMRWIND_OUT 2> $AMRWIND_ERR &

N=$(($NUM_COLZA_PROCS_MIN + $NUM_COLZA_PROCS_INCR))
M=$NUM_COLZA_PROCS_MAX
S=$NUM_COLZA_PROCS_INCR
for K in $(seq $N $S $M)
do
    sleep $TIME_BETWEEN_INCREASES
    print_log "Adding $S new Colza server(s)"
    aprun -cc none -n $S -N $NUM_COLZA_PROCS_PER_NODE -e LD_PRELOAD=$MPI_WRAPPERS -e OMP_NUM_THREADS=60 -p $PDOMAIN \
        bedrock $PROTOCOL -c $BEDROCK_CONFIG -v trace 1> $BEDROCK_OUT.$K 2> $BEDROCK_ERR.$K &
done

print_log "Shutting down servers"
aprun -n 1 -N 1 -cc none -p $PDOMAIN bedrock-shutdown $PROTOCOL -s $BEDROCK_SSG_FILE

sleep 5 # other deleting protection domain will fail

print_log "Destroying protection domain"
apmgr pdomain -r -u ${PDOMAIN}

print_log "Terminating"
