# --- Terraform本体の設定(使用するプラグインのバージョン) ---
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- AWSプロバイダー設定(リージョン) ---
provider "aws" {
  region = var.aws_region
}
