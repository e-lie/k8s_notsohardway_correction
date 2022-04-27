#!/bin/bash

set -eu

sudo pip3 install kubernetes

ansible-playbook --tags=role-wireguard k8s.yml
sleep 5
ping 10.8.0.101 -c 3
sleep 2
ping 10.8.0.102 -c 3
ping 10.8.0.103 -c 3
ping 10.8.0.111 -c 3
ansible-playbook --tags=role-cfssl k8s.yml
sleep 2
ansible-playbook --tags=role-kubernetes-ca k8s.yml
sleep 2
ansible-playbook playbooks/all_kubeconfs.yaml
sleep 2
ansible-playbook githubixx_playbooks/kubeencryptionconfig/kubeencryptionconfig.yml
sleep 2
ansible-playbook --tags=role-etcd k8s.yml
sleep 5
# checking etc cluster
ansible -m shell -e "etcd_conf_dir=/etc/etcd" -a 'ETCDCTL_API=3 etcdctl endpoint health \
--endpoints=https://{{ ansible_wgk8slaab.ipv4.address }}:2379 \
--cacert={{ etcd_conf_dir }}/ca-etcd.pem \
--cert={{ etcd_conf_dir }}/cert-etcd-server.pem \
--key={{ etcd_conf_dir }}/cert-etcd-server-key.pem' \
k8s_etcd
ansible-playbook --tags=role-kubernetes-controller k8s.yml
sleep 5
ansible-playbook ./githubixx_playbooks/kubectlconfig/kubectlconfig.yml
export KUBECONFIG=./k8s_files/confs/admin.kubeconfig
kubectl cluster-info
sleep 2
curl -k https://10.8.0.101:10257/healthz
curl -k https://10.8.0.102:10259/healthz
ansible-playbook --tags=role-containerd k8s.yml
sleep 2
ansible-playbook --tags=role-kubernetes-worker k8s.yml
sleep 2
ansible-playbook --tags=role-cilium-kubernetes -e action=install k8s.yml
kubectl get nodes -o wide
ansible-playbook githubixx_playbooks/coredns/coredns.yml
sleep 2