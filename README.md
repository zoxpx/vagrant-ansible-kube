# Hybrid deployment of virtual Kubernetes cluster using Vagrant (libvirt) and Ansible

This project installs customized Kubernetes cluster, where each node can run a different OS, and a different [container-runtime](https://kubernetes.io/docs/setup/production-environment/container-runtimes/).

## Introduction

### Why yet another Kubernetes installer?

_"There are already plenty of install methods for Kubernetes clusters, so why should I use this one?"_

It is true that there is already plenty of Kubernetes install procedures.
This one is different, because:

* it will install and set up Virtual Machines, as well as install Kubernetes cluster on them,
* one can easily customize both node's OS, as well as the container runtime, and finally
* VMs do not need to be preinstalled; instead, they will be downloaded and set up automatically by the `vagrant` utility.

Example:

```
# kubectl get nodes -o wide
NAME   STATUS   ROLES ...   OS-IMAGE                KERNEL-VERSION                 CONTAINER-RUNTIME
foo1   Ready    master...   Ubuntu 16.04.7 LTS      4.4.0-193-generic              docker://18.9.7
foo2   Ready    <none>...   Ubuntu 16.04.7 LTS      4.4.0-193-generic              docker://20.10.1
foo3   Ready    <none>...   Ubuntu 20.04.1 LTS      5.4.0-52-generic               containerd://1.3.7
foo4   Ready    <none>...   CentOS Linux 7 (Core)   3.10.0-1160.6.1.el7.x86_64     containerd://1.3.7
foo5   Ready    <none>...   CentOS Linux 8 (Core)   4.18.0-193.28.1.el8_2.x86_64   cri-o://1.19.0
foo6   Ready    <none>...   CentOS Linux 8          4.18.0-240.1.1.el8_3.x86_64    docker://20.10.1
```

### This K8s cluster is a mess...

_"This K8s cluster is a mess -- why should every node be a different OS and run a different container-runtime?  Is this even 'legal'?"_

Yes, this is a "legal" Kubernetes cluster.  As for why should this be useful -- the reason is _TESTING_:

* most of the K8s apps will "live" completely isolated inside a container, and will not be affected by the host-system, its packages/versions or container-runtimes -- that's the "beauty" of containers, however
* there are still subtle differences between the container runtimes (or, software that _runs_ your containers), lastly
* if your containerized application needs to interact with the host (e.g. set up resource limits, mount local files/dirs, use Persistent Volumes), or is security-sensitive, it is generally a good idea to test it across a few platforms and container runtimes.

So, you have an option: either test the application multiple times on multiple Kubernetes clusters, or use one "hybrid" cluster.

## Prerequisites

1. Download and/or install the following packages on your Linux host-system that will run your VMs:

   * [libvirt](https://www.google.com/search?q=linux+install+libvirt)
   * [Vagrant](https://www.vagrantup.com/downloads.html)
   * [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

2. Install [libvirt vagrant provider](https://github.com/vagrant-libvirt/vagrant-libvirt#installation) plugin

## Setup

1) Edit the [Vagrantfile](Vagrantfile), and select node-names and [VM/OS-type](https://app.vagrantup.com/boxes/search) to install:

   ```ruby
   vm_nodes = {
      'foo1' => 'generic/ubuntu1604',
      'foo2' => 'centos/7',
      ...
   }
   ```

   <details>
      <summary>More customizations?  (Click to expand)</summary>

      You may also want to modify the nodes' memory, number of CPU-cores or add extra disk-devices, e.g.:

      ```ruby
         # libvirt-specific VM-tuning
         node.vm.provider :libvirt do |v|
            v.memory = 8192
            v.cpus = 4
            v.storage :file, :size => '20G'
            v.storage :file, :size => '50G'
            v.storage :file, :size => '100G'
         end
      ```

      You can find more about the options at https://github.com/vagrant-libvirt/vagrant-libvirt#libvirt-configuration
   </details>

2) Start the VMs

   ```bash
   vagrant up
   ```

3) Verify the network routing

   ```bash
   make test
   ```

   > ![#f03c15](https://placehold.it/15/f03c15/000000?text=+) **WARNING**</span>:<br/> Make sure _none_ of the nodes are routing via `eth0` vagrant NAT/private-network interface. The Ansible playbooks assume the default network interface is set via `eth1` and public network.

4) [*OPTIONAL*] Edit the auto-generated `.hosts` file and modify which container-runtime to use (the default is *docker*):

   Example:

   ```
   foo1 	  # cri_runtime={docker|docker-ce|containerd|cri-o}
   foo2 	  cri_runtime=docker-ce
   foo3 	  cri_runtime=containerd
   foo4 	  cri_runtime=cri-o
   ```

   <details>
      <summary>What is <tt>cri_runtime</tt>?  (Click to expand)</summary>

      | `cri_runtime` | Description                                                                             |
      | ------------- | --------------------------------------------------------------------------------------- |
      | docker        | Platform's "native" docker package (not available on RHEL/CentOS v8)                    |
      | docker-ce     | Docker "Community Edition" via https://get.docker.com/                                  |
      | containerd    | [ContainerD](https://containerd.io/) container runtime                                  |
      | cri-o         | RedHat's [CRI-O](https://cri-o.io/) containter runtime (not available on all platforms) |

   More info at https://kubernetes.io/docs/setup/production-environment/container-runtimes/
   </details>

5) [*OPTIONAL*] Edit [vars/common.yaml](vars/common.yaml) and update software versions, e.g.:

   ```yaml
   k8s_version: 1.17.11
   k8s_net: "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
   crio_version: 1.17
   etcd_version: 3.4.13
   ```

6) Deploy the Kubernetes cluster via Ansible

   ```bash
   make install
   ```

### Related topics

<details>
   <summary>How to I log into the VMs/nodes?  (Click to expand)</summary>

   You have several options:

   1. log in via `vagrant`:

      ```bash
      vagrant ssh foo2
      sudo -u root HOME=/root bash -l
      HOME=/root
      ```

   2. log in via `virsh`:

      ```bash
      # list all available VMs
      virsh list --all
      
      # attach to VM's console
      virsh console XXX_foo2
      ```

   3. log in directly:

      ```bash
      # run `make test` to display IP addresses
      make test

      # ssh as root directly to the node
      # -note: default root's password has been set via Vagrantfile as 'Password1', you'll probably want to change this
      ssh root@192.168.99.99
      ```

</details>
<details>
   <summary>How do I add more nodes into the cluster?   (Click to expand)</summary>

   1) Edit the [Vagrantfile](Vagrantfile), and add more nodes into `vm_nodes`:

      ```ruby
      vm_nodes = {
         ...
         'foo98' => 'centos/8',
         'foo99' => 'generic/ubuntu2004',
      }
      ```

   2) Start the VMs

      ```bash
      vagrant up
      ```

   3) Re-generate `.hosts` and `.ssh_conf`:

      ```bash
      # Save/remove old files
      mv .hosts .hosts0
      rm .ssh_conf

      # Test network, also re-generate .hosts/.ssh_conf files
      make test

      # Update .hosts if you used custom container-runtimes:
      vim -d .hosts .hosts0
      ```

   4) Install/Update Kubernetes cluster

      ```bash
      make install
      ```

</details>

## Cleanup

To terminate and destroy the VMs, run the following:

```bash
make distclean
```

<details>
  <summary>Alternative: Keep the nodes, whipe K8s..  (Click to expand)</summary>

   If you want only to wipe the Kubernetes cluster while _retaining_ the VMs/nodes, run the following:

   ```bash
   ansible-playbook -i .hosts --ssh-common-args "-F .ssh_conf" sa/k8s_destroy.yaml

   # run `make install` to set up K8s cluster again
   ```

</details>

## Known limitations

* no HA; cluster will set up with only 1 Kubernetes master-node
* VM images **must** use `eth#` network-interfaces notation
* all the IP addresses will be auto-assigned via DHCP
* the container-runtime packages may not be available for all the platforms/distributions
  * e.g. no "native" `docker` package on CentOS/RHEL 8, also `cri-o` packages may not be available for your platform
