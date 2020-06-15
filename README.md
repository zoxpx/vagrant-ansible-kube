# Hybrid deployment of virtual Kubernetes cluster using Vagrant (virtualbox) and Ansible

This project installs customizded Kubernetes cluster:

* select number of nodes, also which OS to use on each individual node
* auto-downloads VM images
* select which container-runtime to use (one of docker-native, docker-latest, containerd or cri-o)

> ![#c5f015](https://placehold.it/15/c5f015/000000?text=+) **NOTE**:<br/> Each node in Kubernetes cluster can run a different OS and a different container-runtime.

## Prerequisites

Download and/or install the following packages on your host-system:

* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Setup

1) Edit the [Vagrantfile](Vagrantfile), and select node-names and OS-type to install:

```ruby
vm_nodes = {            # EDIT to specify VM node names, and their type (see #vm_conf below)
   'foo1' => 'bento16',
   'foo2' => 'bento16',
   'foo3' => 'bento16',
   'foo4' => 'centos7',
}
```

2) Start the VMs

```bash
vagrant up
```

> ![#c5f015](https://placehold.it/15/c5f015/000000?text=+) **NOTE**:<br/> Vagrant will automatically download the selected VM images.

3) Verify the network routing

```bash
make test
```

> ![#f03c15](https://placehold.it/15/f03c15/000000?text=+) **WARNING**</span>:<br/> Make sure none of the nodes are routing via `eth0` (`10.0.2.x`) VirtualBox NAT interface.

4) Edit auto-generated `.hosts` file to modify which container-runtime to deploy, i.e.:

```
foo1 	  # cri_runtime={docker|docker-ce|containerd|cri-o}
foo2 	  cri_runtime=docker-ce
foo3 	  cri_runtime=containerd
foo4 	  cri_runtime=cri-o
```

5) Deploy the Kubernetes via Ansible

```bash
make install
```

## Known limitations

* cluster will use only 1 K8s master-node
* VM images must use `eth#` network-interfaces notation
* VM nodes `eth0` configured to use NAT network (vagrant/virtualbox limitation)

## More information

* Kubernetes container-runtimes install instructions @ https://kubernetes.io/docs/setup/production-environment/container-runtimes/
