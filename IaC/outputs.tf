output "machine_01_jenkins_public_ip" {
  description = "Jenkins VM Public IP"
  value       = google_compute_instance.machine_01.network_interface[0].access_config[0].nat_ip
}

output "machine_02_sonarqube_public_ip" {
  description = "SonarQube VM Public IP"
  value       = google_compute_instance.machine_02.network_interface[0].access_config[0].nat_ip
}

output "machine_03_nexus_public_ip" {
  description = "Nexus VM Public IP"
  value       = google_compute_instance.machine_03.network_interface[0].access_config[0].nat_ip
}

output "load_balancer_ip" {
  description = "Load Balancer Public IP"
  value       = google_compute_global_address.lb_ip.address
}