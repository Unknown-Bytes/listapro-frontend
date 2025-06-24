terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# VPC para isolamento de rede
resource "digitalocean_vpc" "listapro_stage_vpc" {
  name     = "listapro-stage-vpc"
  region   = var.region
  ip_range = "10.10.0.0/16"

  tags = ["listapro", "stage", "vpc"]
}

# Cluster Kubernetes
resource "digitalocean_kubernetes_cluster" "listapro_stage" {
  name     = "listapro-stage-cluster"
  region   = var.region
  version  = var.k8s_version
  vpc_uuid = digitalocean_vpc.listapro_stage_vpc.id

  tags = ["listapro", "stage", "k8s"]

  node_pool {
    name       = "listapro-stage-pool"
    size       = var.node_size
    node_count = var.node_count

    tags = ["listapro", "stage", "worker"]
  }

  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }
}

# Container Registry
resource "digitalocean_container_registry" "listapro_stage_registry" {
  name                   = "listapro-stage-registry"
  subscription_tier_slug = "basic"
  region                 = var.region

  tags = ["listapro", "stage", "registry"]
}

# Firewall para segurança
resource "digitalocean_firewall" "listapro_stage_firewall" {
  name = "listapro-stage-firewall"

  tags = [digitalocean_kubernetes_cluster.listapro_stage.id]

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

  inbound_rule {
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Grafana
  inbound_rule {
    protocol         = "tcp"
    port_range       = "3001"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Prometheus
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9090"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

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
}

# Load Balancer para a aplicação
resource "digitalocean_loadbalancer" "listapro_stage_lb" {
  name   = "listapro-stage-lb"
  region = var.region
  size   = "lb-small"

  vpc_uuid = digitalocean_vpc.listapro_stage_vpc.id

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 3000
  }

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 3001
    target_protocol = "http"
    target_port     = 3001
  }

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 9090
    target_protocol = "http"
    target_port     = 9090
  }

  healthcheck {
    protocol = "http"
    port     = 3000
    path     = "/"
  }

  tags = ["listapro", "stage", "loadbalancer"]
}

# Database (PostgreSQL)
resource "digitalocean_database_cluster" "listapro_stage_db" {
  name       = "listapro-stage-db"
  engine     = "pg"
  version    = "15"
  size       = var.db_size
  region     = var.region
  node_count = 1

  private_network_uuid = digitalocean_vpc.listapro_stage_vpc.id

  tags = ["listapro", "stage", "database"]
}

# Database Firewall
resource "digitalocean_database_firewall" "listapro_stage_db_firewall" {
  cluster_id = digitalocean_database_cluster.listapro_stage_db.id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.listapro_stage.id
  }
}
