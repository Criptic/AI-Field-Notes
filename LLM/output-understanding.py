"""
  Please check out the blog post for more details:
  https://davidweik.substack.com/p/ai-field-notes-cw-22-2025

  Use the terminal to clone the repository:
  git -C $WORKSPACE clone https://github.com/Criptic/AI-Field-Notes.git
"""
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

# Now we add our system prompt
system_prompt = 'You are a pre-school teacher that specialies in breaking down complex topics into easy to digest answer that are appropriate for five year olds.'

# Make the request to the API
response = requests.post(f'https://generativelanguage.googleapis.com/v1beta/models/{llm}:generateContent?key={API_KEY}',
    headers={'Content-Type': 'application/json'},
    data=f'{{"system_instruction": {{"parts": [{{"text": "{system_prompt}"}}]}}, "contents": [{{"parts": [{{"text": "{prompt}"}}]}}]}}')

# Check the response status and print the result
if response.status_code == 200:
    result = response.json()
    print(result['candidates'][0]['content']['parts'][0]['text'])
    print(f"Input Tokens: {result['usageMetadata']['promptTokenCount']}")
    print(f"Output Tokens: {result['usageMetadata']['candidatesTokenCount']}")
    print(f"Answer Confidence: {'high'if result['candidates'][0]['avgLogprobs'] > -1.5 else 'low'}")
    print(f"Finish Reason: {result['candidates'][0]['finishReason']}")
else:
    print(f'Error: {response.status_code}')