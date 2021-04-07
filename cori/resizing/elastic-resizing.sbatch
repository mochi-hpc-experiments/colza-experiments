#!/bin/bash
#SBATCH --job-name=ColzaSSG
#SBATCH --qos=regular
#SBATCH --time=02:00:00
#SBATCH --nodes=128
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell
#SBATCH --output="elastic-resizing-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

INCR=${1:-1}
START=${2:-${INCR}}

HERE=$SLURM_SUBMIT_DIR
source $HERE/settings.sh

SSG_FILENAME=colza-$SLURM_JOB_ID.ssg
LOG_DIR=logs-$SLURM_JOB_ID
mkdir $LOG_DIR

function print_log() {
    MSG=$1
    NOW=`date +"%Y-%m-%d %T.%N"`
    echo "[$NOW] $MSG"
}

function add_instance () {
    INSTANCE_NUMBER=$1
    CREATE_GROUP=$3
    WAITTIME=$2
    OUTFILE=$JOB_DIR/elastic.$INSTANCE_NUMBER.$SLURM_JOB_ID.out
    print_log "Starting process $INSTANCE_NUMBER of staging area"
    NP=$INCR
    if [ "$CREATE_GROUP" -eq "1" ]; then
        JOIN=""
        NP=$START
    else
        JOIN="-j"
    fi
    srun -n $NP colza-dist-server $JOIN \
              -a ofi+gni \
              -v trace \
              -p 500 \
              -s $SSG_FILENAME \
              -c $HERE/pipeline.json \
              -t 1 > $OUTFILE 2>&1 &
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Done!"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

CREATE_GROUP=1 # first call must create the group

for (( P=$START; P <= 127;  P=$P+$INCR ))
do
    add_instance $P 60 $CREATE_GROUP
    CREATE_GROUP=0
done

print_log "Shutting down the staging area"
srun -n 1 colza-dist-admin \
            -a ofi+gni \
            -v trace \
            -s $SSG_FILENAME \
            -x shutdown
print_log "Experiment complete"

rm $SSG_FILENAME

print_log "Moving log files"
mv elastic-resizing-$SLURM_JOB_ID.out $LOG_DIR

print_log "Parsing results and creating CSV file"
python $HERE/parse-elastic.py $LOG_DIR/* > elastic-$SLURM_JOB_ID.csv

