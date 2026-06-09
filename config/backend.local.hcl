# Backend remoto apontando para LocalStack (desenvolvimento sem custo AWS)
bucket         = "sre-terraform-state-local"
key            = "dev/terraform.tfstate"
region         = "us-east-1"
use_lockfile   = true

endpoints = {
  s3       = "http://localhost:4566"
  dynamodb = "http://localhost:4566"
}

skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
skip_requesting_account_id  = true
use_path_style              = true

access_key = "test"
secret_key = "test"
