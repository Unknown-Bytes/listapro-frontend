# Alternativa: usar data sources para recursos existentes

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

# Se o Artifact Registry já existe, use um data source
data "google_artifact_registry_repository" "existing_listapro_prod_repo" {
  location      = var.region
  repository_id = "listapro-prod-repo"
  project       = var.project_id
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

output "existing_registry_url" {
  description = "Existing Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${data.google_artifact_registry_repository.existing_listapro_prod_repo.repository_id}"
}
