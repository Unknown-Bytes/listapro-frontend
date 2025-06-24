output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = digitalocean_kubernetes_cluster.listapro_stage.endpoint
}

output "cluster_token" {
  description = "Kubernetes cluster token"
  value       = digitalocean_kubernetes_cluster.listapro_stage.kube_config[0].token
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = digitalocean_kubernetes_cluster.listapro_stage.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = digitalocean_kubernetes_cluster.listapro_stage.id
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = digitalocean_kubernetes_cluster.listapro_stage.name
}

output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = digitalocean_container_registry.listapro_stage_registry.endpoint
}

output "registry_name" {
  description = "Container registry name"
  value       = digitalocean_container_registry.listapro_stage_registry.name
}

output "database_host" {
  description = "Database host"
  value       = digitalocean_database_cluster.listapro_stage_db.host
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = digitalocean_database_cluster.listapro_stage_db.port
}

output "database_user" {
  description = "Database user"
  value       = digitalocean_database_cluster.listapro_stage_db.user
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = digitalocean_database_cluster.listapro_stage_db.password
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = digitalocean_database_cluster.listapro_stage_db.database
}

output "loadbalancer_ip" {
  description = "Load balancer IP address"
  value       = digitalocean_loadbalancer.listapro_stage_lb.ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.listapro_stage_vpc.id
}
