import os
import json
import re
import random
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Global variables for caching models/pipelines
_emotion_pipeline = None
_paraphrase_pipeline = None
_chat_pipeline = None

# Custom dataset path
DATASET_PATH = os.path.join(os.path.dirname(__file__), "..", "socialsync_dataset.json")

def load_custom_dataset():
    if os.path.exists(DATASET_PATH):
        try:
            with open(DATASET_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return []

# Load the dataset once at module load time
SOCIALSYNC_DATA = load_custom_dataset()

# Initialize similarity vectorizer for intelligent fallback
tfidf_vectorizer = TfidfVectorizer(stop_words='english')
if SOCIALSYNC_DATA:
    corpus = [item["original_message"] for item in SOCIALSYNC_DATA]
    tfidf_matrix = tfidf_vectorizer.fit_transform(corpus)
else:
    corpus = []
    tfidf_matrix = None

# Try to pre-load models at startup
try:
    from transformers import pipeline
    print("[AI Pipeline] Loading DistilBERT GoEmotions model...")
    _emotion_pipeline = pipeline("text-classification", model="bhadresh-savani/distilbert-base-uncased-emotion", top_k=1)
    print("[AI Pipeline] DistilBERT Loaded")
    
    print("[AI Pipeline] Loading T5 paraphrase model...")
    _paraphrase_pipeline = pipeline("text2text-generation", model="google-t5/t5-small")
    print("[AI Pipeline] T5 Loaded")
    
    print("[AI Pipeline] Loading DialoGPT response generation model...")
    _chat_pipeline = pipeline("text-generation", model="microsoft/DialoGPT-small")
    print("[AI Pipeline] DialoGPT Loaded")
    
    print("[AI Pipeline] Models Ready")
except Exception as e:
    print(f"[AI Pipeline] Failed to preload models at startup: {e}")


def get_smart_fallback_rewrite(text: str, context: str):
    """Fallback rewrite generator utilizing the custom socialsync dataset and TF-IDF similarity."""
    if not SOCIALSYNC_DATA or tfidf_matrix is None:
        return text, "Try expressing your thoughts directly."
        
    query_vec = tfidf_vectorizer.transform([text])
    similarities = cosine_similarity(query_vec, tfidf_matrix).flatten()
    best_idx = np.argmax(similarities)
    
    if similarities[best_idx] > 0.2:
        matched = SOCIALSYNC_DATA[best_idx]
        return matched["improved_message"], f"Matched context '{matched['context']}': Focus on confidence and clarity."
    
    # Generic smart generation based on context
    ctx = context.lower()
    if "interview" in ctx:
        return f"I bring key experience that directly aligns with the objectives of this role.", "Use the STAR method to structure your response."
    elif "date" in ctx or "dating" in ctx:
        return f"That sounds like a great plan! What's your favorite part about it?", "Ask an engaging open-ended question."
    elif "work" in ctx or "workplace" in ctx:
        return f"Let's sync up on these goals to ensure we are fully aligned.", "Use professional collaborative terms."
    
    return f"Thanks for sharing. I'd love to hear more about that.", "Ask a follow-up question."

def analyze_emotion_hf(text: str) -> dict:
    """Run real DistilBERT GoEmotions model if available, else fallback to TF-IDF rule/keyword match."""
    global _emotion_pipeline
    print(f"[AI Pipeline] Triggered Emotion Detection for text: '{text}'")
    try:
        from transformers import pipeline
        if _emotion_pipeline is None:
            print("[AI Pipeline] Loading DistilBERT GoEmotions model...")
            # bhadresh-savani/distilbert-base-uncased-emotion is lightweight (~260MB)
            _emotion_pipeline = pipeline("text-classification", model="bhadresh-savani/distilbert-base-uncased-emotion", top_k=1)
            print("[AI Pipeline] DistilBERT GoEmotions loaded successfully.")
        
        res = _emotion_pipeline(text)
        if res and len(res) > 0:
            best_match = res[0]
            if isinstance(best_match, list):
                best_match = best_match[0]
            label = best_match.get("label", "neutral").capitalize()
            score = best_match.get("score", 0.5)
            print(f"[AI Pipeline] DistilBERT Emotion Inference: Detected '{label}' (confidence: {score:.2f})")
            # Map default labels to SocialSync expected format
            anxiety_map = {"fear": 0.8, "sadness": 0.6, "anger": 0.4, "joy": 0.1, "surprise": 0.2, "love": 0.1}
            anxiety_base = anxiety_map.get(label.lower(), 0.2)
            return {"emotion": label, "anxiety_score": anxiety_base}
    except Exception as e:
        print(f"[AI Pipeline] DistilBERT loading/inference failed: {e}. Falling back to keyword analysis.")
        
    # Standard keyword & similarity fallback
    print("[AI Pipeline] Fallback Emotion Detection Triggered")
    text_lower = text.lower()
    if any(w in text_lower for w in ["nervous", "scared", "fear", "anxious", "sorry", "panic"]):
        return {"emotion": "Fear", "anxiety_score": 0.85}
    elif any(w in text_lower for w in ["happy", "excited", "great", "glad", "awesome"]):
        return {"emotion": "Joy", "anxiety_score": 0.10}
    elif any(w in text_lower for w in ["mad", "angry", "annoyed", "frustrated", "hate"]):
        return {"emotion": "Anger", "anxiety_score": 0.40}
    
    return {"emotion": "Neutral", "anxiety_score": 0.20}

def rewrite_message_hf(text: str, context: str) -> tuple:
    """Paraphrase message using T5 or fallback to smart dataset retriever."""
    global _paraphrase_pipeline
    print(f"[AI Pipeline] Triggered Rewrite Engine for text: '{text}' in context: '{context}'")
    try:
        from transformers import pipeline
        if _paraphrase_pipeline is None:
            print("[AI Pipeline] Loading T5 paraphrase model...")
            _paraphrase_pipeline = pipeline("text2text-generation", model="google-t5/t5-small")
            print("[AI Pipeline] T5 Paraphraser loaded successfully.")
            
        prompt = f"paraphrase: {text} context: {context}"
        res = _paraphrase_pipeline(prompt, max_length=64)
        if res and len(res) > 0:
            improved = res[0].get("generated_text", "")
            if len(improved.strip()) > 5:
                print(f"[AI Pipeline] T5 rewrite successful: '{improved}'")
                return improved, "Paraphrased with T5 paraphraser for better flow."
    except Exception as e:
        print(f"[AI Pipeline] T5 rewrite engine failed: {e}. Falling back to TF-IDF retriever.")
        
    print("[AI Pipeline] Fallback TF-IDF Rewrite Triggered")
    return get_smart_fallback_rewrite(text, context)

def generate_coach_response_hf(user_input: str, persona: str, context: str) -> str:
    """Generate dynamic conversation response using DialoGPT or PersonaChat heuristics."""
    input_lower = user_input.lower().strip()
    persona_lower = persona.lower()

    # 1. Specialized AI Coach prompt routing (Home Screen Chatbot)
    if "ai coach" in persona_lower or persona_lower == "" or persona_lower == "coach":
        # Handle specific common anxiety/coaching prompts with dedicated guidance
        if any(w in input_lower for w in ["nervous", "anxious", "scared", "fear", "interview prep"]) and "interview" in input_lower:
            return "It is completely normal to feel nervous before an interview! Remember, an interview is a two-way conversation to see if it's a mutual fit. Try to take deep, slow breaths. What role are you interviewing for? Let's practice some common questions together!"
        elif any(w in input_lower for w in ["ignoring", "ignore", "not replying", "ignored"]):
            return "It hurts when a friend doesn't reply. People often get busy or might be dealing with their own challenges. Try giving them a bit of space, and when you do reach out, keep it light and low-pressure: 'Hey! Hope you're having a good week, would love to catch up when you're free!' How does that feel?"
        elif any(w in input_lower for w in ["what to text", "how to reply", "text guidance", "texting", "rewrite"]):
            return "Texting can feel tricky! If you're unsure of what to say, try keeping it authentic and open-ended. Share the message or context here, and we can craft a warm, engaging response together."
        elif any(w in input_lower for w in ["fail", "failed", "hopeless", "sad", "depressed", "ruined", "low"]):
            return "I am so sorry to hear that. Disappointment can feel incredibly heavy, but please remember that setbacks do not define your worth. Give yourself permission to process this today, then take a deep breath. We can build a fresh plan together whenever you are ready. I'm here for you."
        elif len(input_lower.split()) <= 2 and any(re.search(rf"\b{re.escape(w)}\b", input_lower) for w in ["hello", "hi", "hey", "greet", "greetings"]):
            return "Hello! I am your SocialSync AI Coach. I'm here to help you navigate social anxiety, build communication confidence, or practice relationships and interviews. What's on your mind today?"

    # Try generating using DialoGPT
    global _chat_pipeline
    print(f"[AI Pipeline] Triggered Coach Response Generation for input: '{user_input}' (Persona: '{persona}', Context: '{context}')")
    
    # Prompt formatting depending on persona to steer DialoGPT
    prompt = user_input
    if "interview" in persona_lower:
        prompt = f"Interview Coach: {user_input}"
    elif "dating" in persona_lower:
        prompt = f"Dating Coach: {user_input}"
    elif "friendship" in persona_lower:
        prompt = f"Friend Coach: {user_input}"
    elif "speaking" in persona_lower:
        prompt = f"Public Speaking Coach: {user_input}"
    elif "networking" in persona_lower:
        prompt = f"Professional Networking Coach: {user_input}"
    else:
        prompt = f"Social Coach: {user_input}"

    try:
        from transformers import pipeline
        if _chat_pipeline is None:
            print("[AI Pipeline] Loading DialoGPT response generation model...")
            _chat_pipeline = pipeline("text-generation", model="microsoft/DialoGPT-small")
            print("[AI Pipeline] DialoGPT loaded successfully.")
            
        res = _chat_pipeline(prompt, max_length=120, pad_token_id=50256)
        if res and len(res) > 0:
            reply = res[0].get("generated_text", "")
            if reply.startswith(prompt):
                reply = reply[len(prompt):].strip()
            # Clean up residual prefixes
            reply = reply.replace("Interview Coach:", "").replace("Dating Coach:", "").replace("Friend Coach:", "")
            reply = reply.replace("Public Speaking Coach:", "").replace("Professional Networking Coach:", "")
            reply = reply.strip(" :,-")
            if len(reply) > 3:
                print(f"[AI Pipeline] DialoGPT generated reply: '{reply}'")
                return reply
    except Exception as e:
        print(f"[AI Pipeline] DialoGPT response generation failed: {e}. Falling back to heuristics.")

    # 2. Fallback Heuristics per Persona (when DialoGPT is offline or output is too short)
    print(f"[AI Pipeline] Fallback Heuristics Triggered for Persona: '{persona}'")
    is_initial = any(w in input_lower for w in ["hello", "hi", "hey", "start", "begin", "ready"]) or len(user_input) < 3
    
    if "interview" in persona_lower:
        if is_initial:
            return "Welcome! Thanks for coming in today. Let's start with a classic: Can you tell me about yourself and why you're interested in this role?"
        if any(w in input_lower for w in ["myself", "background", "experience", "resume", "work"]):
            return "That sounds like a solid foundation. Can you describe a challenging project you managed and how you handled it?"
        if any(w in input_lower for w in ["challenge", "project", "problem", "failed", "difficult"]):
            return "Understood. Adaptability is key in this environment. How do you handle tight deadlines or conflicting priorities in a team?"
        if any(w in input_lower for w in ["priority", "deadline", "schedule", "time"]):
            return "Excellent. Time management makes a huge difference. What would you say is your greatest professional strength?"
        return "Thank you for sharing that. Do you have any questions for me about the team or our company culture?"
        
    elif "dating" in persona_lower:
        if is_initial:
            return "Hey! I'm really glad we could meet up today. How has your week been going so far?"
        if any(w in input_lower for w in ["good", "busy", "fine", "great", "okay"]):
            return "That's great! I've been wanting to try this new coffee spot. What do you usually like to do to unwind on weekends?"
        if any(w in input_lower for w in ["hobby", "weekend", "play", "read", "watch", "music", "movie"]):
            return "That sounds super interesting! I've wanted to try that too. What's your favorite thing about it?"
        if any(w in input_lower for w in ["fun", "love", "like", "favorite"]):
            return "I can see why you enjoy that! It sounds like a lot of fun. What other spots in the city do you like to hang out at?"
        return "That sounds wonderful. Tell me more about what makes you passionate about that!"

    elif "speaking" in persona_lower:
        if is_initial:
            return "Hello! I'm your Public Speaking coach. Let's practice your introduction. Try introducing your topic in 2-3 strong sentences."
        if len(user_input) > 40:
            return "Great pacing and detailed opening! Try pausing for 2 seconds after your main hook to let it sink in. What is the key takeaway you want your audience to remember?"
        return "A strong start. Let's work on projection and posture. How would you summarize the core message of your presentation in one clear sentence?"

    elif "friendship" in persona_lower:
        if is_initial:
            return "Hey buddy! Long time no see. How have you been? Anything new lately?"
        if any(w in input_lower for w in ["good", "fine", "nothing", "much", "same"]):
            return "Same here, just keeping busy! We should definitely hang out soon and catch up properly. What are you up to this weekend?"
        if any(w in input_lower for w in ["weekend", "hang", "free", "out"]):
            return "Awesome, let's grab some lunch or catch a movie. Which day works better for you, Saturday or Sunday?"
        return "Oh wow, that's awesome! Tell me more about how that went."

    elif "networking" in persona_lower:
        if is_initial:
            return "Hi there! Glad to connect at this event. What kind of projects or industry sectors are you currently focused on?"
        if any(w in input_lower for w in ["tech", "software", "ai", "data", "finance", "design", "product"]):
            return "That's a very dynamic space right now. What do you see as the biggest opportunity or trend there in the coming year?"
        if any(w in input_lower for w in ["trend", "opportunity", "future", "growth"]):
            return "Very insightful analysis. I'd love to connect on LinkedIn to keep in touch. What's the best way to reach you?"
        return "Fascinating work. How did you get started in this field?"

    # Fallback to general conversational questions for AI Coach/General
    general_replies = [
        "That makes a lot of sense. Can you elaborate on that?",
        "I see! How does that make you feel when communicating in this scenario?",
        "Thanks for sharing that with me. What would be your ideal outcome here?",
        "Interesting point. Let's practice phrasing that with more confidence!",
        "Active listening is key. What do you think the other person might be feeling?"
    ]
    return random.choice(general_replies)

