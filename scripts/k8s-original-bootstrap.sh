#!/bin/bash -xe

##################################################################################################################################
# here is a script used for creating a pre-baked kubernetes ami for both the master and worker nodes.
# The ami used for creating this Kubernetes AMI is ami-0cd59ecaf368e5ccf (stable ubuntu version that works with k8s 1.28.1)
##################################################################################################################################

sudo apt-get update 
sudo apt-get install nfs-common -y
sudo apt install -y awscli
sudo apt install mysql-server -y
sudo apt install mysql-client -y

#disabling swapoff so kubelet can work properly
sudo swapoff -a

#forwarding ipv4 and letting iptables see bridged traffic
#load the overlay module for OverlayFS, used by containerd
#load the br_netfilter module for network packet filtering
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

#load the kernel modules immediately without rebooting
sudo modprobe overlay
sudo modprobe br-netfilter

#enable iptables to see bridged traffic, crucial for the correct functioning of network policies
#enable ipv6tables to see bridged traffic (for ipv6), crucial for the correct functioning of network policies
#enable IP forwarding, required for networking between containers
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

#apply sysctl params without reboot
sudo sysctl --system

#checking that system variables are set to 1
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

#installing containerd
sudo apt-get update
sudo apt-get install

#Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

#installing docker and containerd
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable containerd
sudo systemctl enable docker

#verifying our init system
ps -p 1

#setting cgroup to system
#To use the systemd cgroup driver in /etc/containerd/config.toml with runc, set

sudo su <<EOF
sudo echo "[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]" > /etc/containerd/config.toml
sudo echo "  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]" >> /etc/containerd/config.toml
sudo echo "    SystemdCgroup = true" >> /etc/containerd/config.toml
exit 
EOF

sudo systemctl restart containerd
sudo systemctl restart docker

#Installing kubeadm, kubelet and kubectl 

#kubelet: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
#kubectl: the command line util to talk to your cluster.

#kubeadm: the command to bootstrap the cluster
#update the apt package index and install packages needed to use Kubernetes apt repository
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

#download the google cloud public signing key
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command to store the GPG keys of external repositories
sudo mkdir -p -m 755 /etc/apt/keyrings
#Download the Kubernetes signing key and store it
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#add Kubernetes repository to the apt repository, system software resources
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#update apt package index, install kubelet, kubeadm and kubectl and pin their version
sudo apt-get update
#Install specific versions of kubelet, kubeadm, and kubectl, and allow changing of held 
sudo apt-get install -y kubelet=1.28.1-1.1 kubeadm=1.28.1-1.1 kubectl=1.28.1-1.1 --allow-change-held-packages
#Prevent automatic updating or removal of Kubernetes packages to maintain version consistency
sudo apt-mark hold kubelet kubeadm kubectl

# check available kubeadm versions (when manually executing)
apt-cache madison kubeadm

sudo ls -ltr

















