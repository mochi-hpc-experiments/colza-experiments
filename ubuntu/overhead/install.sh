#!/bin/bash

set -e

HERE=`dirname $0`
HERE=`realpath $HERE`
echo $HERE
source $HERE/settings.sh

SKIP_SPACK=0     # skip installation of spack
SKIP_MOCHI=0     # skip installation of mochi repo
SKIP_COLZA=0     # skip installation of colza

while [[ $# -gt 0 ]]
do
    case $1 in
    --skip-spack)
        SKIP_SPACK=1
        shift
        ;;
    --skip-mochi)
        SKIP_MOCHI=1
        shift
        ;;
    --skip-colza)
        SKIP_COLZA=1
        shift
        ;;
    *)
        echo "====> ERROR: unkwown argument $1"
        exit -1
        ;;
    esac
done

function install_spack {
    # Checking if spack is already there
    if [ -d $COLZA_EXP_SPACK_LOCATION ];
    then
        echo "====> ERROR: spack is already installed in $COLZA_EXP_SPACK_LOCATION," \
             "please remove it or use --skip-spack"
        exit -1
    fi
    # Cloning spack and getting the correct release tag
    echo "====> Cloning Spack"
    git clone https://github.com/spack/spack.git $COLZA_EXP_SPACK_LOCATION
    if [ -z "$COLZA_EXP_SPACK_VERSION" ]; then
        echo "====> Using develop version of Spack"
    else
        echo "====> Using spack version/tag/commit $COLZA_EXP_SPACK_VERSION"
        pushd $COLZA_EXP_SPACK_LOCATION
        git checkout $COLZA_EXP_SPACK_VERSION
        popd
    fi
}

function setup_spack {
    echo "====> Setting up spack"
    . $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh
}

function install_mochi {
    if [ -d $COLZA_EXP_MOCHI_LOCATION ]; then
        echo "====> ERROR: Mochi already installed in $COLZA_EXP_MOCHI_LOCATION," \
             " please remove it or use --skip-mochi"
        exit -1
    fi
    echo "====> Cloning Mochi namespace"
    git clone https://github.com/mochi-hpc/mochi-spack-packages.git $COLZA_EXP_MOCHI_LOCATION
    if [ -z "$COLZA_EXP_MOCHI_COMMIT" ]; then
        echo "====> Using current commit of mochi-spack-packages"
    else
        echo "====> Using mochi-spack-packages at commit $COLZA_EXP_MOCHI_COMMIT"
        pushd $COLZA_EXP_MOCHI_LOCATION
        git checkout $COLZA_EXP_MOCHI_COMMIT
        popd
    fi
}

function install_colza {
    echo "====> Setting up Colza environment"
    spack env create $COLZA_EXP_SPACK_ENV $HERE/spack.yaml
    echo "====> Activating environment"
    spack env activate $COLZA_EXP_SPACK_ENV
    echo "====> Adding Mochi namespace"
    spack repo add --scope env:$COLZA_EXP_SPACK_ENV $COLZA_EXP_MOCHI_LOCATION
    echo "====> Installing"
    spack install
    spack env deactivate
}

if [ "$SKIP_SPACK" -eq "0" ]; then
    install_spack
fi

if [ "$SKIP_MOCHI" -eq "0" ]; then
    install_mochi
fi

setup_spack

if [ "$SKIP_COLZA" -eq "0" ]; then
    install_colza
fi
