import base64
import json
import os
import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('TABLE_NAME')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    logger.info(f"Processing batch of {len(event['Records'])} records from Kinesis.")
    
    with table.batch_writer() as batch:
        for record in event['Records']:
            try:
                boda_id = record['kinesis']['partitionKey']
                
                raw_payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
                telemetry_data = json.loads(raw_payload)
                
                logger.info(f"Processing telemetry for bike: {boda_id}")
                
                item = {
                    'boda_id': str(boda_id),
                    'timestamp': telemetry_data.get('timestamp'),
                    'battery_percentage': telemetry_data.get('battery_percentage'),
                    'latitude': telemetry_data.get('latitude'),
                    'longitude': telemetry_data.get('longitude'),
                    'speed': telemetry_data.get('speed'),
                    'status': telemetry_data.get('status', 'ACTIVE')
                }
                
                batch.put_item(Item=item)
                
            except json.JSONDecodeError as e:
                logger.error(f"Skipping record. Failed to parse JSON payload: {str(e)}")
                continue
            except ClientError as e:
                logger.error(f"DynamoDB Database Error: {e.response['Error']['Message']}")
                continue
            except Exception as e:
                logger.error(f"Unexpected processing error: {str(e)}")
                continue
                
    logger.info("Batch processing complete.")
    return {
        'statusCode': 200,
        'body': json.dumps('Successfully processed telemetry batch!')
    }