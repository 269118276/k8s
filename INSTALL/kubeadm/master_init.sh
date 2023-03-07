#!/bin/bash
echo -e "\033[32m ############# 初始化k8s集群 ############ \033[0m"
pwd=$HOME/k8s/INSTALL/shell
kubeadm init --config=$pwd/kubeadm.yaml --ignore-preflight-errors=SystemVerification

echo -e "\033[32m ############# 授权kubectl管理集群 ############ \033[0m"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
