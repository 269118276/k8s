#!/bin/bash
# 修改IP
pwd=$HOME/k8s/INSTALL/shell
echo -e "\033[32m ############# 修改主机名 ############ \033[0m"
ethx=eth0
ip=$(ifconfig $ethx|grep 'inet '|awk '{print $2}')
hostname=$(grep $ip $pwd/hosts|awk '{print $2}')
hostnamectl set-hostname $hostname
echo "主机名已被修改为：$hostname"


echo -e "\033[32m ############# 修改hosts文件 ############ \033[0m"
sed -i '3,$d' /etc/hosts && cat $pwd/hosts >> /etc/hosts
echo "hosts文件已更新"

echo -e "\033[32m ############# 关闭SELINUX ############ \033[0m"
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config && setenforce 0 > /dev/null 2>&1
echo "SELINUX已禁用"

echo -e "\033[32m ############# 关闭Firewall ############ \033[0m"
systemctl disable firewalld > /dev/null 2>&1 && systemctl stop firewalld > /dev/null 2>&1
echo "防火墙已禁用"

echo -e "\033[32m ############# 生成公私钥 ############ \033[0m"
type=rsa
bits=2048
keyfile=$HOME/.ssh/id_rsa
if [ ! -f "$keyfile" ];then
    ssh-keygen -t $type -b $bits -f $keyfile -N "" > /dev/null 2>&1
fi

echo -e "\033[32m ############# 上传公钥到远程主机 ############ \033[0m"
identity_file=~/.ssh/id_rsa.pub
ssh_port=22
ssh_user=root
password=1

# 安装expect
yum install -y expect > /dev/null 2>&1

while read line
do
arr=($line)
for remote_hostname in ${arr[1]}
do
/usr/bin/expect << EOF
    spawn ssh-copy-id -i $identity_file -p $ssh_port $ssh_user@$remote_hostname
    expect {
            "yes/no" { send "yes\r";exp_continue }
            "password" { send "$password\r" }
           }
expect eof
EOF
done > /dev/null 2>&1
done < $pwd/hosts
echo "免密登录设置已完成"
