# Collectives benchmarking

This folder contains experiments that aim to compare MPI and MoNA
for two types of communication patterns: send/recv, and allreduce.

## Installing the required software

Run the following command.
```
./install.sh
```

## Running the benchmarks

Run the following commands.

```
sbatch allreduce-benchmark.sbatch
sbatch send-recv-benchmark.sbatch
```

The Allreduce benchmark will run on 32 nodes (1 process per node).
The Send/recv benchmark will run on 2 nodes (1 process per node).
Both scripts will run 10000 operations, using MoNA and MPI, and
reporting timing. They will output in files in a directory named
`logs-<jobid>`. The allreduce benchmark uses a binary XOR as the
reduce operation.
