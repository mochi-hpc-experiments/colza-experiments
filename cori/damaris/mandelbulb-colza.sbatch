#!/bin/bash
#SBATCH --job-name=MB-Colza
#SBATCH --qos=debug
#SBATCH --time=10:00
#SBATCH --constraint=haswell
#SBATCH --output="mb-colza-%j.out"
#SBATCH --nodes 32

export MPICH_GNI_NDREG_ENTRIES=1024

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

METHOD=${1:-mona} # can be changed to mpi
CONFIG=mb-$METHOD-pipeline.json
CLIENT_NODES=16
CLIENT_PROCS=64
SERVER_NODES=$(( $SLURM_JOB_NUM_NODES-$CLIENT_NODES ))
SERVER_PROCS=$(( $SERVER_NODES*4 ))

STEP=6
PROTOCOL=gni
SSG_FILENAME=colza-$SLURM_JOB_ID.ssg
SSG_SWIM_PERIOD=5000
LOG_DIR=logs-$SLURM_JOB_ID
mkdir $LOG_DIR

BLOCKLENW=64
BLOCKLENH=64
BLOCKLEND=64
BLOCKNUM=2048

SERVERS_OUT_LOG=$LOG_DIR/mb-${METHOD}.servers.$SLURM_JOB_ID.out
CLIENTS_OUT_LOG=$LOG_DIR/mb-${METHOD}.clients.$SLURM_JOB_ID.out

export ABT_THREAD_STACKSIZE=2097152
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HERE/../vtk/sw/mini-apps/lib
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

print_log "Start clients on $CLIENT_NODES nodes / $CLIENT_PROCS processes"

srun -C haswell -N $CLIENT_NODES -n $CLIENT_PROCS -c 8 -l --cpu_bind=cores \
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

