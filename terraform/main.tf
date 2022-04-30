variable "hcloud_token" {}
variable "hcloud_dns_token" {}

module "servers" {
  source = "./hcloud_infra"

  hcloud_token              = var.hcloud_token
  cluster_subdomain       = var.cluster_subdomain
  worker_names          = var.worker_names
  controller_names          = var.controller_names
  worker_server_type           = var.hcloud_worker_server_type
  controller_server_type     = var.hcloud_controller_server_type
  ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBXHgv6fDeMM/zbqXpzdANeNbltG74+2Q1pBC9CXRc0M stagiaire-id"
}

module "domains" {
  source                    = "./hcloud_dns"
  hcloud_dns_token        = var.hcloud_dns_token
  cluster_subdomain       = var.cluster_subdomain
  worker_names          = var.worker_names
  controller_names          = var.controller_names
  worker_public_ips          = module.servers.worker_public_ips
  controller_public_ips          = module.servers.controller_public_ips
  workers = module.servers.workers
  controllers = module.servers.controllers
}

# module "ansible_hosts" {
#   source                    = "./ansible_hosts"
#   # worker_names          = var.worker_names
#   worker_domains     = module.domains.worker_domains
#   controller_domains     = module.domains.controller_domains
#   # controller_names          = var.controller_names
#   # worker_public_ips = module.servers.worker_public_ips
#   workers = module.servers.workers
#   worker_networks = module.servers.worker_networks
#   controllers = module.servers.controllers
#   controller_networks = module.servers.controller_networks
#   # controller_public_ips = module.servers.controller_public_ips
# }