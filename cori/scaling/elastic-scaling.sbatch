#!/bin/bash
#SBATCH --job-name=ColzaSSG
#SBATCH --qos=regular
#SBATCH --time=02:00:00
#SBATCH --nodes=128
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell
#SBATCH --output="elastic-scaling-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

INCR=${1:-1}

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

SSG_FILENAME=colza-$SLURM_JOB_ID.ssg

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

function add_instance () {
    INSTANCE_NUMBER=$1
    WAITTIME=$2
    OUTFILE=elastic.$INSTANCE_NUMBER.$SLURM_JOB_ID.out
    print_log "Starting process $INSTANCE_NUMBER of staging area"
    if [ "$INSTANCE_NUMBER" -eq "1" ]; then
        JOIN=""
    else
        JOIN="-j"
    fi
    srun -n $INCR colza-dist-server $JOIN \
              -a ofi+gni \
              -v trace \
              -p 500 \
              -s $SSG_FILENAME \
              -c $HERE/pipeline.json \
              -t 1 > $OUTFILE 2>&1 &
    SRUN_PID=$!
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Done!"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/spack/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

for (( P=$INCR; P <= 127;  P=$P+$INCR ))
do
    add_instance $P 30
done

print_log "Shutting down the staging area"
srun -n 1 colza-dist-admin \
            -a ofi+gni \
            -v trace \
            -s $SSG_FILENAME \
            -x shutdown
print_log "Experiment complete"

print_log "Parsing results and creating CSV file"
python $HERE/parse-elastic.py $SLURM_JOB_ID > elastic-$SLURM_JOB_ID.csv

rm $SSG_FILENAME

print_log "Moving log files"
mkdir logs-$SLURM_JOB_ID
mv elastic.*.out logs-$SLURM_JOB_ID
