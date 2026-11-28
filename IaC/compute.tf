# ==========================================
# Machine 01 - Jenkins
# ==========================================

resource "google_compute_instance" "machine_01" {
  name         = "machine-01-jenkins"
  machine_type = var.jenkins_machine_type

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size
    }
  }

  network_interface {
    network = var.network

    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(pathexpand(var.ssh_public_key_path))}"
  }
}

# ==========================================
# Machine 02 - SonarQube
# ==========================================

resource "google_compute_instance" "machine_02" {
  name         = "machine-02-sonarqube"
  machine_type = var.sonarqube_machine_type

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size
    }
  }

  network_interface {
    network = var.network

    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(pathexpand(var.ssh_public_key_path))}"
  }
}

# ==========================================
# Machine 03 - Nexus
# ==========================================

resource "google_compute_instance" "machine_03" {
  name         = "machine-03-nexus"
  machine_type = var.nexus_machine_type

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size
    }
  }

  network_interface {
    network = var.network

    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(pathexpand(var.ssh_public_key_path))}"
  }
}