import socket
import ssl
import datetime
import json


def lambda_handler(event, context):
    try:
        hostname = event["queryStringParameters"]["hostname"]
    except KeyError:
        return {
            "statusCode": 400,
            "body": "error, must provide hostname via querystring",
        }
    try:
        hostname = event["queryStringParameters"]["hostname"]
        ssl_date_fmt = r"%b %d %H:%M:%S %Y %Z"

        context = ssl.create_default_context()
        conn = context.wrap_socket(
            socket.socket(socket.AF_INET),
            server_hostname=hostname,
        )
        conn.settimeout(3.0)
        conn.connect((hostname, 443))
        ssl_info = conn.getpeercert()
        expiration_date = datetime.datetime.strptime(ssl_info["notAfter"], ssl_date_fmt)
        time_delta = expiration_date - datetime.datetime.utcnow()
        expired = time_delta < datetime.timedelta(days=0)
        expires_in_less_than_30_days = time_delta < datetime.timedelta(days=30)
        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "expiration_date": str(expiration_date),
                    "days_remaining": str(time_delta.days),
                    "expired": expired,
                    "expires_in_less_than_30_days": expires_in_less_than_30_days,
                }
            ),
        }
    except:
        return {"statusCode": 500, "body": "error"}
