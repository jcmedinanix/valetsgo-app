output "instance_public_ip" {
  description = "IP pública de la instancia ValetsGo"
  value       = oci_core_instance.valetsgo_vm.public_ip
}

output "instance_id" {
  description = "OCID de la instancia creada"
  value       = oci_core_instance.valetsgo_vm.id
}

output "vcn_id" {
  description = "OCID de la VCN creada"
  value       = oci_core_vcn.valetsgo_vcn.id
}
