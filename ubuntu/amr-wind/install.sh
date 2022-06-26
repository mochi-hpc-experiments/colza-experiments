#!/bin/bash

set -e
export SPACK_DISABLE_LOCAL_CONFIG=true

HERE=`dirname $0`
HERE=`realpath $HERE`
source $HERE/settings.sh

SKIP_SPACK=0     # skip installation of spack
SKIP_MOCHI=0     # skip installation of mochi repo
SKIP_COLZA=0     # skip installation of colza
SKIP_AMRWIND=0   # skip installation of AMR-WIND
SKIP_PIPELINE=0  # skip installation of colza pipeline

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
    --skip-amr-wind)
        SKIP_AMRWIND=1
        shift
        ;;
    --skip-pipeline)
        SKIP_PIPELINE=1
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

function install_amr_wind {
    AMRWIND_SOURCE_PATH=$COLZA_EXP_SOURCE_PATH/amr-wind
    AMRWIND_PREFIX_PATH=$COLZA_EXP_PREFIX_PATH/amr-wind
    if [ -d $AMRWIND_PREFIX_PATH ]; then
        echo "====> ERROR: $AMRWIND_PREFIX_PATH already exists," \
             "please remove it or use --skip-amr-wind"
        exit -1
    fi
    if [ ! -d $AMRWIND_SOURCE_PATH ]; then
        echo "====> Cloning AMR-WIND"
        git clone --recursive https://github.com/mdorier/amr-wind.git $AMRWIND_SOURCE_PATH
    fi
    echo "====> Building AMR-WIND"
    spack env activate $COLZA_EXP_SPACK_ENV
    pushd $AMRWIND_SOURCE_PATH
    git checkout $COLZA_EXP_AMRWIND_COMMIT
    if [ ! -d build ]; then
        mkdir build
    else
        echo "====> WARNING: $AMRWIND_SOURCE_PATH/build exists," \
             "remove it if you want a clean build"
    fi
    pushd build
    cmake .. -DAMR_WIND_ENABLE_TESTS:BOOL=ON \
             -DAMR_WIND_ENABLE_ASCENT:BOOL=ON \
             -DAscent_DIR:PATH=`spack location -i ascent`/lib/cmake/ascent \
             -DConduit_DIR:PATH=`spack location -i conduit` \
             -DCMAKE_INSTALL_PREFIX:PATH=$AMRWIND_PREFIX_PATH \
             -DAMR_WIND_ENABLE_COLZA:BOOL=ON \
             -DAMR_WIND_ENABLE_MPI:BOOL=ON
    make
    make install
    spack env deactivate
    echo "====> Done building and installing AMR-WIND"
}

function install_pipeline {
    PIPELINE_SOURCE_PATH=$COLZA_EXP_SOURCE_PATH/colza-ascent-pipeline
    PIPELINE_PREFIX_PATH=$COLZA_EXP_PREFIX_PATH/colza-ascent-pipeline
    if [ -d $PIPELINE_PREFIX_PATH ]; then
        echo "====> ERROR: $PIPELINE_PREFIX_PATH already exists," \
             "please remove it or use --skip-pipeline"
        exit -1
    fi
    if [ ! -d $PIPELINE_SOURCE_PATH ]; then
        echo "====> Cloning colza-ascent-pipeline"
        git clone --recursive https://github.com/mochi-hpc-experiments/colza-ascent-pipeline.git $PIPELINE_SOURCE_PATH
    fi
    echo "====> Building Colza Ascent Pipeline"
    spack env activate $COLZA_EXP_SPACK_ENV
    pushd $PIPELINE_SOURCE_PATH
    git checkout $COLZA_EXP_PIPELINE_COMMIT
    if [ ! -d build ]; then
        mkdir build
    else
        echo "====> WARNING: $PIPELINE_SOURCE_PATH/build exists," \
             "remove it if you want a clean build"
    fi
    pushd build
    cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$PIPELINE_PREFIX_PATH
    make
    make install
    spack env deactivate
    echo "====> Done building and installing Ascent pipeline for Colza"
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

if [ "$SKIP_AMRWIND" -eq "0" ]; then
    install_amr_wind
fi

if [ "$SKIP_PIPELINE" -eq "0" ]; then
    install_pipeline
fi
