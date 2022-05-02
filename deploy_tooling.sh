#!/bin/bash

set -eu


function k8s_playbook (){
    ansible-playbook --tags=$1 -e "ansible_become_password={{ lookup('env', 'ANSIBLE_BECOME_PASSWORD') }},action=install" k8s.yml
}

function other_playbook (){
    ansible-playbook -e ansible_become_password='{{ lookup("env", "ANSIBLE_BECOME_PASSWORD") }}' $1
}

export KUBECONFIG=./k8s_files/confs/admin.kubeconfig

# echo "######## Install cillium CNI plugin in the cluster"
# k8s_playbook role-cilium-kubernetes
# ansible-playbook -K -e action=install --tags=role-cilium-kubernetes k8s.yml
other_playbook githubixx_playbooks/coredns/coredns.yml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
  namespace: default
spec:
  containers:
  - name: dnsutils
    image: gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF
# sleep 5

# kubectl exec -it dnsutils -- nslookup kubernetes.default.svc

# # sleep 5

# # kubectl delete pod dnsutils

helm upgrade --install metallb metallb \
  --repo https://metallb.github.io/metallb \
  --namespace metallb-system --create-namespace \
  --version 0.12.1 --value=playbooks/metallb-values.yaml

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --version 4.1.0

# other_playbook playbooks/setup_argocd.yml

# sleep 5

# kubectl apply -f argocd_apps/metallb.yaml

# sleep 5

# kubectl apply -f argocd_apps/ingress-nginx.yaml

# sleep 5

# kubectl get services -n ingress-nginx -o wide
