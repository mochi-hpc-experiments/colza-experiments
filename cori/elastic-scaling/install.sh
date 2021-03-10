#!/bin/bash

set -e

HERE=`dirname $0`
source $HERE/settings.sh

if [ ! -d $COLZA_EXP_SPACK_LOCATION/spack ]; then
    echo "====> Cloning Spack"
    git clone https://github.com/spack/spack.git $COLZA_EXP_SPACK_LOCATION/spack
    if [ -z "$COLZA_EXP_SPACK_VERSION" ]; then
        echo "====> Using develop version of Spack"
    else
        echo "====> Using spack version $COLZA_EXP_SPACK_VERSION"
        pushd $COLZA_EXP_SPACK_LOCATION/spack
        git checkout tags/$COLZA_EXP_SPACK_VERSION
        popd
    fi
else
    echo "====> Using existing Spack installation"
fi

echo "====> Loading modules"
module swap PrgEnv-intel PrgEnv-gnu
module swap gcc/8.3.0 gcc/9.3.0
module load cmake/3.18.2

if ! [ -x "$(command -v spack)" ]; then
    echo "====> Setting up spack"
    . $COLZA_EXP_SPACK_LOCATION/spack/share/spack/setup-env.sh
else
    echo "====> Spack is already available on the command line"
fi

if [ ! -d $COLZA_EXP_MOCHI_LOCATION/sds-repo ]; then
    echo "====> Cloning Mochi namespace"
    git clone https://xgitlab.cels.anl.gov/sds/sds-repo $COLZA_EXP_MOCHI_LOCATION/mochi-packages
else
    echo "====> Using existing Mochi package repository"
fi

echo "====> Adding Mochi namespace"
spack repo add $COLZA_EXP_MOCHI_LOCATION/mochi-packages

echo "====> Setting up Colza environment"
spack env create $COLZA_EXP_SPACK_ENV $HERE/spack.yaml
spack env activate $COLZA_EXP_SPACK_ENV
spack install
