output "ruleset_id" {
  value       = cloudflare_ruleset.managed.id
  description = "ID of the managed ruleset created by this module."
}
