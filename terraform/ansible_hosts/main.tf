# ## Ansible mirroring hosts section
# # Using https://github.com/nbering/terraform-provider-ansible/ to be installed manually (third party provider)
# # Copy binary to ~/.terraform.d/plugins/

terraform {
  required_providers {
    ansible = {
      source = "nbering/ansible"
      version = "1.0.4"
    }
  }
}


# provider "ansible" {
#   # Configuration options
# }

variable "worker_names" {}
variable "worker_domains" {}
variable "controller_names" {}
variable "controller_domains" {}
variable "worker_public_ips" {}
variable "controller_public_ips" {}


resource "ansible_host" "workers" {
  count = length(var.worker_names)
  inventory_hostname = element(var.worker_names, count.index)
  groups = ["all", "k8s_nodes", "k8s_worker", "vpn"]
  vars = {
    ansible_host = element(var.worker_public_ips, count.index)
    wireguard_address: "10.8.0.11${count.index + 1}/24"
    wireguard_endpoint: element(var.worker_domains, count.index)
    wireguard_port = 51820
    wireguard_persistent_keepalive: "30"
    # username = element(var.worker_names, count.index)
    # vpn_ip = "10.111.0.1${count.index}"
  }
}

resource "ansible_host" "controllers" {
  count = length(var.controller_names)
  inventory_hostname = element(var.controller_names, count.index)
  groups = ["all", "k8s_nodes", "k8s_controller", "k8s_etcd", "vpn"]
  vars = {
    ansible_host = element(var.controller_public_ips, count.index)
    wireguard_address = "10.8.0.10${count.index + 1}/24"
    wireguard_endpoint = element(var.controller_domains, count.index)
    wireguard_port = 51820
    wireguard_persistent_keepalive = "30"
    # username = element(var.controller_names, count.index)
    # vpn_ip = "10.111.0.2${count.index}"
  }
}

resource "ansible_host" "workstation" {
  inventory_hostname = "workstation"
  groups = ["all", "k8s_kubectl", "k8s_ca", "vpn"]
  vars = {
    wireguard_address = "10.8.0.2/24"
    wireguard_endpoint = "" # No endpoint configured (wireguard "client" only)
    ansible_connection = "local"
  }
}

# resource "ansible_group" "vpn" {
#   inventory_group_name = "all"
#   children = ["workers", "controllers"]
#   vars = {
#     wireguard_port = "51820"
#   }
# }