import json


def handle(event: dict, context: dict):
    print('Connect')
    print(f'event: {event}')
    print(f'context: {context}')
    return {
        'statusCode': 200,
        'body': json.dumps({
            'test': 'test',
            'message': 'test'
        })
    }