# VTK-based Experiments

This folder groups experiments that rely on the
Mandelbulb and Gray-Scott mini-apps and on VTK
pipelines.

## Installing the software

To install the required software, run the following command.

```
./install.sh
```

Contrary to the `install.sh` scripts from other folders,
this script will also install ParaView and the mini-apps.
The former will take several hours to build, so be patient!

## Communication evaluation

The `mandelbulb-strong.sbatch` and `mandelbulb-weak.sbatch`,
and the `gray-scott.sbatch`, aim to evaluate the execution
time of the pipeline with either an MPI-based communication
layer or a MoNA-based communication layer. These scripts
work as follows.

### mandelbulb-strong.sbatch

Submit the script as follows:

```
sbatch --nodes <N> mandelbulb-strong.sbatch <method> <width> <heigh> <depth>
```

`N` specifies the total number of nodes used for the job.
Since 16 nodes are used by the Mandelbulb application
(32 processes per node, for a total of 512 processes), `N-16`
are used to deploy Colza (using 4 processes per node).

The `method` should be either `mona` (default) or `mpi`,
and determins whether Colza will rely on MoNA or on MPI
for communication.

`width`, `height`, and `depth` correspond to the block dimensions
(2048 blocks will be produced in total by the application at
 every iteration). By default these values are 64, 64, and 128,
respectively. Our paper also uses `64x128x128` and `128x128x128`.

The job will generate a number of log files in a directory named `logs-<jobid>`.
The most important one is `mb-strong.client.<jobid>.out`, which lists
the timing of `execute` calls.

The job will also generate PNG images named `RenderView1_*.png` in the
current working directory.

TODO add python script to parse the result

## mandelbulb-weak.sbatch


