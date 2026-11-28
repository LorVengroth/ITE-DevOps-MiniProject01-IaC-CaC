# ==========================================
# Instance Group
# ==========================================

resource "google_compute_instance_group" "app_services_ig" {
  name = "app-services-instance-group"
  zone = var.zone

  instances = [
    google_compute_instance.machine_02.id,
    google_compute_instance.machine_03.id
  ]

  named_port {
    name = "http"
    port = 80
  }
}

# ==========================================
# Health Check
# ==========================================

resource "google_compute_health_check" "app_http_health" {
  name = "app-http-health-check"

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# ==========================================
# Global Static IP Address
# ==========================================

resource "google_compute_global_address" "lb_ip" {
  name = "app-services-lb-ip"
}

# ==========================================
# Backend Service
# ==========================================

resource "google_compute_backend_service" "app_backend" {
  name                  = "app-services-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [
    google_compute_health_check.app_http_health.id
  ]

  backend {
    group = google_compute_instance_group.app_services_ig.id
  }
}

# ==========================================
# URL Map
# ==========================================

resource "google_compute_url_map" "app_url_map" {
  name            = "app-services-url-map"
  default_service = google_compute_backend_service.app_backend.id
}

# ==========================================
# HTTP Proxy
# ==========================================

resource "google_compute_target_http_proxy" "app_http_proxy" {
  name    = "app-services-http-proxy"
  url_map = google_compute_url_map.app_url_map.id
}

# ==========================================
# Global Forwarding Rule
# ==========================================

resource "google_compute_global_forwarding_rule" "app_http_forwarding_rule" {
  name                  = "app-services-http-rule"
  target                = google_compute_target_http_proxy.app_http_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}