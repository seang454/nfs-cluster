# Cloudflare Pages project (React / Vue / Next.js / Angular static or SSR
# frontends). Connect it to a GitHub repo, or deploy via `wrangler pages
# deploy` / GitHub Actions and just manage the project shell here.

resource "cloudflare_pages_project" "frontend" {
  count             = var.enable_pages ? 1 : 0
  account_id        = var.account_id
  name              = var.pages_project_name
  production_branch = var.pages_production_branch

  build_config = {
    build_command   = "npm run build"
    destination_dir = "dist"
    root_dir        = "/"
  }

  deployment_configs = {
    production = {
      environment_variables = {
        NODE_VERSION = { value = "20" }
      }
    }
    preview = {
      environment_variables = {
        NODE_VERSION = { value = "20" }
      }
    }
  }
}

resource "cloudflare_pages_domain" "frontend" {
  count      = var.enable_pages ? 1 : 0
  account_id = var.account_id
  project_name = cloudflare_pages_project.frontend[0].name
  name     = "app.${var.domain}"
}
