output "instance_public_ip" {
  description = "IP pública de la instancia ValetsGo"
  value       = aws_instance.valetsgo_vm.public_ip
}

output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.valetsgo_vm.id
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.valetsgo_vpc.id
}
