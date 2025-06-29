# Data sources para todos os recursos existentes no GCP

# Se o Service Account já existe, use um data source
data "google_service_account" "existing_kubernetes" {
  account_id = "listapro-prod-k8s-sa"
  project    = var.project_id
}

# Se o IP Global já existe, use um data source  
data "google_compute_global_address" "existing_listapro_prod_ip" {
  name    = "listapro-prod-ip"
  project = var.project_id
}

# Se o VPC já existe, use um data source
data "google_compute_network" "existing_listapro_prod_vpc" {
  name    = "listapro-prod-vpc"
  project = var.project_id
}

# Se a Subnet já existe, use um data source
data "google_compute_subnetwork" "existing_listapro_prod_subnet" {
  name    = "listapro-prod-subnet"
  region  = var.region
  project = var.project_id
}

# Nota: O provider Google não suporta data source para firewall rules
# Se o Firewall já existe, ele deve ser gerenciado como resource ou importado
# data "google_compute_firewall" é inválido no provider hashicorp/google

# Se o Artifact Registry já existe, use um data source
data "google_artifact_registry_repository" "existing_listapro_prod_repo" {
  location      = var.region
  repository_id = "listapro-prod-repo"
  project       = var.project_id
}

# Se a instância do Cloud SQL já existe, use um data source
data "google_sql_database_instance" "existing_listapro_prod_db" {
  name    = "listapro-prod-db"
  project = var.project_id
}

# Se o database já existe, use um data source
data "google_sql_database" "existing_listapro_prod_database" {
  name     = "listapro"
  instance = data.google_sql_database_instance.existing_listapro_prod_db.name
  project  = var.project_id
}

# Outputs usando os recursos existentes
output "existing_service_account_email" {
  description = "Email of the existing Kubernetes service account"
  value       = data.google_service_account.existing_kubernetes.email
}

output "existing_global_ip" {
  description = "Existing global IP address"
  value       = data.google_compute_global_address.existing_listapro_prod_ip.address
}

output "existing_vpc_name" {
  description = "Existing VPC network name"
  value       = data.google_compute_network.existing_listapro_prod_vpc.name
}

output "existing_subnet_name" {
  description = "Existing subnet name"
  value       = data.google_compute_subnetwork.existing_listapro_prod_subnet.name
}

output "existing_registry_url" {
  description = "Existing Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.existing_listapro_prod_repo.repository_id}"
}

output "existing_db_connection_name" {
  description = "Existing Cloud SQL connection name"
  value       = data.google_sql_database_instance.existing_listapro_prod_db.connection_name
}

output "existing_database_name" {
  description = "Existing database name"
  value       = data.google_sql_database.existing_listapro_prod_database.name
}
