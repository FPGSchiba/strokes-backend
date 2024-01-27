def handle(event: dict, context: dict):
    print('Default')
    print(f'event: {event}')
    print(f'context: {context}')
    return {
        'statusCode': 200,
    }