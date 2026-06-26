variable "project_id" {
  description = "ID del proyecto en GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP (usar us-central1 o us-west1 para Always Free)"
  type        = string
  default     = "us-central1"
}

variable "credentials_file" {
  description = "Ruta al archivo JSON de credenciales de GCP"
  type        = string
  default     = "~/.gcp/credentials.json"
}

variable "ssh_public_key_path" {
  description = "Ruta a la clave SSH pública"
  type        = string
  default     = "~/.ssh/valetsgo_key.pub"
}
