#!/bin/bash

set -eu

sudo pip3 install kubernetes

function test_wireguard (){
    sleep 5
    ansible -m shell -a 'ping 10.8.0.101 -c 3' worker-0
    ansible -m shell -a 'ping 10.8.0.102 -c 3' worker-1
    ansible -m shell -a 'ping 10.8.0.103 -c 3' controller-0
    ansible -m shell -a 'ping 10.8.0.111 -c 3' controller-1
}

function test_etcd () {
    sleep 5
    ansible -m shell -e "etcd_conf_dir=/etc/etcd" \
        -a 'ETCDCTL_API=3 etcdctl endpoint health \
            --endpoints=https://{{ ansible_wgk8slaab.ipv4.address }}:2379 \
            --cacert={{ etcd_conf_dir }}/ca-etcd.pem \
            --cert={{ etcd_conf_dir }}/cert-etcd-server.pem \
            --key={{ etcd_conf_dir }}/cert-etcd-server-key.pem' \
        k8s_etcd
}

function test_control_plane () {
    sleep 5
    kubectl cluster-info
    echo "test scheduler "
    curl -k https://10.8.0.101:10257/healthz
    echo "\ntest controller manager "
    curl -k https://10.8.0.102:10259/healthz
    echo "\n"
}

function k8s_playbook (){
    ansible-playbook --tags=$1 \
        -e ansible_become_password='{{ lookup("env", "ANSIBLE_BECOME_PASSWORD") }}' \
        -e action=install \
        k8s.yml
}

function other_playbook (){
    ansible-playbook -e ansible_become_password='{{ lookup("env", "ANSIBLE_BECOME_PASSWORD") }}' $1
}

echo "######## Setup cluster private network"
k8s_playbook role-wireguard
test_wireguard

echo "######## Install PKI tool cfssl on local workstation"
k8s_playbook role-cfssl

echo "######## Generate locally PKI/certs for all cluster components"
k8s_playbook role-kubernetes-ca

echo "######## Generate kubeconfigs for cluster components based ont PKI"
other_playbook playbooks/all_kubeconfs.yml

echo "######## Setup at rest encryption for etcd cluster"
other_playbook githubixx_playbooks/kubeencryptionconfig/kubeencryptionconfig.yml

echo "######## Install and setup binary etcd on each control plane nodes"
k8s_playbook role-etcd
test_etcd

echo "######## Install binary API server, Scheduler and controller manager on control plane nodes"
k8s_playbook role-kubernetes-controller

echo "######## Setup kubectl config for cluster admin connection"
other_playbook  ./githubixx_playbooks/kubectlconfig/kubectlconfig.yml
export KUBECONFIG=./k8s_files/confs/admin.kubeconfig
export K8S_AUTH_KUBECONFIG=./k8s_files/confs/admin.kubeconfig # for ansible modules
test_control_plane

echo "######## Install containerd runtime on worker nodes"
k8s_playbook role-containerd

echo "######## Install worker nodes components kubelet kube-proxy etc and connect nodes to control plane"
k8s_playbook role-kubernetes-worker

echo "######## Install cillium CNI plugin in the cluster"
ansible-playbook -K -e action=install --tags=role-cilium-kubernetes k8s.yml

echo "######## Install CoreDNS in the cluster"
other_playbook githubixx_playbooks/coredns/coredns.yml
