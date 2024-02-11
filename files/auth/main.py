import json
import os
import urllib.request
from urllib.error import HTTPError


VALIDATE_URL = os.getenv('VALIDATE_URL')


def handle(event, context):
    print('Auth')
    print(f'Event: {event}')
    token = event['queryStringParameters']['auth']
    print(f'Token: {token}')
    try:
        req = urllib.request.Request(VALIDATE_URL)
        req.add_header('Authorization', token)
        status = urllib.request.urlopen(req).status
        response = generatePolicy('user', 'Allow', event['methodArn'])
        print(status)
    except HTTPError as error:
        print('Error')
        print(error.code)
        response = generatePolicy('user', 'Deny', event['methodArn'])
    return json.loads(response)


def generatePolicy(principalId, effect, resource):
    authResponse = {}
    authResponse['principalId'] = principalId
    if effect and resource:
        policyDocument = {}
        policyDocument['Version'] = '2012-10-17'
        policyDocument['Statement'] = [];
        statementOne = {}
        statementOne['Action'] = 'execute-api:Invoke'
        statementOne['Effect'] = effect
        statementOne['Resource'] = resource
        policyDocument['Statement'] = [statementOne]
        authResponse['policyDocument'] = policyDocument
    authResponse['context'] = {
        "stringKey": "stringval",
        "numberKey": 123,
        "booleanKey": True
    }
    authResponse_JSON = json.dumps(authResponse)
    return authResponse_JSON
