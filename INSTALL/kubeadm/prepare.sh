#!/bin/bash
echo -e "\033[32m ############# 关闭swap ############ \033[0m"
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

echo -e "\033[32m ############# 修改内核参数 ############ \033[0m"
modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf > /dev/null 2>&1

echo -e "\033[32m ############# 配置安装docker的阿里云repo源 ############ \033[0m"
# step 1: 安装必要的一些系统工具
yum install -y yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3
sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
# Step 4: 更新并安装Docker-CE
yum makecache fast > /dev/null 2>&1
yum -y install docker-ce > /dev/null 2>&1
# Step 4: 开启Docker服务
systemctl start docker && systemctl enable docker > /dev/null 2>&1

# 注意：
# 官方软件源默认启用了最新的软件，您可以通过编辑软件源的方式获取各个版本的软件包。例如官方并没有将测试版本的软件源置为可用，您可以通过以下方式开启。同理可以开启各种测试版本等。
# vim /etc/yum.repos.d/docker-ce.repo
#   将[docker-ce-test]下方的enabled=0修改为enabled=1
#
# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# yum list docker-ce.x86_64 --showduplicates | sort -r
#   Loading mirror speeds from cached hostfile
#   Loaded plugins: branch, fastestmirror, langpacks
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            docker-ce-stable
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            @docker-ce-stable
#   docker-ce.x86_64            17.03.0.ce-1.el7.centos            docker-ce-stable
#   Available Packages
# Step2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.0.ce.1-1.el7.centos)
# sudo yum -y install docker-ce-[VERSION]

echo -e "\033[32m ############# 安装基础软件包 ############ \033[0m"
yum install -y wget net-tools gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel vim ncurses-devel autoconf automake zlib-devel python-devel epel-release openssh-server socat ipvsadm conntrack telnet > /dev/null 2>&1


echo -e "\033[32m ############# 配置安装k8s的阿里云repo源 ############ \033[0m"
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

echo -e "\033[32m ############# 配置时间同步 ############ \033[0m"
ntp_server=ntp.aliyun.com
yum install -y chrony > /dev/null 2>&1
sed -i '/^server/s/^/#/' /etc/chrony.conf
sed -i '/^#server/a\server $ntp_server iburst' /etc/chrony.conf
systemctl start chronyd && systemctl enable chronyd > /dev/null 2>&1
