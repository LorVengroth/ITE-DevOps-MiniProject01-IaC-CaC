terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}


// use this when use adc_file
provider "google" {
  credentials = file("${path.module}/credentials/adc.json")

  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "machines" {
  count = 3

  name         = "machine-0${count.index + 1}"
  machine_type = var.machine_type

  tags = ["devops-machine"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = var.network

    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "project-one-allow-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.control_node_cidr]
  target_tags   = ["devops-machine"]
}

resource "google_compute_firewall" "allow_internal_ssh" {
  name    = "project-one-internal-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["devops-machine"]
  target_tags = ["devops-machine"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "project-one-health-check"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = ["devops-machine"]
}

resource "google_compute_instance_group" "workers" {
  name = "project-one-workers"
  zone = var.zone

  instances = [
    google_compute_instance.machines[1].self_link,
    google_compute_instance.machines[2].self_link
  ]

  named_port {
    name = "http"
    port = 80
  }
}

# Health Check
resource "google_compute_health_check" "http" {
  name = "project-one-health"

  http_health_check {
    port = 80
  }
}

# Backend Service
resource "google_compute_backend_service" "backend" {
  name                  = "project-one-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [
    google_compute_health_check.http.id
  ]

  backend {
    group = google_compute_instance_group.workers.self_link
  }
}

# URL Map
resource "google_compute_url_map" "url_map" {
  name            = "project-one-url-map"
  default_service = google_compute_backend_service.backend.id
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "proxy" {
  name    = "project-one-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Forwarding Rule
resource "google_compute_global_forwarding_rule" "http" {
  name                  = "project-one-load-balancer"
  target                = google_compute_target_http_proxy.proxy.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
