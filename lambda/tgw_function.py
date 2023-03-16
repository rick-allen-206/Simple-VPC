import os
import json
import boto3
from boto3.dynamodb.types import TypeDeserializer, TypeSerializer

client = boto3.client('dynamodb')


def dynamo_deserializer(dynamo_obj):
    deserializer = TypeDeserializer()
    return {
        k: deserializer.deserialize(v)
        for k, v in dynamo_obj.items()
    }


def dynamo_serializer(python_obj):
    serializer = TypeSerializer()
    return {
        k: serializer.serialize(v)
        for k, v in python_obj.items()
    }


def get_data(key):
    response = client.get_item(
        TableName='vpc-metadata-table',
        Key=key
    )
    return response


def lambda_handler(event, context):

    ###
    # Variables
    ###
    dynamo_table_key = json.loads(os.environ['dynamo_table_key'])
    dynamo_table_key_serialized = dynamo_serializer(dynamo_table_key)

    remote_dynamodb_data = get_data(dynamo_table_key_serialized)
    remote_dynamodb_item = remote_dynamodb_data.get(
        'Item', dynamo_serializer({'id': 'null'}))
    remote_value = dynamo_deserializer(remote_dynamodb_item)

    if remote_dynamodb_item != dynamo_serializer({'id': 'null'}):
        print('Network VPC found!')
        return remote_value
    else:
        print('Could not find Network VPC!')
        return {}
