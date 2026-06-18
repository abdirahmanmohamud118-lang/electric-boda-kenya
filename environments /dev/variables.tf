variable "environment" {
  type        = string
  description = "The deployment stage (e.g., dev, prod)"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment variable must be strictly set to either 'dev' or 'prod'."
  }
}

variable "email" {
  type        = string
  description = "The target email address for SNS operational battery alerts"
}