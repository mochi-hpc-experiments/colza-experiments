# Comparison against Damaris

This set of experiments aims to compare Colza (with either an
MPI or a MoNA-based backend) against Damaris. It requires
the software to have been built in the `vtk` directory first.

These experiments run 16 client nodes with 4 clients per node
and 16 server nodes with 4 clients per node. Clients generate
a total of 2048 blocks (32 per client) of dimensions 128x128x128.

The same mandelbulb mini-app used in the vtk directory is used
here, using the same iso-contour rendering script for the
Catalyst pipeline.

## Running the Damaris-based experiment:

```
sbatch mandelbulb-damaris.sbatch
```

Timing information will be generated in a directory
named `logs-<jobid>`.

### Running the Colza-based experiments:

```
sbatch mandelbulb-colza.sbatch mona
sbatch mandelbulb-colza.sbatch mpi
```

Timing information will be generated in a directory
named `logs-<jobid>`.
