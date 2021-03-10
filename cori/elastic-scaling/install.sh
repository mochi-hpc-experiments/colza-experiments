#!/bin/bash

set -e

echo "====> Cloning Spack"
git clone https://github.com/spack/spack.git

echo "====> Loading modules"
module swap PrgEnv-intel PrgEnv-gnu
module swap gcc/8.3.0 gcc/9.3.0
module load cmake/3.18.2

echo "====> Setting up spack"
. ./spack/share/spack/setup-env.sh

echo "====> Cloning Mochi namespace"
git clone https://xgitlab.cels.anl.gov/sds/sds-repo

echo "====> Adding Mochi namespace"
spack repo add sds-repo

echo "====> Setting up Colza environment"
spack env create colza-env spack.yaml
spack env activate colza-env
spack install
