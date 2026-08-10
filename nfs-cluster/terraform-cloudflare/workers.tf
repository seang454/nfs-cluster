# Cloudflare Worker + route. KV/D1/R2/Queues bindings shown as commented
# examples since they require you to first create the KV namespace / D1
# database / R2 bucket / queue resources.

resource "cloudflare_workers_script" "edge" {
  count      = var.enable_workers ? 1 : 0
  account_id = var.account_id
  script_name = "edge-worker"
  content    = file("${path.module}/workers/edge-worker.js")
  main_module = "edge-worker.js"

  # KV binding example:
  # bindings = [
  #   {
  #     name         = "MY_KV"
  #     type         = "kv_namespace"
  #     namespace_id = cloudflare_workers_kv_namespace.example[0].id
  #   },
  #   {
  #     name        = "MY_D1"
  #     type        = "d1"
  #     database_id = cloudflare_d1_database.example[0].id
  #   },
  #   {
  #     name        = "MY_BUCKET"
  #     type        = "r2_bucket"
  #     bucket_name = cloudflare_r2_bucket.example[0].name
  #   }
  # ]
}

resource "cloudflare_workers_route" "edge" {
  count       = var.enable_workers ? 1 : 0
  zone_id     = var.zone_id
  pattern     = var.worker_route_pattern
  script      = cloudflare_workers_script.edge[0].script_name
}

# Uncomment to provision backing resources for the bindings above.
#
# resource "cloudflare_workers_kv_namespace" "example" {
#   count      = var.enable_workers ? 1 : 0
#   account_id = var.account_id
#   title      = "edge-worker-kv"
# }
#
# resource "cloudflare_d1_database" "example" {
#   count      = var.enable_workers ? 1 : 0
#   account_id = var.account_id
#   name       = "edge-worker-db"
# }
#
# resource "cloudflare_r2_bucket" "example" {
#   count      = var.enable_workers ? 1 : 0
#   account_id = var.account_id
#   name       = "edge-worker-bucket"
# }
#
# resource "cloudflare_queue" "example" {
#   count      = var.enable_workers ? 1 : 0
#   account_id = var.account_id
#   name       = "edge-worker-queue"
# }
