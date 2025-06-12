# Configuração do provider Digital Ocean
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure o token da Digital Ocean
provider "digitalocean" {
  token = var.do_token
}

# Variáveis
variable "do_token" {
  description = "Token da Digital Ocean"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Nome da chave SSH na Digital Ocean"
  type        = string
  default     = "monitoring-key"
}

variable "region" {
  description = "Região da Digital Ocean"
  type        = string
  default     = "nyc1"
}

# Buscar chave SSH existente
data "digitalocean_ssh_key" "monitoring_key" {
  name = var.ssh_key_name
}




























# Criar Firewall
resource "digitalocean_firewall" "monitoring_firewall" {
  name = "monitoring-firewall"

  droplet_ids = [digitalocean_droplet.monitoring_server.id]

  # SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Grafana
  inbound_rule {
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Prometheus
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9090"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTP/HTTPS 
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Permitir todo tráfego de saída
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}


# Criar Droplet
resource "digitalocean_droplet" "monitoring_server" {
  image    = "ubuntu-22-04-x64"
  name     = "monitoring-server"
  region   = var.region
  size     = "s-1vcpu-1gb"
  ssh_keys = [data.digitalocean_ssh_key.monitoring_key.id]

  tags = ["monitoring", "terraform"]

  # Aguardar o droplet estar pronto
  provisioner "remote-exec" {
    inline = ["echo 'Droplet está pronto!'"]

    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      timeout     = "2m"
    }
  }
}








# Outputs
output "droplet_ip" {
  value       = digitalocean_droplet.monitoring_server.ipv4_address
  description = "IP público do droplet"
}

output "grafana_url" {
  value       = "http://${digitalocean_droplet.monitoring_server.ipv4_address}:3000"
  description = "URL do Grafana"
}

output "prometheus_url" {
  value       = "http://${digitalocean_droplet.monitoring_server.ipv4_address}:9090"
  description = "URL do Prometheus"
}