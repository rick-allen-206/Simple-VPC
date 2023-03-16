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


def put_data(value):
    response = client.put_item(
        TableName='vpc-metadata-table',
        Item=value
    )
    return response


def ordered(obj):
    if isinstance(obj, dict):
        return sorted((k, ordered(v)) for k, v in obj.items())
    if isinstance(obj, list):
        return sorted(ordered(x) for x in obj)
    else:
        return obj


def lambda_handler(event, context):

    ###
    # Variables
    ###
    dynamo_table_key = json.loads(event['dynamo_table_key'])
    dynamo_table_key_serialized = dynamo_serializer(dynamo_table_key)

    remote_dynamodb_data = get_data(dynamo_table_key_serialized)
    remote_dynamodb_item = remote_dynamodb_data.get(
        'Item', dynamo_serializer({'id': 'null'}))
    remote_value = dynamo_deserializer(remote_dynamodb_item)
    remote_ordered = ordered(remote_value)

    local_value = json.loads(event['local_value'])
    local_ordered = ordered(local_value)

    if local_ordered == remote_ordered:
        print('Exact match found!')
        return {}
    elif (
        local_value['id'] == remote_value['id'] and
        local_ordered != remote_ordered
    ):
        print('Matching ID found. Updating values ... ')
        output_value = put_data(dynamo_serializer(local_value))
        return output_value
    else:
        print('No match found. Creating DB entry ... ')
        output_value = put_data(dynamo_serializer(local_value))
        return output_value
