terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "project-bd277efe-a49e-4d51-95f"
  region  = "asia-ea"
  zone    = "asia-east1-a"
}

resource "google_compute_firewall" "allow_devops_ports" {
  name    = "allow-devops-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "8081", "9000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "machine_01" {
  name         = "machine-01-jenkins"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/ubuntu/.ssh/gcp_key.pub")}"
  }
}

resource "google_compute_instance" "machine_02" {
  name         = "machine-02-sonarqube"
  machine_type = "e2-standard-2"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/ubuntu/.ssh/gcp_key.pub")}"
  }
}

resource "google_compute_instance" "machine_03" {
  name         = "machine-03-nexus"
  machine_type = "e2-standard-2"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/ubuntu/.ssh/gcp_key.pub")}"
  }
}