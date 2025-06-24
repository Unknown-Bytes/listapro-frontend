variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.2-do.0"
}

variable "node_size" {
  description = "Size of the worker nodes"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "db_size" {
  description = "Database instance size"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "stage"
}
