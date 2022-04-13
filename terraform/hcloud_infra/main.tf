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

resource "hcloud_server" "workers" {
  count = length(var.worker_names)
  name  = "${element(var.worker_names, count.index)}.${var.cluster_subdomain}"
  server_type = var.worker_server_type
  image = "ubuntu-20.04"
  location = "hel1"
  ssh_keys = [hcloud_ssh_key.id_stagiaire.id]
}

resource "hcloud_server" "controllers" {
  count = length(var.controller_names)
  name  = "${element(var.controller_names, count.index)}.${var.cluster_subdomain}"
  server_type = var.controller_server_type 
  image = "ubuntu-20.04"
  location = "hel1"
  ssh_keys = [hcloud_ssh_key.id_stagiaire.id]
}

output "worker_public_ips" {
  value = hcloud_server.workers.*.ipv4_address
}

output "controller_public_ips" {
  value = hcloud_server.controllers.*.ipv4_address
}