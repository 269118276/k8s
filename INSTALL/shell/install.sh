#!/bin/bash
echo -e "\033[32m ############# 安装基础软件包 ############ \033[0m"
yum install -y device-mapper-persistent-data lvm2 wget net-tools nfs-utils lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel vim ncurses-devel autoconf automake zlib-devel python-devel epel-release openssh-server socat ipvsadm conntrack telnet > /dev/null 2>&1

echo -e "\033[32m ############# 安装containerd服务 ############ \033[0m"
yum install -y containerd.io-1.6.6
containerd config default > /etc/containerd/config.toml
sed -i 's/systemcgroup=false/systemcgroup=true/' /etc/containerd/config.toml
sed -i 's/^sandbox_image=.*/sandbox_image="registry.aliyuncs.com/google_containers/pause:3.7"/' /etc/containerd/config.toml
sed -i 's/config_path=""/config_path="/etc/containerd/certs.d/' /etc/containerd/config.toml
systemctl start containerd && systemctl enable containerd > /dev/null 2>&1
cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
dir=/etc/containerd/certs.d/docker.io
if [ !-d $dir ];then
    mkdir $dir -p
fi
cat > $dir/hosts.toml << EOF
[host."https://vh3bm53y.mirror.aliyuncs.com",host."https://registry.docker-cn.com"]
  capabilities=["pull"]
EOF
systemctl restart containerd

echo -e "\033[32m ############# 配置docker镜像加速器 ############ \033[0m"
cat > /etc/docker/daemon.json << EOF
{
"registry-mirrors":["https://vh3bm52y.mirror.aliyuncs.com","https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn","https://dockerhub.azk8s.cn","http://hub-mirror.c.163.com"]
}
EOF
systemctl restart docker

echo -e "\033[32m ############# 安装初始化k8s所需的软件 ############ \033[0m"
yum install -y kubectl-1.25.0 kubelet-1.25.0 kubeadm-1.25.0 > /dev/null 2>&1
systemctl enable kubelet > /dev/null 2>&1

echo -e "\033[32m ############# 初始化k8s集群 ############ \033[0m"
# 设置容器运行时
crictl config runtime-endpoint /run/containerd/containerd.sock
# 使用kubeadm初始化k8s集群
kubeadm config print init-defaults > kubeadm.yaml
sed -i 's/advertiseAddress:.*/advertiseAddress:10.163.1.106/' kubeadm.yaml

