
import json
import boto3

secrets_client = boto3.client(
    "secretsmanager",
    endpoint_url="http://localstack:4566",
    region_name="eu-west-3",
)


def handler(event, context):
    secret_response = secrets_client.get_secret_value(
        SecretId="payment-partner-api-key"
    )
    secret = json.loads(secret_response["SecretString"])
    api_key = secret["api_key"]

    print(f"Clé API récupérée, se termine par: ...{api_key[-6:]}")

    for record in event["Records"]:
        body = json.loads(record["body"])
        print(f"Transaction reçue: {body}")

    return {"statusCode": 200}
