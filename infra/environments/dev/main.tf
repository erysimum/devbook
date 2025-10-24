terraform {
  backend "s3" {} # values injected at init via -backend-config=backend.hcl
}

provider "aws" {
  region = var.region
}

# Placeholder to prove remote backend works
output "hello" {
  value = "Remote backend is configured for ${var.project_name}-${var.env}"
}
