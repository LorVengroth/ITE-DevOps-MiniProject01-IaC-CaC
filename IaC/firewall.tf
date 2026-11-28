# ==========================================
# Allow DevOps Ports
# ==========================================

resource "google_compute_firewall" "allow_devops_ports" {
  name    = "allow-devops-ports"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  source_ranges = var.allowed_source_ranges
}

# ==========================================
# Allow Load Balancer Health Checks
# ==========================================

resource "google_compute_firewall" "allow_lb_health_checks" {
  name    = "allow-lb-health-checks"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "8081", "9000"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}