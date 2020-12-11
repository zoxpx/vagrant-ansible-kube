# Standalone Ansible scripts

This directory contains various utility ansible scripts, that can be ran standalone via:

```bash
ansible-playbook -i .hosts --ssh-common-args "-F .ssh_conf" sa/myscript.yaml
```

## Overview of the scripts

[k8s_destroy.yaml](k8s_destroy.yaml)
> Wipes kubernetes installation off the nodes.

[salt.yaml](salt.yaml)
> Installs [Saltstack](https://en.wikipedia.org/wiki/Salt_(software)) clients on the nodes.
> It'll link the nodes with Salt-master on `70.0.0.65` (hardcoded).

[upgrade_all.yaml](upgrade_all.yaml)
> Runs system-update (i.e. `apt upgrade` / `yum upgrade`) on all the nodes, and reboots them .

[zox.yaml](zox.yaml)
> Sets up user-account for `zox` user, installing extra packages and setting up home-directory.

[hosts_fix.yaml](hosts_fix.yaml)
> Test script to update `/etc/hosts`
