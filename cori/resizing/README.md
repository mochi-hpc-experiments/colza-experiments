# Static vs. Elastic scaling experiment

This folder contains two experiments aimed to run on the Cori supercomputer.
Each experiment will try to resize a staging area from 1 node all the way up
to 127 nodes, one node at a time. The first experiment, _static_, will do
so by deploying a staging area on N node, wait 30 seconds, then kill the
staging area before redeploying it on N+1 nodes. The second experiment,
_elastic_, will scale the staging area by adding processes one at a time
without shutting down the processes that are already running.

## Installing

To install all the required software for this experiment,
run the following command.

```
./install.sh
```

This command will install Spack, the Mochi packages, then
create an environment in Spack and install Colza and its
dependencies in it.

This script will look at `settings.sh` to use specific
commits of Spack and the Mochi packages, so as to reproduce
the experiments with exactly the same software as originally used.

## Running

The _static_ and _elastic_ experiments can be run as follows.

```
$ sbatch static-scaling.sbatch
$ sbatch elastic-scaling.sbatch
```

While this was not evaluated our paper, you can also add processes
X by X (instead of 1 by 1) by calling these scripts as follows.

```
$ sbatch static-scaling.sbatch X
$ sbatch elastic-scaling.sbatch X
```

Both scripts will create a directory called `logs-<jobid>` to
store their output files. They will also finish by calling
their respective Python script (`parse-static.py` and `parse-elastic.py`)
to produce a final CSV file with the results in the current working directory.
The first column of this CSV file corresponds to the size of the staging
area. The second column corresponds to the time required (in seconds) to add
a new process (or multiple process, if specified) to the staging area to
reach that size from the previous deployment.

Note: occasionally the last command of the `elastic` script may
fail to properly shut down the staging area, leaving the script
hanging before the Python script is called. If this happens, you may
kill the job, manually move its output file (`elastic-scaling-<jobid>.out`)
to the `logs-<jobid>` directory (where other output files are stored),
then manually run call `python parse-elastic.py logs-<jobid>/*.out`
to produce the CSV data on your standard output.
