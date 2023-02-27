#!/bin/bash
echo -e "\033[32m ############# 安装containerd服务 ############ \033[0m"
yum install -y containerd.io-1.6.6 > /dev/null 2>&1

echo -e "\033[32m ############# 配置containerd镜像加速 ############ \033[0m"
containerd config default > /etc/containerd/config.toml
sed -i 's/systemcgroup = false/systemcgroup = true/' /etc/containerd/config.toml
#sed -i 's/sandbox_image = .*/sandbox_image = "registry.aliyuncs.com\/google_containers\/pause:3.8"/' /etc/containerd/config.toml
sed -i 's/sandbox_image = .*/sandbox_image = "registry.cn-hangzhou.aliyuncs.com\/google_containers\/pause:3.8"/' /etc/containerd/config.toml
sed -i 's/config_path = ""/config_path = "\/etc\/containerd\/certs.d"/' /etc/containerd/config.toml
systemctl start containerd && systemctl enable containerd > /dev/null 2>&1

echo -e "\033[32m ############# 修改/etc/crictl.yaml文件 ############ \033[0m"
cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
dir=/etc/containerd/certs.d/docker.io
if [ ! -d $dir ];then
    mkdir $dir -p
fi
cat > $dir/hosts.toml << EOF
[host."https://vh3bm53y.mirror.aliyuncs.com",host."https://registry.docker-cn.com"]
  capabilities=["pull"]
EOF

echo -e "\033[32m ############# 重启containerd服务 ############ \033[0m"
systemctl restart containerd

echo -e "\033[32m ############# 配置docker镜像加速器 ############ \033[0m"
cat > /etc/docker/daemon.json << EOF
{
"registry-mirrors":["https://vh3bm52y.mirror.aliyuncs.com","https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn","https://dockerhub.azk8s.cn","http://hub-mirror.c.163.com"]
}
EOF

echo -e "\033[32m ############# 重启docker服务 ############ \033[0m"
systemctl restart docker

echo -e "\033[32m ############# 安装初始化k8s所需的软件 ############ \033[0m"
yum install -y kubectl-1.25.0 kubelet-1.25.0 kubeadm-1.25.0 > /dev/null 2>&1
systemctl enable kubelet > /dev/null 2>&1

echo -e "\033[32m ############# 初始化k8s集群 ############ \033[0m"
# 设置容器运行时
crictl config runtime-endpoint /run/containerd/containerd.sock
# 使用kubeadm初始化k8s集群
pwd=$HOME/k8s/INSTALL/shell
if [ -f $pwd/kubeadm.yaml ]; then
    rm -f $pwd/kubeadm.yaml
fi
kubeadm config print init-defaults > $pwd/kubeadm.yaml
sed -i 's/advertiseAddress:.*/advertiseAddress: 10.163.1.106/' $pwd/kubeadm.yaml
sed -i 's/criSocket:.*/criSocket: unix:\/\/\/run\/containerd\/containerd.sock/' $pwd/kubeadm.yaml
sed -i 's/name: .*/name: k8s-master1/' $pwd/kubeadm.yaml
sed -i 's/imageRepository: .*/imageRepository: registry.cn-hangzhou.aliyuncs.com\/google_containers/' $pwd/kubeadm.yaml
sed -i '/serviceSubnet:/i\  podSubnet: 10.244.0.0\/16' $pwd/kubeadm.yaml
cat >> $pwd/kubeadm.yaml << EOF
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

# 基于kubeadm.yaml初始化k8s集群
#ctr -n=k8s.io images import $pwd/k8s_1.25.0.tar.gz
# 在获取到相应的镜像后通过ctr images export这个命令把镜像输出到k8s_1.25.0.tar.gz这个文件，以上命令执行前当前目录必须要有这个文件。
# 也可以通过ctr -n=k8s.io image pull命令直接拉取各个组件的镜像。
# 可以通过命令查看k8s.io命名空间的镜像：crictl images


