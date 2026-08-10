provider "cloudflare" {
  # Leave cloudflare_api_token blank in terraform.tfvars to use the
  # CLOUDFLARE_API_TOKEN environment variable instead.
  api_token = var.cloudflare_api_token != null && var.cloudflare_api_token != "" ? var.cloudflare_api_token : null
}
