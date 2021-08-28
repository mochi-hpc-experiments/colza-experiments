#!/bin/bash

# IMPORTANT: for portability, all the paths should be absolute.
# To make a path relative to the folder containing the install.sh
# script, use $HERE.

COLZA_EXP_SOURCE_PATH=$HERE/src # where sources will be downloaded
COLZA_EXP_PREFIX_PATH=$HERE/sw  # where software will be installed

# override if you want to use your own spack
COLZA_EXP_SPACK_LOCATION=$COLZA_EXP_PREFIX_PATH/spack
# override if you want to use another tag/version/commit of spack
COLZA_EXP_SPACK_VERSION=1113705080f8acb1634325b2fcdd0998d75a96fd
# override if you have mochi packages installed somewhere else
COLZA_EXP_MOCHI_LOCATION=$COLZA_EXP_PREFIX_PATH/mochi-spack-packages
# override if you want to use another commit of the mochi packages
#COLZA_EXP_MOCHI_COMMIT=e36cb19adaf4e765538f4066937e2f8321f2d655
COLZA_EXP_MOCHI_COMMIT=main
# override if you want to name the environment differently
COLZA_EXP_SPACK_ENV=colza-env
# override if you want to use another commit/tag/branch
#COLZA_EXP_MINIAPPS_COMMIT=f93bbe8b8236df415310148174f5196dffee071a
COLZA_EXP_MINIAPPS_COMMIT=dev-deep-water-impact
