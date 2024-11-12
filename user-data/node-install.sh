# #!/bin/bash

# # swap off
# sudo swapoff -a

# # EBS mount
# sudo mkfs.ext4 /dev/nvme1n1
# sudo mkdir -p /data
# echo '/dev/nvme1n1 /data ext4 defaults 0 0' | sudo tee -a /etc/fstab > /dev/null
# sudo mount -a

# # network plugin setting
# cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
# overlay
# br_netfilter
# EOF
# sudo modprobe overlay
# sudo modprobe br_netfilter

# # sysctl params setting
# cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
# net.bridge.bridge-nf-call-iptables  = 1
# net.bridge.bridge-nf-call-ip6tables = 1
# net.ipv4.ip_forward                 = 1
# EOF

# sudo sysctl --system

# # Docker install
# sudo install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# sudo chmod a+r /etc/apt/keyrings/docker.gpg

# echo \
#   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#   "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# sudo apt-get update
# sudo apt-get install -y ca-certificates curl gnupg docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# # Docker data directory configuration
# sudo mkdir -p /data/docker_dir
# sudo tee /etc/docker/daemon.json > /dev/null << EOT
# { 
#    "data-root": "/data/docker_dir" 
# }
# EOT

# sudo systemctl enable docker --now
# sudo systemctl restart docker

# # Add the current user to the Docker group
# sudo usermod -aG docker $USER

# # cri-dockerd install
# wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.2/cri-dockerd_0.3.2.3-0.ubuntu-jammy_amd64.deb
# sudo dpkg -i cri-dockerd_0.3.2.3-0.ubuntu-jammy_amd64.deb
# rm cri-dockerd_0.3.2.3-0.ubuntu-jammy_amd64.deb

# # Kubernetes binaries installation (kubectl, kubeadm, kubelet)
# # Download and install kubectl
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl
# sudo mv kubectl /usr/local/bin/

# # Download and install kubeadm
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubeadm"
# chmod +x kubeadm
# sudo mv kubeadm /usr/local/bin/

# # Download and install kubelet
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubelet"
# chmod +x kubelet
# sudo mv kubelet /usr/local/bin/

# # Enable and start kubelet service
# sudo systemctl enable kubelet
# sudo systemctl start kubelet
