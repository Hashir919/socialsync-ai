from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json
import re
import random
from pathlib import Path
import sys

# Add root folder to sys.path to resolve scripts module
sys.path.append(str(Path(__file__).resolve().parent.parent))

from scripts.model_pipeline import (
    analyze_emotion_hf,
    rewrite_message_hf,
    generate_coach_response_hf
)

app = FastAPI(title="SocialSync AI API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load coaching dataset
dataset_path = Path(__file__).parent / "coaching_dataset.json"
coaching_dataset = []
if dataset_path.is_file():
    try:
        with open(dataset_path, "r", encoding="utf-8") as f:
            coaching_dataset = json.load(f)
        print(f"Loaded {len(coaching_dataset)} custom training/rewrite examples.")
    except Exception as e:
        print(f"[Warning] Failed to load coaching dataset: {e}")


# Helper to calculate dynamic anxiety, confidence, clarity metrics
def calculate_scores(text: str, context: str, mode: str):
    text_lower = text.lower()
    words = text.split()
    word_count = len(words)

    # 1. Anxiety Score Calculation
    anxiety_keywords = ["nervous", "scared", "fear", "anxious", "panic", "shaking", "sorry", "apologize", "stupid", "worry", "worried", "afraid"]
    filler_words = ["um", "uh", "like", "maybe", "probably", "guess", "sort of", "kind of"]
    
    anxiety_hits = sum(1 for w in anxiety_keywords if w in text_lower)
    filler_hits = sum(1 for w in filler_words if w in text_lower)
    
    # Base anxiety score
    anxiety = 20  # baseline
    anxiety += anxiety_hits * 25
    anxiety += filler_hits * 10
    
    # Adjust based on length/dryness
    if word_count < 3 and word_count > 0:
        anxiety += 15  # awkward hesitation/dryness
        
    # Cap between 5% and 95%
    anxiety = max(5, min(95, anxiety))
    if "confident" in text_lower or "excited" in text_lower:
        anxiety = max(5, anxiety - 15)

    # 2. Confidence Score Calculation
    confidence_keywords = ["definitely", "confident", "excited", "absolutely", "sure", "certain", "ready", "achieve", "success", "great", "glad"]
    confidence_hits = sum(1 for w in confidence_keywords if w in text_lower)
    
    confidence = 60  # baseline
    confidence += confidence_hits * 15
    confidence -= (anxiety - 20) * 0.6  # confidence drops as anxiety increases
    
    # Context-based tuning
    if context.lower() == "interview" and not any(w in text_lower for w in ["sorry", "beg"]):
        confidence += 5
        
    confidence = max(5, min(98, confidence))

    # 3. Clarity Score Calculation
    # Ramble reduction: sentences that are too long reduce clarity
    clarity = 85  # baseline
    if word_count > 25:
        clarity -= 15
    if word_count < 3 and word_count > 0:
        clarity -= 10  # too short / lacks clarity of intent
    
    clarity -= filler_hits * 8
    clarity = max(10, min(98, clarity))

    # Pace simulation
    if mode == "voice":
        if anxiety > 60:
            pace = random.randint(145, 165)  # rapid speaking under stress
        elif anxiety < 30:
            pace = random.randint(110, 128)  # calm optimal speaking pace
        else:
            pace = random.randint(128, 145)
    else:
        pace = 0 # Not applicable for chat typing

    return int(anxiety), int(confidence), int(clarity), pace

# Helper to generate live coaching tips
def get_live_coaching_tips(anxiety: int, confidence: int, clarity: int, pace: int, context: str):
    tips = []
    
    # Pacing checks
    if pace > 140:
        tips.append("Speak slower")
    elif pace > 0 and pace < 100:
        tips.append("Speak with more energy")
        
    # Context-based non-verbal / conversational alerts
    if context.lower() == "interview":
        tips.append("Maintain eye contact")
        tips.append("Avoid filler words")
    elif context.lower() == "dating":
        tips.append("Smile naturally")
        tips.append("Ask a follow-up question")
    elif context.lower() == "public speaking":
        tips.append("Stand tall and gesture naturally")
        tips.append("Pause after key points")
    else:
        tips.append("Ask a follow-up question")
        tips.append("Practice active listening")
        
    # Return random 2 coaching tips
    return list(set(tips))[:2]


@app.get("/")
def read_root():
    return {"status": "SocialSync AI Backend is running", "using_fallback_nlp": False}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            # We support JSON payload: { "text": "...", "context": "...", "mode": "...", "persona": "..." }
            # As well as raw string fallback
            raw_data = await websocket.receive_text()
            
            # Simulate processing latency
            await asyncio.sleep(random.uniform(0.3, 0.6))
            
            try:
                data = json.loads(raw_data)
                text = data.get("text", "")
                context = data.get("context", "Friendship")
                mode = data.get("mode", "chat")
                persona = data.get("persona", "")
            except Exception:
                text = raw_data
                context = "Friendship"
                mode = "chat"
                persona = ""
            
            if not text.strip():
                continue
                
            # If persona is AI Coach, bypass metrics and rewrite engine
            is_ai_coach = "ai coach" in persona.lower() or persona.lower() == "coach"
            
            if is_ai_coach:
                persona_reply = generate_coach_response_hf(text, "AI Coach", context)
                response = {
                    "transcript": text,
                    "context": context,
                    "mode": mode,
                    "emotion": "Neutral",
                    "persona_reply": persona_reply
                }
            else:
                # Calculate metrics
                emotion_res = analyze_emotion_hf(text)
                emotion_label = emotion_res["emotion"]
                anxiety_factor = emotion_res["anxiety_score"]
                anxiety = int(anxiety_factor * 100)
                
                _, confidence, clarity, pace = calculate_scores(text, context, mode)
                confidence = max(5, min(98, 100 - anxiety))
                
                # Generate Rewrite using model pipeline
                improved, suggestion = rewrite_message_hf(text, context)
                
                # Live coaching alerts
                coaching_tips = get_live_coaching_tips(anxiety, confidence, clarity, pace, context)
                
                # Practice Mode persona reply
                persona_reply = ""
                if persona:
                    persona_reply = generate_coach_response_hf(text, persona, context)
                    
                response = {
                    "transcript": text,
                    "context": context,
                    "mode": mode,
                    "emotion": emotion_label,
                    "anxiety": f"{anxiety}%",
                    "confidence": f"{confidence}%",
                    "clarity": f"{clarity}%",
                    "pace": f"{pace} wpm" if mode == "voice" else "N/A",
                    "suggestion": suggestion,
                    "improved": improved,
                    "coaching_tips": coaching_tips,
                    "persona_reply": persona_reply
                }
            
            await websocket.send_json(response)
    except Exception as e:
        print(f"WS Connection closed/failed: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
