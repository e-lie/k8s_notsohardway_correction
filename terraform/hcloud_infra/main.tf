variable "hcloud_token" {}

variable "cluster_subdomain" {}
variable "controller_names" {}
variable "worker_names" {}
variable "controller_server_type" {}
variable "worker_server_type" {}
variable "ssh_key" {}

# Configure the Hetzner Cloud Provider
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.23.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "id_stagiaire" {
  name       = "K3S hcloud - Provisionning SSH key"
  public_key = var.ssh_key
}


resource "hcloud_network" "k8s_net" {
  name     = "k8s-net"
  ip_range = "10.10.0.0/16"
}

resource "hcloud_network_subnet" "k8s_main_subnet" {
  network_id   = hcloud_network.k8s_net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.10.1.0/24"
}


resource "hcloud_server" "workers" {
  count = length(var.worker_names)
  # name  = "${element(var.worker_names, count.index)}.${var.cluster_subdomain}"
  name  = element(var.worker_names, count.index)
  server_type = var.worker_server_type
  image = "ubuntu-20.04"
  location = "hel1"
  ssh_keys = [hcloud_ssh_key.id_stagiaire.id]

  depends_on = [
    hcloud_network_subnet.k8s_main_subnet
  ]
}

resource "hcloud_server_network" "worker_networks" {
  count = length(hcloud_server.workers)
  server_id  = element(hcloud_server.workers.*.id, count.index)
  network_id = hcloud_network.k8s_net.id
  ip         = "10.10.1.1${count.index}"
  depends_on = [
    hcloud_network_subnet.k8s_main_subnet
  ]
}



# resource "hcloud_floating_ip" "workers" {
#   count = length(var.worker_names)
#   name  = "${element(var.worker_names, count.index)}-ip"
#   type      = "ipv4"
#   server_id = hcloud_server.node1.id
# }

resource "hcloud_server" "controllers" {
  count = length(var.controller_names)
  # name  = "${element(var.controller_names, count.index)}.${var.cluster_subdomain}"
  name  = element(var.controller_names, count.index)
  server_type = var.controller_server_type 
  image = "ubuntu-20.04"
  location = "hel1"
  ssh_keys = [hcloud_ssh_key.id_stagiaire.id]

  depends_on = [
    hcloud_network_subnet.k8s_main_subnet
  ]
}

resource "hcloud_server_network" "controller_networks" {
  count = length(hcloud_server.controllers)
  server_id  = element(hcloud_server.controllers.*.id, count.index)
  network_id = hcloud_network.k8s_net.id
  ip         = "10.10.1.10${count.index}"
  depends_on = [
    hcloud_network_subnet.k8s_main_subnet
  ]
}

output "workers" {
  value = hcloud_server.workers
}

output "worker_networks" {
  value = hcloud_server_network.worker_networks
}

output "controllers" {
  value = hcloud_server.controllers
}

output "controller_networks" {
  value = hcloud_server_network.controller_networks
}

# output "controller_public_ips" {
#   value = hcloud_server.controllers.*.ipv4_address
# }

# output "worker_public_ips" {
#   value = hcloud_server.workers.*.ipv4_address
# }
