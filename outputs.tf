output "cluster_datacenter" {
  value = data.vsphere_datacenter.dc
}

output "cluster_datastore" {
  value = data.vsphere_datastore.datastore
}

output "cluster_resource_pool" {
  value = data.vsphere_compute_cluster.cluster
}

output "cluster_network" {
  value = data.vsphere_network.network
}

output "cluster_vm_template" {
  value = data.vsphere_virtual_machine.template
}
