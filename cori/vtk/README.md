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
The former may take several hours to build, so be patient!

Note: the script installs dependencies in this order:
- Spack (clone in `sw`)
- Mochi (clone in `sw`)
- Spack environ,ent (installing Colza, ParaView, etc. in it)
- Mini-apps (clone in `src`, build, install in `sw`)

If you need to call the `install.sh` script again but some
of the steps have already been done, use
`--skip-spack`, `--skip-mochi`, `--skip-env`, or `--skip-miniapps`.

## Communication evaluation

These experiments compare MPI and MoNA when running visualization
pipelines for the Mandelbulb and Gray-Scott applications.

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

For every data size, the typical submissions we ran in evaluation
are (both for mona and mpi methods):

```
sbatch --nodes 17 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 18 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 20 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 24 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 32 mandelbulb-strong.sbatch mona 64 64 128
sbatch --nodes 48 mandelbulb-strong.sbatch mona 64 64 128
```

With the logs stored in `logs-<jobid>`, you will then need to run
`python3 parse-mb-exec-time.py logs-<jobid>` to extract key information
such as average execution time. And example of output:

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

This experiment is very similar to the previous one, but uses
an amount of data (and number of clients) that is proportional
to the number of staging servers.

The script can be submitted by this way:

```
sbatch --nodes <N> mandelbulb-weak.sbatch <method> <client nodes> <width> <heigh> <depth>
```

For example, if we submit:

```
sbatch --nodes 3 mandelbulb-weak.sbatch mona 2 64 64 128
```

We allocate 3 nodes. 1 node is used by staging area processes
(4 staging processes per node), 2 nodes are used by the
Mandelbulb application (32 processes per node).

We use `64x64x128`,`64x128x128`, and `128x128x128` as
block sizes for both mona and mpi methods. The job will also generates
PNG images named `RenderView1_*.png` in the current working directory.

For each block size, the typical submissions for our evaluation are
(both for mona and mpi methods):

```
sbatch --nodes 3 mandelbulb-weak.sbatch mona 2 64 64 128
sbatch --nodes 6 mandelbulb-weak.sbatch mona 4 64 64 128
sbatch --nodes 9 mandelbulb-weak.sbatch mona 8 64 64 128
sbatch --nodes 18 mandelbulb-weak.sbatch mona 16 64 64 128
sbatch --nodes 36 mandelbulb-weak.sbatch mona 32 64 64 128
```

If the directory containing log files is `logs-41453995`,
you may then run the same Python script as before to extract
relevant execution timings:

```
parse-mb-exec-time.py logs-41453995
```

### grayscott-strong.sbatch

This experiment uses the Gray-Scott application.
It can be submitted as follows:

```
sbatch --nodes <N> grayscott-strong.sbatch <method> <data len>
```

The method parameter can be the `mona` or `mpi`;
the `data len` represents the size of data domain.
Since the gray-scott simulation uses the cubic domian, we use one parameter here.

For exmaple, if we submit the job by this way:

```
sbatch --nodes 17 grayscott-strong.sbatch mona 408
```

We will assign 17 nodes. 16 of them are used for clients
(512 client processes in total), 1 node is used for
staging services (4 staging services in total).

The grid size is `408x408x408`. Each grid point contains a
double value, leading to 512MB of total data size per iteration.
Other configuration parameters of the simulation may be found in the
`gs-clientconfig-template.json` file, and can be edited as desired.
A new json file is created by `grayscott-strong.sbatch` based on
this template upon submission.

In the evaluation, we use grid length `408`, `512` and `646`.

The typical submissions are (both for `mona` and `mpi`):

```
sbatch --nodes 17 grayscott-strong.sbatch mona 408
sbatch --nodes 18 grayscott-strong.sbatch mona 408
sbatch --nodes 20 grayscott-strong.sbatch mona 408
sbatch --nodes 24 grayscott-strong.sbatch mona 408
sbatch --nodes 32 grayscott-strong.sbatch mona 408
sbatch --nodes 48 grayscott-strong.sbatch mona 408
```

Similarly, if the log dir is `logs-41462947`,
one can extract the execution time by using the `parse-mb-exec-time.py`
script as follows.

```
$ python3 parse-mb-exec-time.py logs-41462947
client_file:  logs-41462947/gs-strong.clients.41462947.out
  0: rank 0 execution time 58.11
  0: rank 0 execution time 46.7291
  0: rank 0 execution time 46.0243
  0: rank 0 execution time 44.6614
  0: rank 0 execution time 44.8602
  0: rank 0 execution time 43.9309
avg execution time without first step:
45.24118
```

# Elasticity experiment

## mandelbulb-elastic.sbatch

This experiment corresponds to the last experiment of out paper.
It allocates 24 nodes, and deploys the Mandelbulb application on
16 nodes with 16 processes per node, a single block per client
process, and a block size of `128x128x64`. It initially uses
2 nodes to run Colza, using 1 process per node, then adds a
new Colza node to the staging area, up to a total of 8 nodes,
every 60 seconds.

Again, this experiment creates a folder named `logs-<jobid>`
for its output files. The most important of these log files
is `logs-<jobid>/mandeldbulb.client.<jobid>.out`, which contains
timing information. The user can extract this information
in CSV format using the `parse-mb-elastic.py` Python script
as follows.

```
$ python parse-mb-elastic.py logs-12345678/mandelbulb.client.12345678.out
Iteration,Num Colza procs,start(sec),stage(sec),execute(sec),cleanup(sec)
1,2,0.000777721,0.813821,8.47251,0.000350714
2,2,0.000440598,0.126383,6.44897,0.0003438
3,2,0.000489712,0.121873,6.40546,0.000376463
...
```

The CSV data, print on stdout, contains for each iteration of
the Mandelbulb application the number of Colza processes used,
and the timings of start, stage, execute, and cleanup calls.

Note: a successful execution should result the Mandelbulb
application completing around 30 iterations, and most importantly
the last iterations are using 8 Colza servers. However, in some cases
the Mandelbulb application may hang indefinitely in a `start` call
and not complete its iterations. We are still in the processes of
tracking down this issue.
