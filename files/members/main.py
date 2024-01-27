def handle(event: dict, context: dict):
    print('Members')
    print(f'event: {event}')
    print(f'context: {context}')
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    }
