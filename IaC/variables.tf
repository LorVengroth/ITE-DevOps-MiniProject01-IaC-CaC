variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-east1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-east1-a"
}

variable "network" {
  description = "VPC Network"
  type        = string
  default     = "default"
}

variable "ssh_user" {
  description = "SSH Username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH Public Key"
  type        = string
}

variable "boot_image" {
  description = "VM Operating System Image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
  description = "Boot Disk Size in GB"
  type        = number
  default     = 30
}

variable "jenkins_machine_type" {
  description = "Jenkins VM Machine Type"
  type        = string
  default     = "e2-medium"
}

variable "sonarqube_machine_type" {
  description = "SonarQube VM Machine Type"
  type        = string
  default     = "e2-standard-2"
}

variable "nexus_machine_type" {
  description = "Nexus VM Machine Type"
  type        = string
  default     = "e2-standard-2"
}

variable "allowed_ports" {
  description = "Allowed TCP Ports"
  type        = list(string)
  default     = ["22", "80", "443", "8080", "8081", "9000"]
}

variable "allowed_source_ranges" {
  description = "Allowed Source IP Ranges"
  type        = list(string)
}