packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ami_name" {
  type    = string
  default = "nebari-cirun-runner-ubuntu24"
}

variable "build_job_url" {
  type    = string
  default = "manual-build"
}

variable "commit_hash" {
  type    = string
  default = "unknown"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_name}-{{isotime \"20060102-1504\"}}"
  instance_type = var.instance_type
  region        = var.region

  source_ami = "ami-05f991c49d264708f" # Ubuntu 24.04 LTS us-west-2

  ssh_username = "ubuntu"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 100
    volume_type           = "gp3"
    iops                  = 6000
    throughput            = 250
    delete_on_termination = true
  }

  ami_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 100
    volume_type           = "gp3"
    iops                  = 6000
    throughput            = 250
    delete_on_termination = true
  }

  tags = {
    Name        = "Nebari CI Runner"
    Environment = "ci"
    OS_Version  = "Ubuntu 24.04"
    Built_With  = "Packer"
    Purpose     = "cirun.io runners"
    Project     = "nebari-cirun-images"
    BuildJob    = var.build_job_url
    CommitHash  = var.commit_hash
  }
}

build {
  name = "nebari-runner"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    script = "scripts/disable-upgrades.sh"
  }

  provisioner "shell" {
    script = "scripts/install-docker.sh"
  }

  provisioner "shell" {
    script = "scripts/setup-runner.sh"
  }

  provisioner "shell" {
    script = "scripts/preinstall-tools.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get autoremove -y",
      "sudo apt-get autoclean"
    ]
  }
}