# AMR-WIND experiments

This folder contains the necessary code to install and
run the experiments related to AMR-WIND, using Ascent
as in situ visualization backend.

## Installing

Simply call `./install.sh` to install all the necessary
software. This will create the `src` directory in which
some codes will be cloned, and the `sw` directory in which
they will be installed.

The whole process may take a while (around an hour on my
2-core Linux VM).

## Running on laptop

Simply run `./run-on-laptop.sh` to test the installation.
This script will start by creating a folder starting with `exp-`
to place output files. It will then deploy the Colza staging
area on 2 processes, then run the AMR-WIND application on 2
other processes for 20 iterations, before shutting down Colza.

Colza is deployed using Mochi's Bedrock bootstrapping system,
using the configuration file `config/config.json`. Down in this
file, in the configuration of the Colza provider, is a
`"comm_type": "mona"` option. This option can be changed to
`"mpi"` to use MPI instead of MoNA for communication. This
configuration file also points to the Ascent action file to
use for producing visualization, namely `../actions/default.yaml`
(paths are relative to the `exp-` directory from which the
 experiment is running).

This `run-on-laptop.sh` script will use the `input/laptop_scale.damBreak.i`
file as input for AMR-WIND. Down at the bottom of this file is where
AMR-WIND's Colza plugin is configured. There is no need to change anything
except the fields to send, should you want to use other Ascent actions
that require other fields.
