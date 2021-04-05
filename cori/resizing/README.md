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

The _static_ and _elastic_ experiments can be run as follows.

```
$ sbatch static-scaling.sbatch
$ sbatch elastic-scaling.sbatch
```

## Analyzing

The static experiment will produce a log file named `static-scaling-<jobid>.out`
as well as a list of 127 files named `static.<scale>.<jobid>.out` where `<scale>`
is the number of processes deployed. Running `python parse-static.py <jobid>`
will produce CSV data on the standard output. The first column corresponds to
the scale at which the staging area was deploy. The second column corresponds
to the time required (in seconds) to go from a staging area with one fewer
node to the current scale (i.e. the time from killing the previous staging area
to having the new one deployed and ready to accept work).

The elastic experiment will produce a log file named `elastic-scaling-<jobid>.out`
as well as a list of 127 files named `elastic.<proc>.<jobid>.out`. Contrary to
the files produced by the static experiments, each such file here corresponds to
the log file of a single process throughout the full experiment (since process
are not killed). Running `python parse-elastic.py <jobid>` will produce CSV data
on the standard output. The first column corresponds to the scale of the staging
area. The second column corresponds to the time required (in seconds) to add
a new process to the staging area to reach that scale from a scale with one fewer
process.
