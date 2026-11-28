output "public_ips" {
  value = {
    for vm in google_compute_instance.machines :
    vm.name => vm.network_interface[0].access_config[0].nat_ip
  }
}

output "private_ips" {
  value = {
    for vm in google_compute_instance.machines :
    vm.name => vm.network_interface[0].network_ip
  }
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.http.ip_address
}