#!/bin/bash
#SBATCH --job-name=ColzaSSG
#SBATCH --qos=regular
#SBATCH --time=04:00:00
#SBATCH --nodes=128
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell
#SBATCH --output="static-scaling-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

SSG_FILENAME=colza-$SLURM_JOB_ID.ssg

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

function run_instance () {
    NPROCS=$1
    WAITTIME=$2
    OUTFILE=static.$NPROCS.$SLURM_JOB_ID.out
    print_log "Starting staging area on $NPROCS processes"
    srun -n $NPROCS colza-dist-server \
              -a ofi+gni \
              -v trace \
              -s $SSG_FILENAME \
              -p 500 \
              -c $HERE/pipeline.json \
              -t 1 > $OUTFILE 2>&1 &
    SRUN_PID=$!
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Killing staging area"
    kill $SRUN_PID
    print_log "Waiting for staging area to shut down"
    wait $SRUN_PID
    print_log "Done!"
    rm $SSG_FILENAME
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/spack/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

for NPROCS in {1..127}
do
    run_instance $NPROCS 60
done
