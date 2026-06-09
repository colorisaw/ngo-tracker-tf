# Tabela principal — design single-table (PK/SK) para ONGs, doações e metadados
resource "aws_dynamodb_table" "main" {
  name         = "${local.name_prefix}-main"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  # GSI opcional para consultas por tipo de entidade (ex.: todas as ONGs)
  attribute {
    name = "entity_type"
    type = "S"
  }

  global_secondary_index {
    name            = "entity-type-index"
    hash_key        = "entity_type"
    range_key       = "sk"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = !local.is_localstack
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-main"
  })
}
