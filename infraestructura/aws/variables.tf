variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "ID de la AMI Ubuntu 22.04 (varía por región)"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "ssh_public_key_path" {
  description = "Ruta a la clave SSH pública"
  type        = string
  default     = "~/.ssh/valetsgo_key.pub"
}
