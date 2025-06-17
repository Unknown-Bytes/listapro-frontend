variable "do_token" {
    description =  "Token da Digital Ocean"
    type        =  string
    sensitive   =  true 
}

variable "region" {
    description =  "Regiao da Digital Ocean"
    type        =  string  
    default     =  "nyn1"
}

variable "ssh_key_name" {
    description =  "Nome da chave SSH"
    type        =  string
    default     =  "monitoring-key"
}