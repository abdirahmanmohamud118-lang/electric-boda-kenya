terraform {
  backend "s3" {
    bucket         = "electric-boda-terraform-state-2026"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "electric_boda" {
  source = "../../modules/telemetry-pipleine"
  alert_email  = "${var.email}"
  environment = "${var.environment}"
  analytics_bucket_name = "electric-boda-${var.environment}"

}