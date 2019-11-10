# Monitoring variables | variables-monitoring.tf

variable "monitoring_username" {
  type        = string
  description = "Username used to authenticate to monitoring container"
  default     = "ec2-user"
}

variable "prometheus_pagerduty_key" {
  type        = string
  description = "Key for Prometheus-PagerDuty integration"
  default     = ""
}

variable "monitoring_snapshot" {
  type        = string
  description = "EBS snapshot ID to initialise monitoring data with"
  default     = ""
}

variable "cloudwatch_logs" {
  type        = string
  description = "Send container logs to CloudWatch"
  default     = false
}
