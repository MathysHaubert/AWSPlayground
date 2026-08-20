import json

def handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        print(f"Transaction reçue: {body}")
    return {"statusCode": 200}
