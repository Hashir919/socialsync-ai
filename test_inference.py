import sys, os
sys.path.append(os.path.abspath('scripts'))
from model_pipeline import generate_coach_response_hf

inputs = [
    "I feel lonely and don't know how to start conversations.",
    "My friend ignored my message and I feel upset.",
    "I keep replaying conversations in my head after talking to people.",
    "A girl stopped replying to my messages.",
    "I am nervous about meeting new people.",
    "I have an interview tomorrow and I am nervous."
]

for idx, text in enumerate(inputs, 1):
    print(f"Test case {idx}:")
    generate_coach_response_hf(text, persona="ai coach", context="")
