#!/bin/bash

HERE=`dirname $0`
HERE=`realpath $HERE`

source $HERE/settings.sh
source $COLZA_EXP_SPACK_LOCATION/share/spack/setup-env.sh
spack env activate $COLZA_EXP_SPACK_ENV
