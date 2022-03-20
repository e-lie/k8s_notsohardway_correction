
variable "hcloud_dns_token" {}

variable "cluster_subdomain" {}

variable "worker_names" {}
variable "controller_names" {}
variable "worker_public_ips" {}
variable "controller_public_ips" {}


terraform {
  required_providers {
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = "2.1.0"
    }
  }
}

provider "hetznerdns" {
  # Configuration options
  apitoken = var.hcloud_dns_token
}


data "hetznerdns_zone" "dopluk" {
    name = "dopl.uk"
}

resource "hetznerdns_record" "worker_subdomains" {
  count = length(var.worker_names)
  zone_id = data.hetznerdns_zone.dopluk.id
  type   = "A"
  ttl = 3600
  name   = "${element(var.worker_names, count.index)}.${var.cluster_subdomain}"
  value  = element(var.worker_public_ips, count.index)
}

resource "hetznerdns_record" "workers_wildcard_subdomains" {
  count = length(var.worker_names)
  zone_id = data.hetznerdns_zone.dopluk.id
  type   = "A"
  ttl = 3600
  name   = "*.${element(var.worker_names, count.index)}.${var.cluster_subdomain}"
  value  = element(var.worker_public_ips, count.index)
}

resource "hetznerdns_record" "controller_subdomains" {
  count = length(var.worker_names)
  zone_id = data.hetznerdns_zone.dopluk.id
  type   = "A"
  ttl = 3600
  name   = "${element(var.controller_names, count.index)}.${var.cluster_subdomain}"
  value  = element(var.controller_public_ips, count.index)
}

resource "hetznerdns_record" "controller_wildcard_subdomains" {
    count = length(var.worker_names)
  zone_id = data.hetznerdns_zone.dopluk.id
  type   = "A"
  ttl = 3600
  name   = "*.${element(var.controller_names, count.index)}.${var.cluster_subdomain}"
  value  = element(var.controller_public_ips, count.index)
}

output "worker_domains" {
  value = hetznerdns_record.worker_subdomains.*.value
}

output "controller_domains" {
  value = hetznerdns_record.controller_subdomains.*.value
}