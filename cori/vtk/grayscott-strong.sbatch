#!/bin/bash
#SBATCH --job-name=GS-Strong
#SBATCH --qos=debug
#SBATCH --time=10:00
#SBATCH --constraint=haswell
#SBATCH --output="gs-strong-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

HERE=$SLURM_SUBMIT_DIR
# add necessary envs
source $HERE/settings.sh

METHOD=${1:-mona} # can be changed to mpi
BLOCKLEN=${2:-408}

CLIENT_NODES=16
CLIENT_PROCS=512
SERVER_NODES=$(( $SLURM_JOB_NUM_NODES-$CLIENT_NODES ))
SERVER_PROCS=$(( $SERVER_NODES*4 ))

export SRCDIR=$COLZA_EXP_SOURCE_PATH/mini-apps
SERVER_CONFIG=gs-$METHOD-pipeline.json

PROTOCOL=gni
SSG_FILENAME=colza-$SLURM_JOB_ID.ssg
SSG_SWIM_PERIOD=5000

# generate client config
sed "s/LEN/${BLOCKLEN}/g;s/SSGFILE/${SSG_FILENAME}/g;s/PROTOCOL/${PROTOCOL}/g" gs-clientconfig-template.json > gs-clientconfig-${METHOD}-${BLOCKLEN}-${SSG_FILENAME}.json
CLIENT_CONFIG=gs-clientconfig-${METHOD}-${BLOCKLEN}-${SSG_FILENAME}.json

LOG_DIR=logs-$SLURM_JOB_ID
mkdir $LOG_DIR
SERVERS_OUT_LOG=$LOG_DIR/gs-strong.servers.$SLURM_JOB_ID.out
CLIENTS_OUT_LOG=$LOG_DIR/gs-strong.clients.$SLURM_JOB_ID.out

export ABT_THREAD_STACKSIZE=2097152
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/sw/mini-apps/lib
export LD_LIBRARY_PATH=/global/common/sw/cray-sles15-x86_64/gcc-8.2.0/mesa-18.3.6-qozjngg/lib:$LD_LIBRARY_PATH

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

print_log "Staring servers on $SERVER_NODES nodes / $SERVER_PROCS processes"

srun -C haswell -N $SERVER_NODES -n $SERVER_PROCS -c 8 -l --cpu_bind=cores \
    $HERE/sw/mini-apps/bin/example/GrayScottColza/gsserver \
    -a $PROTOCOL \
    -s $SSG_FILENAME \
    -c $SERVER_CONFIG -t 1 &> $SERVERS_OUT_LOG &
COLZA_PID=$!
print_log "Waiting for all the servers processes to start"

servers_ready=0
while [ $servers_ready -ne $SERVER_PROCS ]
do
    servers_ready=$(cat $SERVERS_OUT_LOG | grep "Server running at" | wc -l)
    sleep 1
    print_log "$servers_ready servers are ready"
done

print_log "Start clients on $CLIENT_NODES nodes / $CLIENT_PROCS processes"

srun -C haswell -N $CLIENT_NODES -n $CLIENT_PROCS -c 2 -l --cpu_bind=cores \
    $HERE/sw/mini-apps/bin/example/GrayScottColza/gsclient $CLIENT_CONFIG &> $CLIENTS_OUT_LOG

print_log "Client done"
kill $COLZA_PID
print_log "All done!"

