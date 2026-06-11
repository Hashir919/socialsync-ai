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

# Helper to find exact or close matches for rewrite engine
def find_rewrite(text: str, context: str):
    text_clean = re.sub(r'[^\w\s]', '', text.lower()).strip()
    
    # 1. Match from dataset
    for item in coaching_dataset:
        item_text_clean = re.sub(r'[^\w\s]', '', item["text"].lower()).strip()
        if item_text_clean == text_clean or item_text_clean in text_clean:
            return item["improved"], item["suggestion"]
            
    # 2. Heuristics fallback based on context if no match
    context_lower = context.lower()
    
    # Check if text is dry or anxious
    words = text.split()
    is_dry = len(words) <= 3
    is_anxious = any(w in text_clean for w in ["sorry", "maybe", "nervous", "anxious", "scared", "stupid", "wrong"])
    is_demanding = any(w in text_clean for w in ["now", "need", "must", "fix", "ignore", "why"])

    if context_lower == "interview":
        if is_dry:
            return f"I have direct experience in this area, specifically handling projects that required problem solving and technical execution.", "Provide detailed examples using the STAR method."
        if is_anxious:
            return f"I welcome feedback and look forward to learning from new challenges.", "Frame challenges as growth opportunities rather than weaknesses."
        if is_demanding:
            return f"Could we align on the next steps and see how we can optimize this process?", "Use collaborative language to show professionalism."
        return f"I'd love to highlight how my background aligns with your team's goals.", "Emphasize mutual fit and value add."

    elif context_lower == "dating":
        if is_dry:
            return f"That sounds like a lot of fun! How did you get into that?", "Ask open-ended questions to keep the conversation light and engaging."
        if is_anxious:
            return f"I'm really looking forward to getting to know you better. When are you free next week?", "Take initiative and suggest a low-pressure plan."
        return f"That's so interesting! Tell me more about what you enjoyed most about it.", "Express warm curiosity and active listening."

    elif context_lower == "workplace" or context_lower == "networking":
        if is_dry:
            return f"Thanks for sharing. I'll review this and send over my thoughts shortly.", "Keep communication prompt and value-driven."
        if is_anxious:
            return f"Let's connect tomorrow to review the project details and ensure we are aligned.", "Take ownership and project competence."
        if is_demanding:
            return f"I appreciate your patience as we troubleshoot this issue together.", "Soften direct requests with collaborative words."
        return f"I'd love to schedule a brief call to sync on these milestones.", "Suggest clear call-to-actions."

    else:
        # Default fallback
        if is_dry:
            return f"That sounds great! Tell me more about how that went.", "Invite them to expand."
        if is_anxious:
            return f"I'm happy to help out with this whenever you're ready.", "Offer help simply and directly."
        return f"Thanks for checking in! I appreciate the message.", "Keep it warm and positive."

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

# Simulated Persona responses for Practice Mode
def get_persona_response(user_input: str, persona: str, context: str):
    persona_lower = persona.lower()
    input_lower = user_input.lower()
    
    # Check if first message
    is_initial = any(w in input_lower for w in ["hello", "hi", "hey", "start", "begin", "ready"]) or len(user_input) < 3
    
    if "interview" in persona_lower:
        if is_initial:
            return "Welcome! Thanks for coming in today. Let's start with a classic: Can you tell me about yourself and why you're interested in this role?"
        if "myself" in input_lower or "background" in input_lower or "experience" in input_lower:
            return "That sounds like a solid foundation. Can you describe a challenging project you managed and how you handled it?"
        return "I see. How do you handle stressful deadlines or conflict within your team?"
        
    elif "dating" in persona_lower:
        if is_initial:
            return "Hey! I'm really glad we could meet up today. How has your week been going so far?"
        if "good" in input_lower or "busy" in input_lower or "fine" in input_lower:
            return "That's good to hear! I've been checking out this new coffee spot. What do you like to do to unwind on weekends?"
        return "That's really neat! I've actually wanted to try that too. What's your favorite spot in the city for that?"

    elif "public speaking" in persona_lower:
        if is_initial:
            return "Hello! I'm your Public Speaking coach. Let's practice your introduction. Try introducing your topic in 2-3 strong sentences."
        return "Good start! Try pausing for 2 seconds after your main hook to let it sink in. What's the main takeaway for the audience?"

    elif "friendship" in persona_lower:
        if is_initial:
            return "Hey buddy! Long time no see. How have you been? Anything new lately?"
        return "Oh wow, that's awesome! We should definitely hang out soon and catch up properly. What are you up to this weekend?"

    else:
        # Networking Coach
        if is_initial:
            return "Hi there! Glad to connect at this event. What kind of projects or industry sectors are you currently focused on?"
        return "That's a very dynamic space right now. What do you see as the biggest opportunity or trend there in the coming year?"


@app.get("/")
def read_root():
    return {"status": "SocialSync AI Backend is running", "using_fallback_nlp": False}


@app.websocket("/ws/live-assist")
def websocket_legacy(websocket: WebSocket):
    # This acts as a placeholder if clients connect raw
    pass

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
