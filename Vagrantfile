# -*- mode: ruby -*-
# vim:ft=ruby:sw=3:et:


# EDIT to specify VM node names, and their box-type
# - see https://app.vagrantup.com/boxes/search for more VM images for libvirt-provider
#   > i.e. Debian family: 'generic/ubuntu1604', 'generic/ubuntu1804', 'generic/ubuntu2004'
#   > i.e. RedHat family: 'centos/7', 'centos/8', 'generic/centos8'
vm_nodes = {
   'foo1' => 'generic/ubuntu1604',
   'foo2' => 'generic/ubuntu1604',
   'foo3' => 'generic/ubuntu2004',
   'foo4' => 'centos/7',
   'foo5' => 'centos/8',
}

rootPassword = 'Password1'                   # set to enable root ssh-access
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'  # force libvirt provider

Vagrant.configure("2") do |config|
   config.vm.box_check_update = false

   vm_nodes.each do |host,box|
      config.vm.define "#{host}" do |node|
         # vagrant host-setup
         node.vm.box = "#{box}"
         node.vm.hostname = "#{host}"
         node.vm.network :public_network, :type => "bridge", dev: "br0", mode: "bridge",
            network_name: "public_network", use_dhcp_assigned_default_route: true

         # libvirt-specific host-tuning
         node.vm.provider :libvirt do |v|
            v.memory = 4096
            v.cpus = 2
            v.storage :file, :size => '20G'
         end

         # custom post-install
         node.vm.provision "shell" do |s|
            s.inline = <<-SHELL
               if [ -n '#{rootPassword}' ]; then
                  echo ':: Fixing ROOT access ...'
                  echo 'root:#{rootPassword}' | chpasswd
                  sed -i -e 's/.*UseDNS.*/UseDNS no  # VAGRANT/' \
                     -e 's/.*PermitRootLogin.*/PermitRootLogin yes  # VAGRANT/' \
                     -e 's/.*PasswordAuthentication.*/PasswordAuthentication yes  # VAGRANT/' \
                     /etc/ssh/sshd_config && systemctl restart sshd
               fi

               echo ':: Fixing /etc/hosts ...'
               sed -i -e 's/.*#{host}.*/# \\0  # VAGRANT/' /etc/hosts

               if [ -f /etc/sysconfig/network ]; then
                  echo ':: Fixing GATEWAYDEV  (RedHat routing fix) ...'
                  echo 'GATEWAYDEV=eth1' >> /etc/sysconfig/network
                  systemctl restart network || \
                  ( systemctl restart NetworkManager; sleep 3; nmcli networking off; nmcli networking on; sleep 5 )
                  # fix DNS entries on eth1
                  nmcli con mod "System eth1" ipv4.dns "1.1.1.1 1.0.0.1" ; nmcli con mod "System eth1" ipv4.ignore-auto-dns yes ; nmcli connection up id 'System eth1'
               elif [ -f /etc/netplan/01-netcfg.yaml ]; then
                  echo ':: Fixing NetPlan  (Ubuntu 18/20 routing fix) ...'
                  sed -i -e 's/^\\( \\+\\)dhcp4: true/\\0\\n\\1dhcp4-overrides:\\n\\1  use-routes: false/' \
                    /etc/netplan/01-netcfg.yaml && \
                    netplan apply && sleep 5
               fi
               echo ":: IPs $(hostname -I)"
            SHELL
         end
      end
   end
end
