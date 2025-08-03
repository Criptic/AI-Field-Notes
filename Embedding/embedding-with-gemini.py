"""
  Please check out the blog post for more details:
  https://davidweik.substack.com/p/ai-field-notes-cw-30-2025

  Use the terminal to clone the repository:
  git -C $WORKSPACE clone https://github.com/Criptic/AI-Field-Notes.git
"""
import json
# Ensure requests package is installed
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
model = 'gemini-embedding-001'
prompt = 'What is the meaning of life?'

# Make the request to the API
response = requests.post(f'https://generativelanguage.googleapis.com/v1beta/models/{model}:embedContent',
    headers={'Content-Type': 'application/json', 'x-goog-api-key': API_KEY},
    data=f'{{"content": {{"parts": [{{"text": "{prompt}"}}]}}}}')

# Check the response status and print the result
if response.status_code == 200:
    print(len(response.json()['embedding']['values']))
else:
    print(f'Error: {response.status_code} - {response.text}')