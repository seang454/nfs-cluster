# The provider is the bridge between Terraform and a service.
/*
Terraform code
   |
   v
Google provider
   |
   v
GCP API
   |
   v
Real GCP VM/firewall/network

*/
# Configure Terraform itself.
terraform {
  # Require Terraform CLI version 1.4.0 or newer.
  required_version = ">= 1.4.0"

  # Tell Terraform which provider plugins this project needs.
  required_providers {
    # Use the Google Cloud provider.
    google = {
      # Download the provider from the official HashiCorp namespace.
      source = "hashicorp/google"

      # Allow any Google provider version from 5.0 up to, but not including, 6.0.
      version = "~> 5.0"
    }

    # Used only to write the generated Ansible inventory file on this machine.
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    # Used to create Cloudflare DNS records for service subdomains.
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.19"
    }

    # Used to generate a local SSH key pair when configured key files are missing.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Configure the Google Cloud provider.
# This is what lets Terraform connect to your GCP account.
provider "google" {
  # GCP project where Terraform will create resources.
  project = var.project_id

  # Default GCP region for regional resources.
  region = var.region

  # Recommended: leave gcp_adc_file empty so Google's ADC discovery selects
  # the credentials of whichever user runs Terraform.
  #
  # Optional: a path beginning with "~" is expanded to that user's home
  # directory, for example ~/.config/gcloud/application_default_credentials.json.
  credentials = trimspace(var.gcp_adc_file) != "" ? file(pathexpand(trimspace(var.gcp_adc_file))) : null
}

# Configure the Cloudflare provider.
# Prefer setting CLOUDFLARE_API_TOKEN in your shell instead of storing the token in terraform.tfvars.
provider "cloudflare" {
  api_token = var.cloudflare_api_token != "" ? var.cloudflare_api_token : null
}
