output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.listapro_prod.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.listapro_prod.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.listapro_prod.name
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.listapro_prod.location
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.listapro_prod_repo.repository_id}"
}

output "database_connection_string" {
  description = "Database connection string"
  value       = "postgresql://${google_sql_user.listapro_prod_user.name}:${google_sql_user.listapro_prod_user.password}@${google_sql_database_instance.listapro_prod_db.public_ip_address}:5432/${google_sql_database.listapro_prod_database.name}"
  sensitive   = true
}

output "database_host" {
  description = "Database host"
  value       = google_sql_database_instance.listapro_prod_db.public_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.listapro_prod_database.name
}

output "database_user" {
  description = "Database user"
  value       = google_sql_user.listapro_prod_user.name
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = google_sql_user.listapro_prod_user.password
  sensitive   = true
}

output "external_ip" {
  description = "External IP address"
  value       = google_compute_global_address.listapro_prod_ip.address
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.listapro_prod_vpc.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.listapro_prod_subnet.name
}
