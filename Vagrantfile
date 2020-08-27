# -*- mode: ruby -*-
# vim:ft=ruby:sw=3:et:

vm_nodes = {            # EDIT to specify VM node names, and their type (see #vm_conf below)
   'foo1' => 'bento16',
   'foo2' => 'bento16',
   'foo3' => 'bento16',
   'foo4' => 'centos7',
}

# VM config, format: <type-label> => [ 0:vagrant-box, 1:vm-net-iface, 2:vm-disk-controller, 3:vm-start-port, 4:vm-drives-map ]
# see https://app.vagrantup.com/boxes/search for more VM images (ie. "box-names")
vm_conf = {
   'ubuntu16' => [ 'ubuntu/xenial64', 'enp0s8', 'SCSI', 2, { "sdc" => 15*1024, "sdd" => 20*1024 } ],
   'ubuntu18' => [ 'ubuntu/bionic64', 'enp0s8', 'SCSI', 2, { "sdc" => 15*1024, "sdd" => 20*1024 } ],
   'bento16' => [ 'bento/ubuntu-16.04', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'bento18' => [ 'bento/ubuntu-18.04', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'centos7'  => [ 'centos/7', 'eth1', 'IDE', 1, { "sdb" => 20*1024 } ],
   'centos8'  => [ 'generic/centos8', 'eth1', 'IDE Controller', 1, { "sdb" => 20*1024 } ],
   'fedora29'  => [ 'generic/fedora29', 'eth1', 'IDE Controller', 1, { "sdb" => 20*1024 } ],
   'rhel7'  => [ 'generic/rhel7', 'eth1', 'IDE Controller', 1, { "sdb" => 20*1024 } ],
   # -- NOT supported for Kubernetes:
   'ubuntu14' => [ 'ubuntu/trusty64', 'eth1', 'SATAController', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'debian8'  => [ 'debian/jessie64', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'debian9'  => [ 'debian/stretch64', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
   'debian10'  => [ 'debian/buster64', 'eth1', 'SATA Controller', 1, { "sdb" => 15*1024, "sdc" => 20*1024 } ],
}

#
# VAGRANT SETUP
#
Vagrant.configure("2") do |config|

   vm_nodes.each do |host,typ|

      mybox, mynic, mycntrl, myport, extra_disks = vm_conf["#{typ}"]

      config.vm.define "#{host}" do |node|

         node.vm.box = "#{mybox}"
         node.vm.hostname = "#{host}"
         node.vm.network "public_network", bridge: "eth0", use_dhcp_assigned_default_route: true

         node.vm.provider "virtualbox" do |v|
            v.gui = false
            v.memory = 4096
            v.linked_clone = true

            # Extra customizations
            v.customize 'pre-boot', ["modifyvm", :id, "--cpus", "2"]
            v.customize 'pre-boot', ["modifyvm", :id, "--chipset", "ich9"]
            v.customize 'pre-boot', ["modifyvm", :id, "--audio", "none"]
            v.customize 'pre-boot', ["modifyvm", :id, "--usb", "off"]
            v.customize 'pre-boot', ["modifyvm", :id, "--accelerate3d", "off"]
            v.customize 'pre-boot', ["storagectl", :id, "--name", "#{mycntrl}", "--hostiocache", "on"]

            # force Virtualbox to sync the time difference w/ threshold 10s (defl was 20 minutes)
            v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000 ]

            # Net boot speedup (see https://github.com/mitchellh/vagrant/issues/1807)
            v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

            if defined?(extra_disks)
               # NOTE: If you hit errors w/ extra disks provisioning, you may need to run "Virtual
               # Media Manager" via VirtualBox GUI, and manually remove $host_sdX drives.
               port = myport
               extra_disks.each do |hdd, size|
                  vdisk_name = ".vagrant/#{host}_#{hdd}.vdi"
                  unless File.exist?(vdisk_name)
                     v.customize ['createhd', '--filename', vdisk_name, '--size', "#{size}"]
                  end
                  v.customize ['storageattach', :id, '--storagectl', "#{mycntrl}", '--port', port, '--device', 0, '--type', 'hdd', '--medium', vdisk_name]
                  port = port + 1
               end
            end
         end

         # Custom post-install script below:
         node.vm.provision "shell" do |s|
            s.inline = <<-SHELL
               echo ':: Fixing ROOT access ...'
               echo root:Password1 | chpasswd
               sed -i -e 's/.*UseDNS.*/UseDNS no  # VAGRANT/' \
                  -e 's/.*PermitRootLogin.*/PermitRootLogin yes  # VAGRANT/' \
                  -e 's/.*PasswordAuthentication.*/PasswordAuthentication yes  # VAGRANT/' \
                  /etc/ssh/sshd_config && systemctl restart sshd

               echo ':: Fixing /etc/hosts ...'
               sed -i -e 's/.*#{host}.*/# \\0  # VAGRANT/' /etc/hosts

               if [ -f /etc/sysconfig/network ]; then
                  echo ':: Fixing GATEWAYDEV  (CentOS) ...'
                  echo 'GATEWAYDEV=#{mynic}' >> /etc/sysconfig/network
                  systemctl restart network || \
                  ( systemctl restart NetworkManager; sleep 3; nmcli networking off; nmcli networking on )
               fi
               echo ":: IPs $(hostname -I)"
            SHELL
         end
      end
   end
end

