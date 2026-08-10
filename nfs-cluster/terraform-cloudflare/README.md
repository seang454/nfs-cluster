# terraform-cloudflare

Production-ready Terraform project for managing Cloudflare as code: DNS, SSL/TLS,
WAF, firewall rules, cache rules, rate limiting, load balancing, Cloudflare
Tunnel, Zero Trust / Access, Workers, Pages, and Origin CA certificates.

Built for a GitOps workflow (Kubernetes + Helm + ArgoCD friendly) — Cloudflare
Tunnel gives you ingress into a cluster without exposing a LoadBalancer/public
IP, and everything else (WAF, cache, DNS) sits in front of it.

## Layout

```
terraform-cloudflare/
├── versions.tf              # required_providers + terraform block
├── providers.tf             # cloudflare provider config
├── variables.tf             # root input variables
├── outputs.tf                # root outputs
├── terraform.tfvars.example  # copy to terraform.tfvars and fill in
├── dns.tf                    # A/AAAA/CNAME/TXT/MX/NS/SRV/CAA records
├── ssl.tf                    # TLS mode, HSTS, always-https, min TLS version
├── waf.tf                    # managed rulesets (OWASP + Cloudflare managed)
├── firewall.tf               # custom firewall rules (block/allow/challenge)
├── cache.tf                  # cache rules, browser/edge TTL
├── rulesets.tf               # generic ruleset engine helper rules
├── rate_limit.tf              # rate limiting rules on sensitive paths
├── loadbalancer.tf            # multi-origin / multi-cluster load balancing
├── origin_ca.tf               # Cloudflare Origin CA certificate for the origin
├── workers.tf                 # Workers script + route
├── tunnels.tf                  # Cloudflare Tunnel + config + DNS CNAME
├── access.tf                   # Zero Trust Access applications
├── zero_trust.tf                # Zero Trust Access policies (identity, MFA)
├── pages.tf                     # Cloudflare Pages project
├── modules/
│   ├── dns/                     # reusable DNS record module
│   ├── tunnel/                  # reusable Cloudflare Tunnel module
│   └── waf/                     # reusable managed-ruleset module
├── environments/
│   ├── dev/terraform.tfvars
│   ├── staging/terraform.tfvars
│   └── production/terraform.tfvars
└── .github/workflows/terraform.yml
```

## Requirements

- Terraform >= 1.6
- Cloudflare provider ~> 5.0 (uses the newer `cloudflare_dns_record`,
  `cloudflare_ruleset`, `cloudflare_zero_trust_*` resource names)
- A Cloudflare API token (not the legacy Global API Key) with the zones,
  DNS, SSL, Firewall, Access, and Tunnel permissions you intend to manage

## Getting started

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: zone_id, account_id, domain, origin IP, etc.

terraform init
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

Use a remote backend (Terraform Cloud, S3+DynamoDB, or GCS) for real usage —
see the commented-out `backend` block in `versions.tf`.

## State per environment

This project uses one root module and swaps `-var-file` per environment
(`environments/dev|staging|production/terraform.tfvars`). If you want fully
isolated state per environment instead, either:

- use separate `terraform workspace` per env, or
- give each environment its own backend key/prefix, e.g.
  `key = "cloudflare/${env}/terraform.tfstate"`

## What's a full example vs. a stub

Every root `.tf` file compiles and shows the real resource shape for that
feature area. Some resources are gated behind `var.enable_*` flags (Zero
Trust, Load Balancer, Workers, Pages) since not every Cloudflare plan or
project needs all of them — flip the flag in your tfvars to turn a section on.

## Notes on plan limits

Some resources here (Load Balancing, advanced WAF managed rules, Argo Smart
Routing) require a Cloudflare Pro/Business/Enterprise plan. On a Free plan,
set the corresponding `enable_*` variable to `false`.
