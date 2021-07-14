# Comparison against Damaris

This set of experiments aims to compare Colza (with either an
MPI or a MoNA-based backend) against Damaris. It requires
the software to have been built in the `vtk` directory first.

These experiments have been setup to run on 4 processes in a single
Linux workstation.

## Running the Damaris-based experiment:

```
./mandelbulb-damaris.sh
```

### Running the Colza-based experiments:

```
./mandelbulb-colza.sh mona
./mandelbulb-colza.sh mpi
```
