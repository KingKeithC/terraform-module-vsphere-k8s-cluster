variable "suffix" {
  type        = string
  default     = "main"
  description = "An optional string to append to the name of created objects. Recommend setting to the name of a git branch."
}

variable "datacenter_name" {
  description = "The name of the Datacenter in vSphere in which to operate."
}

variable "datastore_name" {
  description = "The datastore on which to place the VMs ans CSI PVs."
}

variable "cluster_name" {
  description = "The cluster in which to place the VMs."
}

variable "cluster_domain_name" {
  description = "The domain to append to the vm hostnames, and to use for the cluster."
}

variable "k8s_vm_template" {
  description = "The name of the VM to clone to make the k8s nodes."
}

variable "k8s_vm_template_user" {
  description = "The name of the user with which to connect to the k8s nodes."
}

variable "k8s_vm_cidr_prefix" {
  description = "A CIDR of IPs to use for the k8s node IP addresses."
}

variable "k8s_default_gateway" {
  description = "The default gateway for the hosts in the cluster."
}

variable "k8s_dns_servers" {
  type        = list(string)
  description = "The DND Servers for the hosts in the cluster."
}

variable "k8s_vm_netbits" {
  description = "The number of bits in the vm subnet mask."
  default     = 24
}

variable "k8s_network_name" {
  description = "The name of the network on which to connect the k8s-nodes."
}

variable "k8s_etcd_count" {
  description = "The number of etcd nodes to place in the cluster."
  default     = 1

  validation {
    condition     = var.k8s_etcd_count >= 1
    error_message = "The k8s_etcd_count value must be at least 1."
  }
}

variable "k8s_master_count" {
  description = "The number of master nodes to place in the cluster."
  default     = 1

  validation {
    condition     = var.k8s_master_count >= 1
    error_message = "The k8s_master_count value must be at least 1."
  }
}

variable "k8s_worker_count" {
  description = "The number of worker nodes to place in the cluster."
  default     = 2

  validation {
    condition     = var.k8s_worker_count >= 2
    error_message = "The k8s_worker_count value must be at least 2."
  }
}
