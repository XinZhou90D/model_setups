# awg_include

This awg_include reposiory contains the shared awg_include files to be
used in CMIP6 experiments.

## How to add

The awg_include repository should be included in a CMIP6 experiment
branch via the `git submodule` command.  A git submodule is a way to
add to a git repository another external repository.  A feature of git
submodule is to associate a single commit (or branch) to be used in
the main repository.  This allows the ability to have the submodule
repository tracked separately, without affecting the parent
repository.

To include this repository as a submodule run the following command.

```
git submodule add https://gitlab.gfdl.noaa.gov/CMIP6/awg_include.git awg_include
git submodule update --init --recursive 
```

This will create a `awg_include` directory, and assocate the head of the master
branch with the parent repository.

## How to update

The awg_include directory, once added as a submodule, will look and behave as
a git repository.  However, unless the submodule is explicitly updated in the parent
directory, any changes to awg_include (even if pushed to the gitlab repository) will not
change what is cloned (or checkedout later).

To update the submodule, and have the update available on the next
clone (or checkout), do the following.

1. Modify the awg_include directory, commit and push the changes back
to gitlab.
2. cd back to the parent directory of the parent repository.
3. Run `git add awg_include` followed by `git commit`.

## How to clone

Cloning is done similar to a normal clone.  However, the submodule
must be initialized.  This can be accomplished either by adding the
`-r` (`--recursive`) option to `git clone`, or calling `git submodule
update --init` after the clone.


