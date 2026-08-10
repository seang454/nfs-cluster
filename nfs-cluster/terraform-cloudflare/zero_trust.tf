# Identity providers + access policies + MFA requirement.
# Example: only @example.com accounts, with MFA, can reach admin.example.com.

resource "cloudflare_zero_trust_access_identity_provider" "google" {
  count      = var.enable_zero_trust ? 1 : 0
  account_id = var.account_id
  name       = "Google Workspace"
  type       = "google"

  config = {
    client_id     = var.google_oauth_client_id
    client_secret = var.google_oauth_client_secret
  }
}

resource "cloudflare_zero_trust_access_identity_provider" "github" {
  count      = var.enable_zero_trust ? 1 : 0
  account_id = var.account_id
  name       = "GitHub"
  type       = "github"

  config = {
    client_id     = var.github_oauth_client_id
    client_secret = var.github_oauth_client_secret
  }
}

# Azure AD example (uncomment and supply tenant/client details to use):
# resource "cloudflare_zero_trust_access_identity_provider" "azure_ad" {
#   count      = var.enable_zero_trust ? 1 : 0
#   account_id = var.account_id
#   name       = "Azure AD"
#   type       = "azureAD"
#   config = {
#     client_id     = var.azure_ad_client_id
#     client_secret = var.azure_ad_client_secret
#     directory_id  = var.azure_ad_tenant_id
#   }
# }

resource "cloudflare_zero_trust_access_policy" "allow_company_domain_with_mfa" {
  count = var.enable_zero_trust ? 1 : 0

  account_id     = var.account_id
  name           = "Allow ${join(",", var.access_allowed_email_domains)} with MFA"
  decision       = "allow"

  include = [
    {
      email_domain = {
        domain = var.access_allowed_email_domains[0]
      }
    }
  ]

  require = [
    {
      auth_method = {
        auth_method = "mfa"
      }
    }
  ]
}
