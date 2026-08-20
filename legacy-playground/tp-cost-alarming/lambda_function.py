import json

def handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        print(f"Transaction reçue: {body}")
    raise Exception("Erreur simulée pour tester CloudWatch")
