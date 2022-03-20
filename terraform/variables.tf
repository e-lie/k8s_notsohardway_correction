variable "worker_names" {
  default = [
    "worker-0",
  ]
}

variable "controller_names" {
  default = [
    "controller-0",
    "controller-1",
    "controller-2",
  ]
}

variable "cluster_subdomain" {
  default = "k8slaab"
}

variable "hcloud_worker_server_type" {
  default = "cx21"
}

variable "hcloud_controller_server_type" {
  default = "cx21"
}