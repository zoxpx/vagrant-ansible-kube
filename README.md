# Hybrid deployment of virtual Kubernetes cluster using Vagrant (libvirt) and Ansible

This project installs customized Kubernetes cluster:

* customize how many nodes, and their OS type
* customize which container-runtime to use

> ![#c5f015](https://placehold.it/15/c5f015/000000?text=+) **NOTES**:<br/> Each node in Kubernetes cluster can run a different OS and a different container-runtime.<br/>
The VMs do not need to be preinstalled; instead, they will be downloaded and set up automatically by the `vagrant` utility.

## Prerequisites

1. Download and/or install the following packages on your host-system:

   * [libvirt](https://www.google.com/search?q=linux+install+libvirt)
   * [Vagrant](https://www.vagrantup.com/downloads.html)
   * [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

2. Install [libvirt vagrant provider](https://github.com/vagrant-libvirt/vagrant-libvirt#installation) plugin, and

3. Configure [bridge interface](https://www.google.com/search?q=linux+bridge+interface) as `br0` device on your host-system.

## Setup

1) Edit the [Vagrantfile](Vagrantfile), and select node-names and [VM/OS-type](https://app.vagrantup.com/boxes/search) to install:

```ruby
vm_nodes = {
   'foo1' => 'generic/ubuntu1604',
   'foo2' => 'centos/7',
   ...
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

> ![#f03c15](https://placehold.it/15/f03c15/000000?text=+) **WARNING**</span>:<br/> Make sure none of the nodes are routing via `eth0` vagrant NAT interface.

4) [*OPTIONAL*] Edit auto-generated `.hosts` file to modify which container-runtime to use (the default is *docker*):

```
foo1 	  # cri_runtime={docker|docker-ce|containerd|cri-o}
foo2 	  cri_runtime=docker-ce
foo3 	  cri_runtime=containerd
foo4 	  cri_runtime=cri-o
```

5) [*OPTIONAL*] Edit [vars/common.yaml](vars/common.yaml) and update software versions if required:

```yaml
k8s_version: 1.17.11
k8s_net: "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
crio_version: 1.17
etcd_version: 3.4.13
```

6) Deploy the Kubernetes via Ansible

```bash
make install
```

## Known limitations

* no HA; cluster will set up with only 1 Kubernetes master-node
* VM images **must** use `eth#` network-interfaces notation
* the container-runtime packages may not be available for all the platforms/distributions  (e.g. `cri-o` packages as provided by [openSUSE](https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/), or `docker` on CentOS/RHEL 8)

## More information

* Kubernetes container-runtimes install instructions @ https://kubernetes.io/docs/setup/production-environment/container-runtimes/
