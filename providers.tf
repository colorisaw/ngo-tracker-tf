provider "aws" {
  region = var.aws_region

  access_key = local.is_localstack ? local.localstack_access_key : null
  secret_key = local.is_localstack ? local.localstack_secret_key : null

  skip_credentials_validation = local.is_localstack
  skip_metadata_api_check     = local.is_localstack
  skip_requesting_account_id  = local.is_localstack

  s3_use_path_style = local.is_localstack

  default_tags {
    tags = local.common_tags
  }

  # FinOps: endpoints sobrescritos apenas quando use_localstack = true
  dynamic "endpoints" {
    for_each = local.is_localstack ? [var.localstack_endpoint] : []
    content {
      apigateway     = endpoints.value
      apigatewayv2   = endpoints.value
      autoscaling    = endpoints.value
      cloudformation = endpoints.value
      cloudwatchlogs = endpoints.value
      dynamodb       = endpoints.value
      ec2            = endpoints.value
      ecr            = endpoints.value
      ecs            = endpoints.value
      eks            = endpoints.value
      elasticache    = endpoints.value
      elb            = endpoints.value
      elbv2          = endpoints.value
      events         = endpoints.value
      iam            = endpoints.value
      kinesis        = endpoints.value
      kms            = endpoints.value
      lambda         = endpoints.value
      rds            = endpoints.value
      route53        = endpoints.value
      s3             = endpoints.value
      secretsmanager = endpoints.value
      sns            = endpoints.value
      sqs            = endpoints.value
      ssm            = endpoints.value
      sts            = endpoints.value
      #tag            = endpoints.value
    }
  }
}
