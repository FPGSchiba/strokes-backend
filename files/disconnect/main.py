def handle(event: dict, context: dict):
    print('Disconnect')
    print(f'event: {event}')
    print(f'context: {context}')
    return {
        'statusCode': 200,
    }