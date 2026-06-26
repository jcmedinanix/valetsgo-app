terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

# Red Virtual (VPC)
resource "google_compute_network" "valetsgo_vpc" {
  name                    = "valetsgo-vpc"
  auto_create_subnetworks = false
}

# Subred pública
resource "google_compute_subnetwork" "valetsgo_subnet" {
  name          = "valetsgo-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.valetsgo_vpc.id
}

# Firewall (puertos 22, 80, 443, 3001)
resource "google_compute_firewall" "valetsgo_fw" {
  name    = "valetsgo-firewall"
  network = google_compute_network.valetsgo_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["valetsgo-server"]
}

# Instancia e2-micro (Always Free)
resource "google_compute_instance" "valetsgo_vm" {
  name         = "valetsgo-server"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  tags         = ["valetsgo-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.valetsgo_subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
  EOF
}
