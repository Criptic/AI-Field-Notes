"""
  Please check out the blog post for more details:
  https://davidweik.substack.com/p/ai-field-notes-cw-29-2025

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

def call_gemini(system_prompt, user_prompt, llm='gemini-2.5-flash-lite', temperature=1, max_output_tokens=1000, top_p=0.8, top_k=10):
    """
    Call the Gemini API with the provided parameters.
    
    Parameters:
    - system_prompt (str): The system prompt for the model. 
    - user_prompt (str): The user prompt for the model.
    - llm (str): The model to use. Default is 'gemini-2.5-flash-lite'. Values include: 'gemini-2.5-flash-lite', 'gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash', 'gemini-2.0-flash-lite', 'gemma-3n-e2b-it', 'gemma-3n-e4b-it', 'gemma-3-1b-it', 'gemma-3-4b-it', 'gemma-3-12b-it', 'gemma-3-27b-it'.
    - temperature (float): Controls the randomness of the output.. Default is 1.
    - max_output_tokens (int): Limits the number of output tokens. Default is 1000.
    - top_p (float): The cumulative proability of tokens to consider when sampling. Default is 0.8.
    - top_k (int): The maximum number of tokens to consider when sampling. Default is 10.
    
    Returns:
    - dict: A dictionary containing the response, input tokens, output tokens, LLM used, and input configuration.
    """
    input_config = {
        'temperature': temperature,
        'maxOutputTokens': max_output_tokens,
        'topP': top_p,
        'topK': top_k,
        'candidateCount': 1
    }
    # Make the API request
    response = requests.post(
        f'https://generativelanguage.googleapis.com/v1beta/models/{llm}:generateContent?key={API_KEY}',
        headers={'Content-Type': 'application/json'},
        data=json.dumps({
            "system_instruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"parts": [{"text": user_prompt}]}],
            "generation_config": input_config
        })
    )
    # Check the response status and return the result
    if response.status_code == 200:
        result = response.json()
        return {
            "response": result['candidates'][0]['content']['parts'][0]['text'],
            "input_tokens": result['usageMetadata']['promptTokenCount'],
            "output_tokens": result['usageMetadata']['candidatesTokenCount'],
            "llm": llm,
            "input_config": input_config
        }
    else:
        Exception(f"Error: {response.status_code}, {response.text}")
        return None

# Example usage
user_prompt = 'Explain how AI works in a few words'
system_prompt = 'You are a pre-school teacher that specialies in breaking down complex topics into easy to digest answer that are appropriate for five year olds.'
llm_response = call_gemini(user_prompt, system_prompt)
print(llm_response)