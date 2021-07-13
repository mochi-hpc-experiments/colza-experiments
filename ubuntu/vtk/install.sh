#!/bin/bash

set -e

HERE=`dirname $0`
HERE=`realpath $HERE`
echo $HERE
source $HERE/settings.sh

SKIP_PARAVIEW=0  # skip installation of paraview
SKIP_SPACK=0     # skip installation of spack
SKIP_MOCHI=0     # skip installation of mochi repo
SKIP_COLZA=0     # skip installation of colza
SKIP_MINI_APPS=0 # skipp installation of mini-apps

while [[ $# -gt 0 ]]
do
    case $1 in
    --skip-paraview)
        SKIP_PARAVIEW=1
        shift
        ;;
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
    --skip-mini-apps)
        SKIP_MINI_APPS=1
        shift
        ;;
    *)
        echo "====> ERROR: unkwown argument $1"
        exit -1
        ;;
    esac
done

function install_paraview {
    echo "====> Installing dependencies needed by ParaView"
    spack env create paraview-env paraview.yaml
    spack env activate paraview-env
    spack install
    spack env deactivate
    spack env activate paraview-env
    PARAVIEW_SOURCE_PATH=$COLZA_EXP_SOURCE_PATH/paraview
    PARAVIEW_PREFIX_PATH=$COLZA_EXP_PREFIX_PATH/paraview
    # Checking if source is already there
    if [ -d "$PARAVIEW_PREFIX_PATH" ]
    then
        echo "====> ERROR: Paraview already installed in $PARAVIEW_PREFIX_PATH," \
             "please remove this folder or use --skip-paraview"
        exit -1
    fi
    # Cloning ParaView and checking out the correct commit
    if [ ! -d "$PARAVIEW_SOURCE_PATH" ];
    then
        echo "====> Clone ParaView"
        git clone https://gitlab.kitware.com/mdorier/paraview.git $PARAVIEW_SOURCE_PATH
    fi
    pushd $PARAVIEW_SOURCE_PATH
    echo "====> Checking out correct commit"
    git checkout $COLZA_EXP_PARAVIEW_COMMIT
    git submodule update --init --recursive
    echo "====> Building ParaView"
    # Creating build directory
    if [ -d build ];
    then
        echo "====> WARNING: $PARAVIEW_SOURCE_PATH/build directory already exists," \
             "please remove it if you want a clean build"
    else
        mkdir build
    fi
    # Going in build directory and calling cmake
    pushd build
    cmake .. -DPARAVIEW_USE_QT=OFF \
             -DPARAVIEW_USE_PYTHON=ON \
             -DPARAVIEW_USE_MPI=ON \
             -DVTK_OPENGL_HAS_OSMESA:BOOL=TRUE \
             -DVTK_USE_X:BOOL=FALSE \
             -DCMAKE_CXX_COMPILER=mpicxx \
             -DCMAKE_C_COMPILER=mpicc \
             -DVTK_PYTHON_OPTIONAL_LINK=OFF \
             -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_INSTALL_PREFIX=$PARAVIEW_PREFIX_PATH
    make -j 4
    make install
    popd # from build
    # ParaView doesn't install the IceT headers so we have to do it
    cp ThirdParty/IceT/vtkicet/src/include/*.h $PARAVIEW_PREFIX_PATH/include/paraview-5.8
    popd # from $PARAVIEW_SOURCE_PATH
    echo "====> Done building and installing ParaView"
}

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
        echo "====> Using spack version/commit/tag $COLZA_EXP_SPACK_VERSION"
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
        echo "====> Using latest commit of mochi-spack-packages"
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
    echo "====> Adding ParaView to spack environment"
    spack python -c "import spack.config; spack.config.set('packages:paraview', {'buildable': False, 'externals': [{'spec': 'paraview@develop-mochi', 'prefix': '$COLZA_EXP_PREFIX_PATH/paraview'}]})"
    echo "====> Installing"
    spack install
    spack env deactivate
}

function install_mini_apps {
    MINIAPP_SOURCE_PATH=$COLZA_EXP_SOURCE_PATH/mini-apps
    MINIAPP_PREFIX_PATH=$COLZA_EXP_PREFIX_PATH/mini-apps
    if [ -d $MINIAPP_PREFIX_PATH ]; then
        echo "====> ERROR: $MINIAPP_PREFIX_PATH already exists," \
             "please remove it or use --skip-mini-apps"
        exit -1
    fi
    if [ ! -d $MINIAPP_SOURCE_PATH ]; then
        echo "====> Cloning mini apps"
        git clone https://github.com/mochi-hpc-experiments/mona-vtk.git $MINIAPP_SOURCE_PATH
    fi
    echo "====> Building mini apps"
    spack env activate $COLZA_EXP_SPACK_ENV
    pushd $MINIAPP_SOURCE_PATH
    git checkout $COLZA_EXP_MINIAPPS_COMMIT
    if [ ! -d build ]; then
        mkdir build
    else
        echo "====> WARNING: $MINIAPP_SOURCE_PATH/build exists," \
             "remove it if you want a clean build"
    fi
    pushd build
    cmake .. \
        -DCMAKE_CXX_COMPILER=mpicxx \
        -DCMAKE_C_COMPILER=mpicc \
        -DVTK_DIR=$COLZA_EXP_PREFIX_PATH/paraview/lib64/cmake/paraview-5.8 \
        -DENABLE_EXAMPLE=ON \
        -DParaView_DIR=$COLZA_EXP_PREFIX_PATH/paraview/lib64/cmake/paraview-5.8 \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=$MINIAPP_PREFIX_PATH \
        -DENABLE_DAMARIS=ON \
        -DBOOST_ROOT=`spack location -i boost` \
	-DUSE_GNI=OFF
    make
    make install
    popd # build
    popd # $MINIAPP_SOURCE_PATH
    spack env deactivate
    echo "====> Done building and installing mini apps"
}

if [ "$SKIP_SPACK" -eq "0" ]; then
    install_spack
fi

if [ "$SKIP_MOCHI" -eq "0" ]; then
    install_mochi
fi

setup_spack

if [ "$SKIP_PARAVIEW" -eq "0" ]; then
    install_paraview
fi

if [ "$SKIP_COLZA" -eq "0" ]; then
    install_colza
fi

if [ "$SKIP_MINI_APPS" -eq "0" ]; then
    install_mini_apps
fi
