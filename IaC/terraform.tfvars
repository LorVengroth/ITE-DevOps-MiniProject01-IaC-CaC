project_id = "project-bd277efe-a49e-4d51-95f"

region  = "asia-east1"
zone    = "asia-east1-a"
network = "default"

ssh_user            = "ubuntu"
ssh_public_key_path = "/home/ubuntu/.ssh/gcp_key.pub"

boot_image     = "ubuntu-os-cloud/ubuntu-2204-lts"
boot_disk_size = 30

jenkins_machine_type   = "e2-medium"
sonarqube_machine_type = "e2-standard-2"
nexus_machine_type     = "e2-standard-2"

allowed_ports = ["22", "80", "443", "8080", "8081", "9000"]

allowed_source_ranges = ["0.0.0.0/0"]