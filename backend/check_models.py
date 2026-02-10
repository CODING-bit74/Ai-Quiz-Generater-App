import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv("backend/.env")

api_key = os.getenv("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

try:
    models = genai.list_models()
    print("Available Embedding Models:")
    for m in models:
        if 'embedContent' in m.supported_generation_methods:
            print(m.name)
except Exception as e:
    print(f"Error listing models: {e}")
