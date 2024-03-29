import json


def handle(event: dict, context: dict):
    print('Strokes')
    print(f'event: {event}')
    print(f'context: {context}')
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'test': 'test'
        })
    }
