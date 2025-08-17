"""
  Please check out the blog post for more details:
  https://davidweik.substack.com/p/ai-field-notes-cw-32-2025

  Use the terminal to clone the repository:
  git -C $WORKSPACE clone https://github.com/Criptic/AI-Field-Notes.git
"""
import time
import json
# Ensure requests package is installed
try:
    import requests
except ImportError:
    print('requests module not found. Please install it with pip install requests')
    exit(1)
try:
        import pandas as pd
except ImportError:
    print('pandas module not found. Please install it with pip install pandas')
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

# Setting up our system prompt for the evaluation task
system_prompt = 'You are an expert in general knowledge question multiple choice answers. You will be given a question with multiple choice answers. You will answer the question with the correct answer, by only returning the letter of the correct answer. If you do not know the answer, provide a 1.'
# Load the evaluation dataset
df_eval = pd.read_csv('../Datasets/simple-evaluation.csv')
# Create a new column 'response'
df_eval['response'] = None
df_eval['input_tokens'] = None
df_eval['output_tokens'] = None

started_timestamp = time.time()
# Iterate through the DataFrame rows and apply the function
for index, row in df_eval.iterrows():
    # Concatenate the 'question' and 'choices' columns to create the prompt
    user_prompt = f"{row['question']} {row['choices']}"
    
    # Call the gemini function and get the response attribute
    response = call_gemini(system_prompt, user_prompt)
    df_eval.at[index, 'input_tokens'] = response['input_tokens']
    df_eval.at[index, 'output_tokens'] = response['output_tokens']
    df_eval.at[index, 'response'] = response['response']

run_time = time.time() - started_timestamp

# Let's calculate the accuracy of the responses
df_eval['correct'] = df_eval.apply(lambda x: x['response'].strip().lower() == x['answer'].strip().lower(), axis=1)
accuracy = df_eval['correct'].mean()
# Let's calcuate the prompt adherence
df_eval['prompt_adherence_correct_character'] = df_eval.apply(lambda x: x['response'] in ['a', 'b', 'c', 'd', '1'], axis=1)
df_eval['prompt_adherence_correct_length'] = df_eval.apply(lambda x: len(x['response']) == 1, axis=1)
prompt_adherence = (df_eval['prompt_adherence_correct_character'].mean() + df_eval['prompt_adherence_correct_length'].mean()) / 2

# Print the updated DataFrame
print(f"Evaluation completed in {run_time:.2f} seconds.")
print(f"Accuracy: {accuracy:.2%}")
print(f"Prompt adherence correct character: {df_eval['prompt_adherence_correct_character'].mean():.2%}")
print(f"Prompt adherence correct length: {df_eval['prompt_adherence_correct_length'].mean():.2%}")
print(f"Prompt adherence: {prompt_adherence:.2%}")
print(f"Input tokens: {df_eval['input_tokens'].sum()}")
print(f"Output tokens: {df_eval['output_tokens'].sum()}")
print(f"Total tokens: {df_eval['input_tokens'].sum() + df_eval['output_tokens'].sum()}")