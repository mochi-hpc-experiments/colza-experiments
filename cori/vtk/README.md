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

For every data size, the typical scipts we run for evaluation are (both for mona and mpi methods):

```
sbatch --nodes 17 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 18 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 20 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 24 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 32 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 48 mandelbulb-strong.sbatch mona 64 64 128
```

If the dir name for log is `logs-41455589` , we can run `python3 parse-mb-exec-time.py logs-41455589` to extract key information such as average execution time by this way:

```
client_file:  logs-41455589/mb-strong.clients.41455589.out
  0: rank 0 execution time 28.617
  0: rank 0 execution time 19.8865
  0: rank 0 execution time 16.4469
  0: rank 0 execution time 16.2823
  0: rank 0 execution time 16.0782
  0: rank 0 execution time 16.6688
avg execution time without first step:
17.07254
```

## mandelbulb-weak.sbatch

For the weak scale experiment, we need to make sure there is fixed proportion of data size to the staging services.

The script can be submitted by this way:

```
sbatch --nodes <N> mandelbulb-weak.sbatch <method> <client nodes> <width> <heigh> <depth>
```

For example, if we submit job:

```
sbatch --nodes 3 mandelbulb-weak.sbatch mona 2 64 64 128
```

We assign 3 nodes, 1 node is used as staging processes (4 staging processes per node), 2 nodes of them are used for clients (32 processes per node).

We use `64*64*128`,`64*128*128`, and `128*128*128` as the data block size for both mona and mpi methods. 

For each block size, the typical scripts for evaluation are (both for mona and mpi methods):

```
sbatch --nodes 3 mandelbulb-weak.sbatch mona 2 64 64 128
sbatch --nodes 6 mandelbulb-weak.sbatch mona 4 64 64 128
sbatch --nodes 9 mandelbulb-weak.sbatch mona 8 64 64 128
sbatch --nodes 18 mandelbulb-weak.sbatch mona 16 64 64 128
sbatch --nodes 36 mandelbulb-weak.sbatch mona 32 64 64 128
```

The similar PNG images named `RenderView1_*.png` will be generated in the
current working directory.

If the dir name for log is `logs-41453995` , we can run

```
parse-mb-exec-time.py logs-41453995
```

this script can extract the key log messages and cacualte the average execution time as follows:

```
client_file:  logs-41453995/mb-weak.clients.41453995.out
 0: rank 0 execution time 10.863
 0: rank 0 execution time 4.74145
 0: rank 0 execution time 2.47949
 0: rank 0 execution time 2.3503
 0: rank 0 execution time 2.36547
 0: rank 0 execution time 2.32615
avg execution time without first step:
2.852572
```