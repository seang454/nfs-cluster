terraform {
  required_version = ">= 1.6.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state (recommended). Uncomment and configure one backend.
  #
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "cloudflare/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
  #
  # backend "remote" {
  #   organization = "my-org"
  #   workspaces {
  #     name = "cloudflare-infra"
  #   }
  # }
}
