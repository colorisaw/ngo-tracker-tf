resource "aws_s3_bucket" "sre_terraform_state_aws_s3_bucket" {
  bucket = "sre-terraform-state"

  tags = {
    Name        = "SRE Terraform State"
    Environment = "dev"
  }
}