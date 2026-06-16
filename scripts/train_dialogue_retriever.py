import os
import json
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer

def get_conversational_corpus():
    # Curated, rich conversational dialogue corpus for empathetic communication support
    corpus = [
        # Greetings & Chit-chat
        {
            "query": "hello hi hey greetings howdy good morning good evening",
            "response": "Hello! I am your AI Communication Coach. I'm here to chat, listen to how you feel, or help you navigate social interactions. What's on your mind today?"
        },
        {
            "query": "how are you doing today? how are you?",
            "response": "I'm doing well, thank you for asking! I'm ready to support you with any communication challenges or just have a friendly chat. How is your day going?"
        },
        {
            "query": "who are you? what do you do?",
            "response": "I'm your AI Communication Coach, designed to help you build confidence, overcome social anxiety, prepare for conversations, or simply listen when you need to vent."
        },
        
        # Social Anxiety & Reassurance
        {
            "query": "i feel anxious nervous scared worried panic shaking",
            "response": "It is completely okay to feel anxious. Anxiety is a natural response, and you are not alone in feeling this way. Let's take a deep breath together. What's triggering this feeling right now?"
        },
        {
            "query": "i am nervous about speaking to people presenting stage",
            "response": "Speaking in public or starting a conversation can feel incredibly daunting. A good trick is to focus on your breathing and speak slightly slower than usual. Would you like some tips on pacing, or do you just want to talk about it?"
        },
        {
            "query": "i feel like a failure hopeless depressed sad down bad low",
            "response": "I'm really sorry you're feeling this way, but please remember that a single day, setback, or mistake doesn't define your worth. Be gentle with yourself today. I'm here to support you."
        },
        {
            "query": "i made a mistake awkward embarrassing stupid",
            "response": "We all make social mistakes; it's a completely normal part of being human. Often, other people don't notice it as much as we think they do. Try to let it go and focus on the present moment."
        },
        
        # Interview Advice (Empathetic / Non-forcing)
        {
            "query": "i have an interview upcoming job interview nervous",
            "response": "Congratulations on the interview! It's completely natural to feel nervous. An interview is just a two-way conversation to see if it's a mutual fit. What kind of role is it for? We can chat about how to present your strengths."
        },
        {
            "query": "how do i answer tell me about yourself resume experience",
            "response": "For 'tell me about yourself', try to structure it in three steps: Present (your current role/skills), Past (a key achievement or project), and Future (why you're excited for this role). It keeps your response focused and engaging."
        },
        {
            "query": "how to handle salary question interview",
            "response": "When asked about salary, you can pivot to focusing on the role: 'I am open to a competitive offer that aligns with the responsibilities of the role and my experience. Do you have a budget in mind for this position?'"
        },
        
        # Relationships & Awkward Conversations
        {
            "query": "my friend is ignoring me not replying text ghosted",
            "response": "It hurts when a friend doesn't reply. People often get busy or might be dealing with their own silent struggles. Try giving them a bit of space, and when you reach out, keep it light and low-pressure."
        },
        {
            "query": "i need to have an awkward conversation conflict boundary",
            "response": "Awkward conversations are tough but necessary. Try to use 'I' statements instead of 'You' statements. For example, 'I feel overwhelmed when...' instead of 'You always...'. This prevents the other person from getting defensive."
        },
        {
            "query": "how to apologize say sorry conflict mistake",
            "response": "A sincere apology has three parts: acknowledging the impact of your actions, saying 'I'm sorry' clearly, and offering a way to fix it or do better next time. Avoid adding 'but' or excuses."
        },
        
        # General Chit-chat fallbacks
        {
            "query": "tell me a joke fun humor laugh",
            "response": "Why don't scientists trust atoms? Because they make up everything! I hope that brought a small smile to your face."
        },
        {
            "query": "thank you thanks helper useful great good job",
            "response": "You're very welcome! I'm glad I could help. Remember, building communication confidence is a journey, and you're doing great."
        },
        {
            "query": "bye goodbye talk later end see you",
            "response": "Goodbye! Take care of yourself. I'm always here whenever you need another chat or some communication advice. Have a wonderful day!"
        }
    ]
    
    # Let's also load custom dataset items to expand coverage
    dataset_path = os.path.join(os.path.dirname(__file__), "..", "socialsync_dataset.json")
    if os.path.exists(dataset_path):
        try:
            with open(dataset_path, "r", encoding="utf-8") as f:
                social_data = json.load(f)
            for item in social_data:
                # Add context as part of query tags
                corpus.append({
                    "query": f"{item['context'].lower()} {item['original_message'].lower()}",
                    "response": f"{item['improved_message']} (Tip: Focus on a confident, balanced delivery.)"
                })
        except Exception as e:
            print(f"[ML Training] Warning loading socialsync_dataset: {e}")
            
    return corpus

def train_dialogue_retriever():
    print("[ML Training] Starting Conversational Dialogue Retriever training...")
    corpus = get_conversational_corpus()
    
    queries = [item["query"] for item in corpus]
    responses = [item["response"] for item in corpus]
    
    vectorizer = TfidfVectorizer(stop_words="english", ngram_range=(1, 2))
    tfidf_matrix = vectorizer.fit_transform(queries)
    
    model_data = {
        "vectorizer": vectorizer,
        "tfidf_matrix": tfidf_matrix,
        "responses": responses
    }
    
    models_dir = os.path.join(os.path.dirname(__file__), "..", "models")
    os.makedirs(models_dir, exist_ok=True)
    model_path = os.path.join(models_dir, "conversational_retriever.pkl")
    
    joblib.dump(model_data, model_path)
    print(f"[ML Training] Conversational Dialogue Retriever saved to {model_path} with {len(corpus)} dialog states.")

if __name__ == "__main__":
    train_dialogue_retriever()
