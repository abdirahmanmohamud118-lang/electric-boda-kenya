variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'prod')."
  type        = string
  default     = "dev"


  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be one of 'dev' or 'prod'."
  }
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "electric-boda-kenya"
}


variable "kinesis_shard_count" {
  description = "The number of shards for the Kinesis stream."
  type        = number
  default     = 1
}


variable "kinesis_retention_period_hours" {
  description = "The retention period for the Kinesis stream in hours."
  type        = number
  default     = 24
}



variable "analytics_bucket_name" {
  description = "The name of the S3 bucket for long-term telemetry storage"
  type        = string
}

variable "battery_threshold" {
  description = "The battery level threshold for alerts (in percentage) for the boda "
  type        = number
  default     = 15
}


variable "alert_email" {
  description = "The email address to send alerts to."
  type        = string
}