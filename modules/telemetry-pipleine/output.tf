output "kinesis_stream_arn" {
  value       = aws_kinesis_stream.telemetry_stream.arn
  description = "The ARN of the primary ingestion stream for metrics routing"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.telemetry_table.name
  description = "The name of the hot path live state table"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.analytics_bucket_name.arn
  description = "The ARN of the cold path analytical data lake"
}