terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  region = var.region
}

# Red Virtual en la Nube (VCN)
resource "oci_core_vcn" "valetsgo_vcn" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "valetsgo-vcn"
  dns_label      = "valetsgovcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "valetsgo_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.valetsgo_vcn.id
  display_name   = "valetsgo-igw"
  enabled        = true
}

# Tabla de rutas
resource "oci_core_route_table" "valetsgo_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.valetsgo_vcn.id
  display_name   = "valetsgo-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.valetsgo_igw.id
  }
}

# Lista de seguridad (puertos 22, 80, 443, 3001, 4000)
resource "oci_core_security_list" "valetsgo_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.valetsgo_vcn.id
  display_name   = "valetsgo-security-list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options { min = 22   max = 22   }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options { min = 80   max = 80   }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options { min = 443  max = 443  }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options { min = 3001 max = 3001 }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options { min = 4000 max = 4000 }
  }
}

# Subred pública
resource "oci_core_subnet" "valetsgo_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.valetsgo_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "valetsgo-subnet"
  dns_label         = "valetsgosubnet"
  route_table_id    = oci_core_route_table.valetsgo_rt.id
  security_list_ids = [oci_core_security_list.valetsgo_sl.id]
}

# Instancia VM — shape y disco configurables desde el wizard
resource "oci_core_instance" "valetsgo_vm" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = var.instance_shape
  display_name        = "valetsgo-server"

  dynamic "shape_config" {
    for_each = can(regex("Flex", var.instance_shape)) ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gb
    }
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.valetsgo_subnet.id
    assign_public_ip = true
    display_name     = "valetsgo-vnic"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(<<-EOF
      #!/bin/bash
      apt-get update -y
      apt-get install -y docker.io docker-compose
      systemctl enable docker
      systemctl start docker
      usermod -aG docker ubuntu
    EOF
    )
  }
}
