packer {
  required_plugins {
    docker = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "image_tag" {
  type    = string
  default = "v0.1.2"
}

source "docker" "ubuntu_base" {
  image  = "ubuntu:24.04"
  commit = true
}

build {
  name    = "ubuntu-hardened"
  sources = ["source.docker.ubuntu_base"]

  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends curl sudo",
      "useradd -m -s /usr/sbin/nologin app",
      "chmod 700 /home/app",
      "DEBIAN_FRONTEND=noninteractive apt-get purge -y -qq man-db manpages || true",
      "rm -rf /var/lib/apt/lists/*"
    ]
  }

  hcp_packer_registry {
    bucket_name   = "ubuntu-hardened"
    description   = "Hardened Ubuntu base image for Docker and HCP"
    bucket_labels = {
      project = "medium"
    }
    build_labels = {
      tag      = var.image_tag
      os       = "ubuntu"
      hardened = "true"
      version  = "24.04"
    }
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "repping/ubuntu_hardened"
      tags       = [var.image_tag]
    }

    post-processor "docker-push" {
      login = false
    }
  }
}
