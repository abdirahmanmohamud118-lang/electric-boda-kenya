####################################################
# s3 storage bucket for data lake 
####################################################

resource "aws_s3_bucket" "analytics_bucket_name" {
  bucket = "${var.analytics_bucket_name}-${var.environment}"


}

resource "aws_s3_bucket_versioning" "analytics_versioning" {
  bucket = aws_s3_bucket.analytics_bucket_name.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_encryption" {
  bucket = aws_s3_bucket.analytics_bucket_name.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "analytics_public_access" {
  bucket = aws_s3_bucket.analytics_bucket_name.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



####################################################
# dynamodb table for hot path storage
####################################################

resource "aws_dynamodb_table" "telemetry_table" {
  name           = "electric-boda-${var.environment}-telemetry"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "boda_id"

  attribute {
    name = "boda_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}
 


####################################################
# kinesis stream for telemetry data
####################################################

resource "aws_kinesis_stream" "telemetry_stream" {
  name             = "${var.project_name}-${var.environment}-telemetry-kinesis-stream"
  retention_period = 24

  
  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

 
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "${var.project_name}-${var.environment}-extended-s3-stream-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.telemetry_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.analytics_bucket_name.arn
    compression_format = "UNCOMPRESSED"
    buffering_size   = 5
    buffering_interval = 600
  }
}



##############################################
# iot core rule for telemetry data ingestion
##############################################

resource "aws_iot_topic_rule" "rule" {

  name        = "${var.project_name}-${var.environment}_iot_telemetry_rule"
  enabled     = true
  sql         = "SELECT * FROM 'boda/+/telemetry'"
  sql_version = "2016-03-23"
kinesis {
  stream_name = aws_kinesis_stream.telemetry_stream.name
  role_arn = aws_iam_role.iot_role.arn
 partition_key = "$${topic(2)}"
}
}



##############################################
# compute resource lambda
##############################################
data "archive_file" "telemetry_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src/lambda_function.zip"
}

resource "aws_lambda_function" "telemetry_processor" {
  filename         = data.archive_file.telemetry_lambda_zip.output_path
  function_name    = "electric-boda-${var.environment}-telemetry-processor"
  role             = aws_iam_role.lambda_role.arn 
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.telemetry_lambda_zip.output_base64sha256

  runtime = "python3.14"

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.telemetry_table.name
      ENVIRONMENT = var.environment
    }
  }

}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.telemetry_stream.arn
  function_name     = aws_lambda_function.telemetry_processor.arn
  starting_position = "LATEST"
  batch_size        = 100
}

resource "aws_s3_object" "athena_results" {
  bucket = aws_s3_bucket.analytics_bucket_name.id
  key    = "athena-results/"
}

resource "aws_athena_database" "telemetry_database" {
  name          = "electric_boda_${var.environment}_telemetry_db"
  bucket        = aws_s3_bucket.analytics_bucket_name.id
  force_destroy = true
}

resource "aws_athena_workgroup" "telemetry_workgroup" {
  name          = "electric-boda-${var.environment}-athena-workgroup"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = 104857600

    result_configuration {
      output_location = "s3://${aws_s3_bucket.analytics_bucket_name.id}/${aws_s3_object.athena_results.key}"
      
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}