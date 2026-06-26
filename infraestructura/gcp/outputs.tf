output "instance_public_ip" {
  description = "IP pública de la instancia ValetsGo"
  value       = google_compute_instance.valetsgo_vm.network_interface[0].access_config[0].nat_ip
}

output "instance_id" {
  description = "ID de la instancia GCP"
  value       = google_compute_instance.valetsgo_vm.id
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = google_compute_network.valetsgo_vpc.id
}
