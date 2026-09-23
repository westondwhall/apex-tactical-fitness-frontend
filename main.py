import os
import sys

from google import genai


GEMINI_API_KEY = os.environ["GEMINI_API_KEY"]
PDF_PATH = sys.argv[1] if len(sys.argv) > 1 else "path/to/tactical_document.pdf"

client = genai.Client(api_key=GEMINI_API_KEY)
new_file = client.files.upload(file=PDF_PATH)
print(f"Uploaded RAG file URI: {new_file.uri}")
