#!/bin/bash
echo -e "\033[32m ############# 修改主机名 ############ \033[0m"
read -p "输入主机名:" hostname
hostnamectl set-hostname $hostname
echo "主机名已被修改为：$hostname"

# 修改IP

echo -e "\033[32m ############# 修改hosts文件 ############ \033[0m"
sed -i '3,$d' /etc/hosts && cat ./hosts >> /etc/hosts

echo -e "\033[32m ############# 关闭SELINUX ############ \033[0m"
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config && setenforce 0 > /dev/null 2>&1

echo -e "\033[32m ############# 关闭Firewall ############ \033[0m"
systemctl disable firewalld > /dev/null 2>&1 && systemctl stop firewalld > /dev/null 2>&1

echo -e "\033[32m ############# 生成公私钥 ############ \033[0m"
type=rsa
bits=2048
keyfile=~/.ssh/id_rsa
passphrase=""
if [ ! -f "$keyfile" ];then
    ssh-keygen -t $type -b $bits -f $keyfile -N $passphrase > /dev/null 2>&1
fi

echo -e "\033[32m ############# 上传公钥到远程主机 ############ \033[0m"
identity_file=~/.ssh/id_rsa.pub
ssh_port=22
ssh_user=root
while read line
do
arr=($line)
for remote_hostname in ${arr[0]}
do
ssh-copy-id -i $identity_file -p $ssh_port $ssh_user@${remote_hostname[0]} > /dev/null 2>&1
done
done < hosts
