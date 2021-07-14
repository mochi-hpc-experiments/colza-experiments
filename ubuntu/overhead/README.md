Overhead of Two-Phase Commit
============================

This folder contains scripts to evaluate the overhead
of the two-phase commit (2PC) algorithm in Colza on a
standard Linux cluster. Please see the corresponding
[Cori experiment](../../cori/overhead) for more details.

To install all the required software for this experiment,
run the following command.

```
./install.sh
```

To run the experiment, edit the `nodes.txt` file to provide
a list of host names, then simply execute the following command.

```
./overhead.sh
```
