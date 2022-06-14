# VTK-based Experiments

This folder contains an experiment that can run on a single
Linux workstation, using the Mandelbulb mini-app and a VTK-based pipeline.

Installing the dependencies can be done using the following command.

```
./install.sh
```

Running the example can be done as follows.

```
./mandelbulb.sh <method>
```

`<method>` may be either `mpi` or `mona`.

Because of the difficulty of setting up these kind of experiments
on various clusters, we provide this one as an example only, and
we did not attempt to fully convert the corresponding Cori
experiments.
