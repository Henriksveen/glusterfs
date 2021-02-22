# -*- mode: ruby -*-
# vi: set ft=ruby :

$install_gluster_script = <<SCRIPT
sudo yum -y install centos-release-gluster7
sudo yum -y install glusterfs-server
sudo systemctl enable --now glusterd.service
systemctl status glusterd
SCRIPT

$div_setup = <<SCRIPT
sudo /bin/bash -c 'echo -e "172.20.20.101 gluster01 gluster01" >> /etc/hosts'
sudo /bin/bash -c 'echo -e "172.20.20.102 gluster02 gluster02" >> /etc/hosts'
sudo /bin/bash -c 'echo -e "172.20.20.103 gluster03 gluster03" >> /etc/hosts'

sudo /bin/bash -c 'sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config'
sudo /bin/bash -c 'echo -e "Match Address 172.20.20.101,172.20.20.102,172.20.20.103" >> /etc/ssh/sshd_config'
sudo /bin/bash -c 'echo -e "\tPermitRootLogin yes" >> /etc/ssh/sshd_config'
sudo systemctl reload sshd
SCRIPT

$heketi = <<SCRIPT
sudo /bin/bash -c 'echo -e "HEKETI_CLI_USER=admin" >> /etc/environment'
sudo /bin/bash -c 'echo -e "HEKETI_CLI_KEY=password" >> /etc/environment'
SCRIPT

$mount = <<SCRIPT
sudo mkfs.xfs /dev/sdb 
sudo mkdir /mnt/volume
sudo mount /dev/sdb /mnt/volume
SCRIPT

BOX_NAME = "centos/7"
MEMORY = "512"
CPUS = 1
GLUSTER_NODES = 3
GLUSTER_IP = "172.20.20.10"
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = BOX_NAME
  config.vm.box_check_update = true
  config.vm.synced_folder ".", "/vagrant"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = MEMORY
    vb.cpus = CPUS
  end

  #Setup Gluster Nodes
  (1..GLUSTER_NODES).each do |i|
    config.vm.define "gluster0#{i}" do |gluster|
      gluster.vm.network :private_network, ip: "#{GLUSTER_IP}#{i}"
      gluster.vm.hostname = "gluster0#{i}"
      gluster.vm.provision "shell",inline: $install_gluster_script, privileged: true
      gluster.vm.provision "shell",inline: $div_setup, privileged: true
      gluster.vm.provider "virtualbox" do |vb|
        unless File.exist?("./disk#{i}.vdi")
          vb.customize ['createhd', '--filename', "./disk#{i}.vdi", '--variant', 'Fixed', '--size', 2 * 1024]
        end
        vb.customize ['storageattach', :id,  '--storagectl', 'IDE', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "./disk#{i}.vdi"]
      end
      gluster.vm.provision "shell",inline: $mount, privileged: true
      if i == 1
        gluster.vm.provision "shell",inline: $heketi, privileged: true
      end  
    end
  end
end
