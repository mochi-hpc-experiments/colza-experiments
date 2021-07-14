# Static vs. Elastic resizing experiment

This folder contains version of the corresponding [Cori scripts](../../cori/resizing)
but meant to run on a standard Linux cluster.

To install all the required software for this experiment,
run the following command.

```
./install.sh
```

To run the experiments, modify `nodes.txt` to provide a list of
host names, then run the following commands.

```
$ ./static-resizing.sh
$ ./elastic-resizing.sbatch
```
