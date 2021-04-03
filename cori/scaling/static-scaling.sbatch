#!/bin/bash
#SBATCH --job-name=ColzaSSG
#SBATCH --qos=regular
#SBATCH --time=01:00:00
#SBATCH --nodes=128
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell
#SBATCH --output="static-scaling-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

INCR=${1:-1}

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

SSG_FILENAME=colza-$SLURM_JOB_ID.ssg
DRC_CREDENTIAL_ID=-1

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
              -d $DRC_CREDENTIAL_ID \
              -t 1 > $OUTFILE 2>&1 &
    SRUN_PID=$!
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Killing staging area"
    kill $SRUN_PID
    print_log "Waiting for staging area to shut down"
    wait $SRUN_PID
    if [[ "$DRC_CREDENTIAL_ID" -eq "-1" ]]; then
        DRC_CREDENTIAL_ID=$(python find-drc-credential.py $OUTFILE)
        print_log "DRC credential changed to $DRC_CREDENTIAL_ID"
    fi
    print_log "Done!"
    rm $SSG_FILENAME
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/spack/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

for (( NPROCS=$INCR; NPROCS <= 127;  NPROCS=$NPROCS+$INCR ))
do
    run_instance $NPROCS 60
done

print_log "Experiment done"

print_log "Parsing results and creating CSV file"
python $HERE/parse-static.py static-scaling-$SLURM_JOB_ID.out logs-$SLURM_JOB_ID/*.out > static-$SLURM_JOB_ID.csv

print_log "Moving log files"
mkdir logs-$SLURM_JOB_ID
mv static.*.out logs-$SLURM_JOB_ID
