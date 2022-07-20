#!/bin/bash

# IMPORTANT: for portability, all the paths should be absolute.
# To make a path relative to the folder containing the install.sh
# script, use $HERE.

COLZA_EXP_SOURCE_PATH=$HERE/src # where sources will be downloaded
COLZA_EXP_PREFIX_PATH=$HERE/sw  # where software will be installed

# IMPT: override to use your protection domain on Theta
COLZA_PROTECTION_DOMAIN=srameshascent
# override if you want to use your own spack
COLZA_EXP_SPACK_LOCATION=$COLZA_EXP_PREFIX_PATH/spack
# override if you want to use another tag/version/commit of spack
COLZA_EXP_SPACK_VERSION="v0.18.0"
# override if you have mochi packages installed somewhere else
COLZA_EXP_MOCHI_LOCATION=$COLZA_EXP_PREFIX_PATH/mochi-spack-packages
# override if you want to use another commit of the mochi packages
COLZA_EXP_MOCHI_COMMIT=main
# override if you want to name the environment differently
COLZA_EXP_SPACK_ENV=colza-amr-wind-env
# override to use a different commit/tag/branch
COLZA_EXP_AMRWIND_COMMIT=c1531ecc7ccccef0956cb72e3461535375dbe4f6
# override to use a different commit/tag/branch
COLZA_EXP_PIPELINE_COMMIT=main
