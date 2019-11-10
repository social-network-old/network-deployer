# Substrate Container Variables | substrate variables.tf

variable "substrate_app_name" {
  type        = string
  description = "Name of Application Container"
  default     = "substrate"
}

variable "substrate_app_image" {
  type        = string
  description = "Docker image to run in the ECS cluster"
  default     = "socialnetwork/substrate:latest"
}

variable "substrate_app_port_1" {
  type        = string
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 30333
}

variable "substrate_app_port_2" {
  type        = string
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 9933
}

variable "substrate_app_port_3" {
  type        = string
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 9944
}

variable "substrate_app_count" {
  type        = string
  description = "Number of docker containers to run"
  default     = 2
}

variable "substrate_fargate_cpu" {
  type        = string
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "1024"
}

variable "substrate_fargate_memory" {
  type        = string
  description = "Fargate instance memory to provision (in MiB)"
  default     = "2048"
}
