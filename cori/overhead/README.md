Overhead of Two-Phase Commit
============================

This folder contains scripts to evaluate the overhead
of the two-phase commit (2PC) algorithm in Colza. The
experiment consists of deploying 1 server, then 1 client
doing start/cleanup call in a loop, waiting 1 second
between each call, then add a new server every second
up to 63 servers.

Installing
==========

To install all the required software for this experiment,
run the following command.

```
./install.sh
```

This command will install Spack, the Mochi packages, then
create an environment in Spack and install Colza and its
dependencies in it.

Running
=======

To run the experiment, simply run the following command.

```
sbatch overhead.sbatch
```

Once the job has completed, you will find a file named
`overhead-<jobid>.csv` containing the results. The complete
set of log files from the job is located in a folder
named `logs-<jobid>`.

Files
=====

This folder contains the following files.
- `settings.sh`: contains environment variables to control
  where and how the software is installed;
- `spack.yaml`: contains a description of the Spack environment
  to setup and install;
- `install.sh`: install the software required to run the experiment;
- `overhead.sbatch`: job script to submit to the SLURM job scheduler;
- `parse-logs.py`: python script that processes the log files and
  produces the final CSV file (called automatically at the end of
  the job).
- pipeline.json
