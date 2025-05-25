import json
# Ensure requests is installed
try:
    import requests
except ImportError:
    print('requests module not found. Please install it with pip install requests')
    exit(1)

# Get api key from ../config.json
with open('../config.json') as f:
    config = json.load(f)
    API_KEY = config['gemini_key']

# Provide configuration for the model and set the prompt
llm = 'gemini-2.0-flash'
prompt = 'Explain how AI works in a few words'

# Make the request to the API
response = requests.post(f'https://generativelanguage.googleapis.com/v1beta/models/{llm}:generateContent?key={API_KEY}',
    headers={'Content-Type': 'application/json'},
    data=f'{{"contents": [{{"parts": [{{"text": "{prompt}"}}]}}]}}')

# Check the response status and print the result
if response.status_code == 200:
    print(response.json())
else:
    print(f'Error: {response.status_code}')