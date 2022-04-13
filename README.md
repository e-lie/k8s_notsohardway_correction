

```
ansible-galaxy collection install hetzner.hcloud
ansible-galaxy collection install community.dns
pip install hcloud # or use pacman
```

```
ansible-galaxy install -r ./roles/requirements.yml -p ./roles
```

```bash
source env_file
ssh-add ~/.ssh/id_stagiaire
./cloud_cli setup_terraform
ansible-playbook playbooks/initial_hardening.yml
ansible-playbook -K --tags=role-wireguard k8s.yml
ping 10.8.0.101
ping 10.8.0.102
ping 10.8.0.103
ping 10.8.0.111
ansible-playbook -K --tags=role-cfssl k8s.yml
ansible-playbook -K --tags=role-kubernetes-ca k8s.yml
# then check k8s_files/certs

ansible-playbook -K playbooks/all_kubeconfs.yaml
# then check k8s_files/confs
ansible-playbook -K githubixx_playbooks/kubeencryptionconfig/kubeencryptionconfig.yml
# then check k8s_files/confs for new file
ansible-playbook -K --tags=role-etcd k8s.yml

# checking etc cluster
ansible -m shell -e "etcd_conf_dir=/etc/etcd" -a 'ETCDCTL_API=3 etcdctl endpoint health \
--endpoints=https://{{ ansible_wgk8slaab.ipv4.address }}:2379 \
--cacert={{ etcd_conf_dir }}/ca-etcd.pem \
--cert={{ etcd_conf_dir }}/cert-etcd-server.pem \
--key={{ etcd_conf_dir }}/cert-etcd-server-key.pem' \
k8s_etcd

ansible-playbook -K --tags=role-kubernetes-controller k8s.yml

ansible-playbook -K ./githubixx_playbooks/kubectlconfig/kubectlconfig.yml

export KUBECONFIG=./k8s_files/confs/admin.kubeconfig

kubectl cluster-info
kubectl get componentstatuses # only to check etcd health
# normal that healthcheck other than etcd doesn't work as this is deprecated and use 127.0.0.1 not wg interface 10.8.0.101 addr

# check controller-manager health
curl -k https://10.8.0.101:10257/healthz

# check scheduler health
curl -k https://10.8.0.102:10259/healthz


# Install containerd crictl cni runc
ansible-playbook --tags=role-containerd k8s.yml

# Install kubelet kube-proxy kubectl
ansible-playbook --tags=role-kubernetes-worker k8s.yml

# Check node status
kubectl get nodes -o wide

# Check why
ansible -m command -a 'journalctl -t kubelet -n 50' k8s_worker

# Install Cilium
# if SSL verification error it probably comes from self signed certificates for kube-apiserver
# add validate_certs: no in k8s tasks
ansible-playbook -K --tags=role-cilium-kubernetes -e action=install k8s.yml

ansible-playbook githubixx_playbooks/coredns/coredns.yml

# if error getting logs from pods it can be a problem from the clusterRoleBindings name for
# Kubernetes user because the bindings kubeapi-to-kubelet binding use kubernetes with lower k


```