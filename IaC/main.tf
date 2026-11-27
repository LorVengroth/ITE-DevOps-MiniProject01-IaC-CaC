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
  region  = "asia-east1"
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

resource "google_compute_firewall" "allow_lb_health_checks" {
  name    = "allow-lb-health-checks"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8081", "9000"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
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

resource "google_compute_instance_group" "app_services_ig" {
  name = "app-services-instance-group"
  zone = "asia-east1-a"

  instances = [
    google_compute_instance.machine_02.id,
    google_compute_instance.machine_03.id,
  ]

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "app_http_health" {
  name = "app-http-health-check"

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_global_address" "lb_ip" {
  name = "app-services-lb-ip"
}

resource "google_compute_backend_service" "app_backend" {
  name                  = "app-services-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.app_http_health.id]

  backend {
    group = google_compute_instance_group.app_services_ig.id
  }
}

resource "google_compute_url_map" "app_url_map" {
  name            = "app-services-url-map"
  default_service = google_compute_backend_service.app_backend.id
}

resource "google_compute_target_http_proxy" "app_http_proxy" {
  name    = "app-services-http-proxy"
  url_map = google_compute_url_map.app_url_map.id
}

resource "google_compute_global_forwarding_rule" "app_http_forwarding_rule" {
  name                  = "app-services-http-rule"
  target                = google_compute_target_http_proxy.app_http_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}