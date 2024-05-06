#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

     apt update && apt upgrade -y
     apt install -y ufw nfs-common

     mkdir minecraft
     mount 192.168.1.7:/var/local/minecraft minecraft

     curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key |  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' |  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y

apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now kubelet

kubectl version --client && kubeadm version

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Enable kernel modules
 modprobe overlay
 modprobe br_netfilter

# Add some settings to sysctl
 tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
 sysctl --system

# Configure persistent loading of modules
 tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF


# Install required packages
 apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg

 echo " " | add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install containerd
 apt update
 apt install -y containerd.io

# Configure containerd and start service
 mkdir -p /etc/containerd
 containerd config default| tee /etc/containerd/config.toml

# restart containerd
 systemctl restart containerd
 systemctl enable containerd
 systemctl status  containerd

unset DEBIAN_FRONTEND

