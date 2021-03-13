
locals {
  suffix = "-${lower(replace(var.suffix, "_", "-"))}"
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.k8s_network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.k8s_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_tag_category" "k8s_tags" {
  name        = "category-${cluster_name}${local.suffix}"
  description = "Tags for the ${cluster_name} Kubernetes Cluster (${local.suffix}) Managed by Terraform"
  cardinality = "MULTIPLE"

  associable_types = ["VirtualMachine", "Datastore"]
}

resource "vsphere_tag" "groups" {
  for_each = ["etcd", "k8s-cluster", "kube-node"]

  name        = each.key
  category_id = vsphere_tag_category.k8s_tags.id
}

resource "vsphere_custom_attribute" "attributes" {
  for_each = ["etcd_member_name", "ansible_host", "ip", "access_ip", "ansible_user"]

  name                = each.key
  managed_object_type = "VirtualMachine"
}

resource "vsphere_virtual_machine" "k8s_etcd_vms" {
  count = var.k8s_etcd_count

  # General Options
  name             = "k8s-etcd-${count.index}${local.suffix}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  # Disable the Guest Net waiter, and use the legacy Guest IP waiter instead
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 5
  enable_disk_uuid           = true
  hardware_version           = 15

  tags = [
    for tagname in compact(["etcd", local.suffix]) :
    vsphere_tag.groups[tagname].id
  ]

  custom_attributes = {
    for attr, value in {
      etcd_member_name = "k8s-etcd-${count.index}${local.suffix}"
      ansible_host     = cidrhost(var.k8s_vm_cidr_prefix, count.index)
      ip               = cidrhost(var.k8s_vm_cidr_prefix, count.index)
      access_ip        = cidrhost(var.k8s_vm_cidr_prefix, count.index)
      ansible_user     = var.k8s_vm_template_user
    } : vsphere_custom_attribute.attributes[attr].id => value
  }

  # CPU and Memory
  num_cpus = 2
  memory   = 4096

  # VMWare Tools Options
  sync_time_with_host = true

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 50
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "k8s-etcd-${count.index}${local.suffix}"
        domain    = var.cluster_domain_name
      }

      network_interface {
        ipv4_address = cidrhost(var.k8s_vm_cidr_prefix, count.index)
        ipv4_netmask = var.k8s_vm_netbits
      }

      ipv4_gateway    = var.k8s_default_gateway
      dns_server_list = var.k8s_dns_server
      dns_suffix_list = [var.internal_domain_name]
    }
  }

}

resource "vsphere_virtual_machine" "k8s_master_vms" {
  count = var.k8s_master_count

  # General Options
  name             = "k8s-master-${count.index}${local.suffix}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  # Disable the Guest Net waiter, and use the legacy Guest IP waiter instead
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 5
  enable_disk_uuid           = true
  hardware_version           = 15

  tags = [
    for tagname in compact(["k8s-cluster", "kube-master", "etcd", local.suffix]) :
    vsphere_tag.groups[tagname].id
  ]

  custom_attributes = {
    for attr, value in {
      etcd_member_name = "k8s-master-${count.index}${local.suffix}"
      ansible_host     = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count)
      ip               = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count)
      access_ip        = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count)
      ansible_user     = var.k8s_vm_template_user
    } : vsphere_custom_attribute.attributes[attr].id => value
  }

  # CPU and Memory
  num_cpus = 2
  memory   = 4096

  # VMWare Tools Options
  sync_time_with_host = true

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 50
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "k8s-master-${count.index}${local.suffix}"
        domain    = var.cluster_domain_name
      }

      network_interface {
        ipv4_address = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count)
        ipv4_netmask = var.k8s_vm_netbits
      }

      ipv4_gateway    = var.k8s_default_gateway
      dns_server_list = var.k8s_dns_server
      dns_suffix_list = [var.internal_domain_name]
    }
  }

}

resource "vsphere_virtual_machine" "k8s_worker_vms" {
  count = var.k8s_worker_count

  # General Options
  name             = "k8s-worker-${count.index}${local.suffix}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  # Disable the Guest Net waiter, and use the legacy Guest IP waiter instead
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 5
  enable_disk_uuid           = true
  hardware_version           = 15

  tags = [
    for tagname in compact(["k8s-cluster", "kube-node", local.suffix]) :
    vsphere_tag.groups[tagname].id
  ]

  custom_attributes = {
    for attr, value in {
      etcd_member_name = "k8s-worker-${count.index}${local.suffix}"
      ansible_host     = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count + var.k8s_master_count)
      ip               = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count + var.k8s_master_count)
      access_ip        = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count + var.k8s_master_count)
      ansible_user     = var.k8s_vm_template_user
    } : vsphere_custom_attribute.attributes[attr].id => value
  }

  # CPU and Memory
  num_cpus = 2
  memory   = 4096

  # VMWare Tools Options
  sync_time_with_host = true

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 50
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "k8s-master-${count.index}${local.suffix}"
        domain    = var.cluster_domain_name
      }

      network_interface {
        ipv4_address = cidrhost(var.k8s_vm_cidr_prefix, count.index + var.k8s_etcd_count + var.k8s_master_count)
        ipv4_netmask = var.k8s_vm_netbits
      }

      ipv4_gateway    = var.k8s_default_gateway
      dns_server_list = var.k8s_dns_server
      dns_suffix_list = [var.internal_domain_name]
    }
  }

}