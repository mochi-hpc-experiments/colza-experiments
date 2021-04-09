#!/bin/bash

# IMPORTANT: for portability, all the paths should be absolute.
# To make a path relative to the folder containing the install.sh
# script, use $HERE.

COLZA_EXP_SOURCE_PATH=$HERE/src # where sources will be downloaded
COLZA_EXP_PREFIX_PATH=$HERE/sw  # where software will be installed

# paraview will be installed in sw/paraview
# mini-apps will be installed in sw/mini-apps

# override if you want to use another commit of ParaView
# WARNING: these experiments require a modified ParaView,
#          not all the commits will work.
COLZA_EXP_PARAVIEW_COMMIT=ecb0a075f459c9db78bdd57bf83d715a99f0fe55
# override if you want to use your own spack
COLZA_EXP_SPACK_LOCATION=$COLZA_EXP_PREFIX_PATH/spack
# override if you want to use another tag/version/commit of spack
COLZA_EXP_SPACK_VERSION=51ac05483d7ea13abcf7f15741a8dfababcba62b
# override if you have mochi packages installed somewhere else
COLZA_EXP_MOCHI_LOCATION=$COLZA_EXP_PREFIX_PATH/mochi-packages
# override if you want to use another commit of the mochi packages
COLZA_EXP_MOCHI_COMMIT=53f65630ac79adbd92fffae51c7359d024439db5
# override if you want to name the environment differently
COLZA_EXP_SPACK_ENV=colza-env
# override if you want to use another commit/tag/branch
COLZA_EXP_MINIAPPS_COMMIT=cf0e6c49be1e761912022e2282334216c78b3272
