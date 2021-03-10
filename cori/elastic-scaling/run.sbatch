#!/bin/bash
#SBATCH --job-name=ColzaSSG
#SBATCH --qos=debug
#SBATCH --time=00:05:00
#SBATCH --nodes=2
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --constraint=haswell

export MPICH_GNI_NDREG_ENTRIES=1024

echo "====> Loading spack"
SPACK_PATH=$HOME/spack
. $SPACK_PATH/share/spack/setup-env.sh

echo "====> Loading spack environment"
spack env activate colza-env

export HG_LOG_LEVEL=DEBUG
echo "====> Running server"
srun -n 1 ../../build/examples/distributed/colza-dist-server \
	-a ofi+gni \
	-v trace \
	-s colza.ssg \
	-t 1 \
	-c pipeline.json > server.out &
X=$!

echo "====> Waiting 30 seconds"
sleep 30s

echo "====> Shutting down service"
srun -n 1 ../../build/examples/distributed/colza-dist-admin \
	-a ofi+gni \
	-s colza.ssg \
	-x shutdown > admin.out
echo "====> Shutdown call complete"

wait $X
echo "====> Job completed"
