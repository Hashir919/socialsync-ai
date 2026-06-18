import sys, os
sys.path.append(os.path.abspath('scripts'))
from model_pipeline import generate_coach_response_hf, analyze_emotion_hf

test_cases = [
    "I have an interview tomorrow and I am nervous.",
    "I feel lonely and don't know how to start conversations.",
    "My friend ignored my message and I feel upset.",
    "How do I become more confident while talking to people?"
]
for text in test_cases:
    print('---')
    print('Input:', text)
    response = generate_coach_response_hf(text, persona='AI Coach', context='General')
    print('Response:', response)
    # also show emotion detection
    emotion = analyze_emotion_hf(text)
    print('Emotion detection:', emotion)
