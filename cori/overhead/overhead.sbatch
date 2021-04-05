#!/bin/bash
#SBATCH --job-name=ColzaOverhead
#SBATCH --qos=debug
#SBATCH --time=00:30:00
#SBATCH --nodes=64
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell
#SBATCH --output="overhead-job-%j.out"

export MPICH_GNI_NDREG_ENTRIES=1024

INCR=${1:-1}
START=${2:-${INCR}}

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
    CREATE_GROUP=$3
    WAITTIME=$2
    OUTFILE=overhead.$INSTANCE_NUMBER.$SLURM_JOB_ID.out
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
    SRUN_PID=$!
    print_log "Waiting $WAITTIME seconds"
    sleep $WAITTIME
    print_log "Done!"
}

print_log "Loading spack"
. $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh

print_log "Loading spack environment"
spack env activate $COLZA_EXP_SPACK_ENV

print_log "Starting first server instance"
add_instance 1 30 1

print_log "Starting client"
srun -n 1 colza-dist-client \
            -a ofi+gni \
            -v trace \
            -s $SSG_FILENAME \
            -p abc \
            -i 10000 \
            --no-execute \
            --no-stage \
            -w 1 > overhead.client.$SLURM_JOB_ID.out 2>&1 &
CLIENT_PID=$!

sleep 15
print_log "Starting more servers"

for (( P=$START+$INCR; P <= 63;  P=$P+$INCR ))
do
    add_instance $P 15 0
done

print_log "Killing client"
kill $CLIENT_PID

print_log "Shutting down the staging area"
srun -n 1 colza-dist-admin \
            -a ofi+gni \
            -v trace \
            -s $SSG_FILENAME \
            -x shutdown
print_log "Experiment complete"

rm $SSG_FILENAME

print_log "Moving log files"
mkdir logs-$SLURM_JOB_ID
mv overhead*$SLURM_JOB_ID.out logs-$SLURM_JOB_ID

print_log "Parsing results and creating CSV file"
python $HERE/parse-logs.py \
    logs-$SLURM_JOB_ID/overhead.client.$SLURM_JOB_ID.out \
    > overhead-$SLURM_JOB_ID.csv

print_log "All done!"
