#!/bin/bash

sudo yum install sshpass -y
sudo yum install wget -y

curl -s https://api.github.com/repos/heketi/heketi/releases/latest \
  | grep browser_download_url \
  | grep linux.amd64 \
  | cut -d '"' -f 4 \
  | wget -qi -

for i in `ls | grep heketi | grep .tar.gz`; do tar xvf $i; done

sudo cp heketi/{heketi,heketi-cli} /usr/local/bin

heketi --version
heketi-cli --version

sudo groupadd --system heketi
sudo useradd -s /sbin/nologin --system -g heketi heketi

sudo mkdir -p /var/lib/heketi /etc/heketi /var/log/heketi
sudo cp /vagrant/heketi.json /etc/heketi

sudo ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''
sudo chown heketi:heketi /etc/heketi/heketi_key*

for i in gluster01 gluster02 gluster03; do
  sudo sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no -i /etc/heketi/heketi_key.pub root@$i
done

sudo cp /vagrant/heketi.service /etc/systemd/system/heketi.service

sudo wget -O /etc/heketi/heketi.env https://raw.githubusercontent.com/heketi/heketi/master/extras/systemd/heketi.env

sudo chown -R heketi:heketi /var/lib/heketi /var/log/heketi /etc/heketi

sudo systemctl daemon-reload
sudo systemctl enable --now heketi

systemctl status heketi

curl localhost:8080/hello; echo

if [ $? -eq 1 ]; then 
    echo "Heketi not ready"
    exit 1;
fi

echo "Create heketi cluster.."
heketi-cli cluster create
CLUSTER_ID=$(heketi-cli cluster list | awk -v FS=: 'NR==2{print $2}' | cut -d' ' -f1)

echo "Adding nodes to cluster: $CLUSTER_ID"
for i in gluster01 gluster02 gluster03; do
  heketi-cli node add --zone 1 --cluster $CLUSTER_ID --management-host-name $i --storage-host-name $i
done

NODE_IDS=$(heketi-cli node list | awk -v FS=: '{print $2}' | cut -f1)

echo "Adding devices to nodes"
for i in $NODE_IDS; do
  heketi-cli device add --name /dev/sdb --node $i
  heketi-cli node info $i
done

