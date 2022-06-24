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

## Running on a laptop

Simply run `./run-static.sh` to test your installation on a laptop.
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

This `run-static.sh` script will use the `input/laptop_scale.damBreak.i`
file as input for AMR-WIND. Down at the bottom of this file is where
AMR-WIND's Colza plugin is configured. There is no need to change anything
except the fields to send, should you want to use other Ascent actions
that require other fields.

## Running on a Linux cluster

We assume that you can run an MPI application on your Linux cluster
simply by using Mpich, which spack will have installed as part of
the installation process above, and using a file listing the available
hosts (potentially multiple times to have multiple processes per host).

To run the experiment on a Linux cluster, simply edit
the `hosts.txt` file to provide the host names available in your cluster.
You can then execute `./run-static.sh N M` where N is the number
of hosts to use for AMR-WIND, which will be taken from the beginning
of your `hosts.txt` file, and M is the number of hosts to use for
Colza, which will be taken from the remaining hosts in your `hosts.txt`
file.

Feel free to use a different input file for AMR-WIND to accomodate
for the scale. The previous section explained how to do that.
