variable "region" {
  description = "Región de OCI"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "compartment_id" {
  description = "OCID del compartment raíz de OCI"
  type        = string
  default     = "ocid1.tenancy.oc1..aaaaaaaacrc3lxiedqv6deidtu6wsibm2m2iacwrkyoz2wfwx6vtl3ylgw7a"
}

variable "availability_domain" {
  description = "Dominio de disponibilidad"
  type        = string
  default     = "XkLi:SA-SAOPAULO-1-AD-1"
}

variable "image_id" {
  description = "OCID de la imagen Ubuntu 22.04"
  type        = string
  default     = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaagbb3ikg7maknou7bnigb34coc3hbgthknlfluaj4qypvnxkexsba"
}

variable "ssh_public_key_path" {
  description = "Ruta a la clave SSH pública"
  type        = string
  default     = "~/.ssh/valetsgo_key.pub"
}

variable "instance_shape" {
  description = "Shape de la instancia (default: Always Free)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "instance_ocpus" {
  description = "Número de OCPUs (solo para shapes Flex)"
  type        = number
  default     = 1
}

variable "instance_memory_gb" {
  description = "Memoria RAM en GB (solo para shapes Flex)"
  type        = number
  default     = 1
}

variable "boot_volume_size_gb" {
  description = "Tamaño del disco de arranque en GB"
  type        = number
  default     = 50
}
