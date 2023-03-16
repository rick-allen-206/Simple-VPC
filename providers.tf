# ─── Backend ──────────────────────────────────────────────────────────────────


terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.38.0"
      configuration_aliases = [aws, aws.network]
    }
  }
}


# ──────────────────────────────────────────────────────────────────────────────

