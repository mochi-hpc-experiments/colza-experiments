# Static vs. Elastic scaling experiment

This folder contains two experiments aimed to run on the Cori supercomputer.
Each experiment will try to scale a staging area from 1 node all the way up
to 128 nodes, one node at a time. The first experiment, _static_, will do
so by deploying a staging area on N node, wait 30 seconds, then kill the
staging area before redeploying it on N+1 nodes. The second experiment,
_elastic_, will scale the staging area by adding processes one at a time
without shutting down the processes that are already running.

## Installing

This experiment is self-contained. The `install.sh` script will take care
of installing the Spack package manager, creating an environment, and
installing Colza and its dependencies in this environment. The `settings.sh`
file can be modified to change the location where Spack and Mochi will be
cloned, and the name of the environment. If spack already exists in the
specified directory, it will not be installed again. Hence, you may also
use this script with your own installation of spack (we do not however
guarantee reproducible experiments if you choose to do so).

## Running

The _static_ and elastic experiments can be run as follows.

```
$ sbatch static-scaling.sbatch
$ sbatch elastic-scaling.sbatch
```
