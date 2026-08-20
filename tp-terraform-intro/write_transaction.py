import boto3
from botocore.exceptions import ClientError

# On force boto3 à parler à MiniStack au lieu du vrai AWS
dynamodb = boto3.resource(
    "dynamodb",
    endpoint_url="http://localhost:4566",
    region_name="eu-west-3",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)

table = dynamodb.Table("Transactions")

try:
    table.put_item(
        Item={
            "transaction_id": "txn-001",
            "amount": 4200,
            "currency": "EUR",
            "status": "completed",
        },
        ConditionExpression="attribute_not_exists(transaction_id)",
    )
    print("Écriture réussie")
except ClientError as e:
    print("Échec:", e.response["Error"]["Code"])
