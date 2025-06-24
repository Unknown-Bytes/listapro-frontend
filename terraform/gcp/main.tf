terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Enable required APIs
resource "google_project_service" "container_api" {
  service = "container.googleapis.com"
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "artifactregistry_api" {
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "sql_api" {
  service = "sql-component.googleapis.com"
}

# VPC Network (comentado - usando data source)
# resource "google_compute_network" "listapro_prod_vpc" {
#   name                    = "listapro-prod-vpc"
#   auto_create_subnetworks = false
# 
#   depends_on = [google_project_service.compute_api]
# }

# Subnet (comentado - usando data source)
# resource "google_compute_subnetwork" "listapro_prod_subnet" {
#   name          = "listapro-prod-subnet"
#   ip_cidr_range = "10.0.0.0/16"
#   region        = var.region
#   network       = data.google_compute_network.existing_listapro_prod_vpc.name
# 
#   secondary_ip_range {
#     range_name    = "pods"
#     ip_cidr_range = "10.1.0.0/16"
#   }
# 
#   secondary_ip_range {
#     range_name    = "services"
#     ip_cidr_range = "10.2.0.0/16"
#   }
# }

# GKE Cluster
resource "google_container_cluster" "listapro_prod" {
  name     = "listapro-prod-cluster"
  location = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = data.google_compute_network.existing_listapro_prod_vpc.name
  subnetwork = data.google_compute_subnetwork.existing_listapro_prod_subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled = true
  }

  # Monitoring and logging
  monitoring_config {
    managed_prometheus {
      enabled = true
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  depends_on = [google_project_service.container_api]
}

# Node Pool
resource "google_container_node_pool" "listapro_prod_nodes" {
  name       = "listapro-prod-nodes"
  location   = var.zone
  cluster    = google_container_cluster.listapro_prod.name
  node_count = var.node_count

  node_config {
    preemptible  = false
    machine_type = var.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = data.google_service_account.existing_kubernetes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env     = "production"
      project = "listapro"
    }

    tags = ["listapro", "production"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account for Kubernetes (comentado - usando data source)
# resource "google_service_account" "kubernetes" {
#   account_id   = "listapro-prod-k8s-sa"
#   display_name = "Kubernetes Service Account for ListaPro Production"
#   
#   lifecycle {
#     ignore_changes = [
#       account_id,
#     ]
#   }
# }

# Artifact Registry (comentado - usando data source)
# resource "google_artifact_registry_repository" "listapro_prod_repo" {
#   location      = var.region
#   repository_id = "listapro-prod-repo"
#   description   = "Container repository for ListaPro Production"
#   format        = "DOCKER"
# 
#   depends_on = [google_project_service.artifactregistry_api]
# }

# Cloud SQL Instance (comentado - usando data source)
# resource "google_sql_database_instance" "listapro_prod_db" {
#   name             = "listapro-prod-db"
#   database_version = "POSTGRES_15"
#   region           = var.region
#   deletion_protection = false
# 
#   settings {
#     tier = var.db_tier
# 
#     backup_configuration {
#       enabled                        = true
#       start_time                     = "04:00"
#       point_in_time_recovery_enabled = true
#     }
# 
#     maintenance_window {
#       day  = 7
#       hour = 4
#     }
# 
#     ip_configuration {
#       ipv4_enabled = true
#       
#       authorized_networks {
#         value = "0.0.0.0/0"
#         name  = "all"
#       }
#     }
# 
#     disk_autoresize = true
#     disk_size       = 20
#     disk_type       = "PD_SSD"
#   }
# 
#   depends_on = [google_project_service.sql_api]
# }

# Database (comentado - usando data source)
# resource "google_sql_database" "listapro_prod_database" {
#   name     = "listapro"
#   instance = data.google_sql_database_instance.existing_listapro_prod_db.name
# }

# Database User
resource "google_sql_user" "listapro_prod_user" {
  name     = "listapro"
  instance = data.google_sql_database_instance.existing_listapro_prod_db.name
  password = var.db_password
}

# Firewall rules (comentado - usando data source)
# resource "google_compute_firewall" "listapro_prod_firewall" {
#   name    = "listapro-prod-firewall"
#   network = data.google_compute_network.existing_listapro_prod_vpc.name
# 
#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443", "3000", "3001", "9090"]
#   }
# 
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["listapro", "production"]
# }

# External IP for Load Balancer (comentado - usando data source)
# resource "google_compute_global_address" "listapro_prod_ip" {
#   name = "listapro-prod-ip"
#   
#   lifecycle {
#     ignore_changes = [
#       name,
#     ]
#   }
# }
