import json
import decimal
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE_NAME']
table = dynamodb.Table(table_name)

def decimal_default(obj):
    if isinstance(obj, decimal.Decimal):
        return float(obj)
    raise TypeError

def get_items_by_username(username):
    try:
        response = table.query(
            KeyConditionExpression=Key('username').eq(username)
        )
        return response['Items']
    except Exception as e:
        print(f"Error fetching items: {str(e)}")
        return []

def lambda_handler(event, context):
    if 'username' not in event:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing username parameter'})
        }
    
    username = event['username']
    items = get_items_by_username(username)
    
    return {
        'statusCode': 200,
        'body': json.dumps(items, default=decimal_default)
    }