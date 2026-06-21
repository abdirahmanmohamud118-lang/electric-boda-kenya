output "analytics_bucket_name" {
  description = "The name of the S3 bucket for telemetry storage"
  value       = aws_s3_bucket.analytics_bucket_name.id
}

output "telemetry_table_name" {
  description = "The name of the DynamoDB table for hot path telemetry"
  value       = aws_dynamodb_table.telemetry_table.name
}

output "telemetry_processor_name" {
  description = "The name of the Lambda function processing the data"
  value       = aws_lambda_function.telemetry_processor.function_name
}

output "iot_rule_arn" {
  description = "The ARN of the IoT topic rule routing the data"
  value       = aws_iot_topic_rule.iot_to_lambda.arn
}