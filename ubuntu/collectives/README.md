# Collectives benchmarking

This folder contains scripts to install and run the collective
benchmarking experiments described [here](../../cori/collectives),
but on a traditional Linux workstation.

To install the required software, execute the following command.

```
./install.sh
```

To run on a Linux cluster, you must first edit the `nodes.txt`
file to provide a list of nodes. This list will be used by `mpirun`
to deploy the programs. You may then execute the experiments as follows.

```
./allreduce-benchmark.sh
./send-recv-benchmark.sh
```
