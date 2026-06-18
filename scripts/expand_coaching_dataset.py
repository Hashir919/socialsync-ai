import os
import json
import random

COACHING_PATH = os.path.join(os.path.dirname(__file__), "..", "backend", "coaching_dataset.json")

def main():
    if os.path.exists(COACHING_PATH):
        with open(COACHING_PATH, "r", encoding="utf-8") as f:
            existing_data = json.load(f)
    else:
        existing_data = []

    print(f"Loaded {len(existing_data)} existing coaching examples.")

    categories_templates = {
        "loneliness": {
            "context": "Loneliness",
            "category": "lonely",
            "prefixes": ["I feel so ", "Lately I've been feeling ", "I am feeling extremely ", "It's hard because I'm so ", "Sometimes I just feel "],
            "cores": ["lonely and disconnected", "isolated from everyone", "alone with nobody to talk to", "left out by the world", "like I have no close connections"],
            "suffixes": [" and don't know how to start conversations.", " and it is starting to get to me.", " and I don't know what to do.", " and I wish I had someone to reach out to.", " during the weekends."],
            "emotions": ["Sadness", "Fear", "Neutral"],
            "suggestions": [
                "Acknowledge the feeling gently. Focus on self-compassion and think of one small, low-pressure interaction to try.",
                "Loneliness is a signal for connection. Take it step-by-step by joining a shared-interest group or calling a family member."
            ],
            "improved": [
                "It's completely valid to feel lonely. Let's start with a low-pressure step, like saying hi to someone in a hobby group or online community.",
                "Feeling isolated can be really tough. Remember, you don't have to jump into deep conversations right away. Even a small connection counts."
            ]
        },
        "friendship": {
            "context": "Friendship",
            "category": "anxious",
            "prefixes": ["My friend ", "A close friend of mine ", "Someone I considered a good friend ", "My best friend "],
            "cores": ["ignored my message", "left me out of their weekend plans", "stopped replying to me out of nowhere", "seems to be avoiding me", "criticized me in front of others"],
            "suffixes": [" and I feel really upset.", " and I don't know if I did something wrong.", " and I feel anxious about reaching out again.", " which makes me feel excluded.", " and it hurts a lot."],
            "emotions": ["Sadness", "Anger", "Fear"],
            "suggestions": [
                "Express your feelings using 'I' statements to avoid sounding accusatory. Give them space but check in gently.",
                "Acknowledge your hurt feelings, but try not to jump to conclusions about their intent. Re-engage with calmness."
            ],
            "improved": [
                "It can hurt when a friend pulls away. Try sending a gentle message: 'Hey, noticed you've been a bit quiet lately. Hope everything is okay!'",
                "Try saying: 'Hey, I felt a bit left out when you guys hung out last weekend. Just wanted to share how I felt, hope we can catch up soon!'"
            ]
        },
        "social_anxiety": {
            "context": "Social Anxiety",
            "category": "anxious",
            "prefixes": ["I am so ", "I always get incredibly ", "Every time I go out, I feel ", "I get really ", "I am super "],
            "cores": ["nervous about meeting new people", "anxious when walking into a crowded room", "scared that people are judging me", "terrified of making a fool of myself", "tense when having to make small talk"],
            "suffixes": [" in social situations.", " and I just want to run away.", " and my heart starts beating so fast.", " which makes me avoid parties entirely.", " and I freeze up."],
            "emotions": ["Fear", "Nervousness", "Neutral"],
            "suggestions": [
                "Shift your focus outward onto others rather than inward on your physical symptoms. Take slow, deep breaths.",
                "Recognize that social anxiety is common. Focus on finding one friendly face and asking a simple, open-ended question."
            ],
            "improved": [
                "It's normal to feel nervous. Try taking three deep breaths and focusing on one person. You can ask a simple question like, 'How do you know the host?'",
                "Try shifting your attention to the environment. Remember, most people are focused on themselves, not judging you. You've got this!"
            ]
        },
        "overthinking": {
            "context": "Overthinking",
            "category": "anxious",
            "prefixes": ["I keep ", "I can't stop ", "I spend hours ", "Every night I lie awake ", "I am constantly "],
            "cores": ["replaying conversations in my head", "analyzing everything I said to my boss", "worrying that I made a bad impression", "overthinking my texts before sending them", "regretting the joke I made earlier"],
            "suffixes": [" after talking to people.", " and it makes me feel so insecure.", " and second-guessing every detail.", " and feeling stupid about it.", " even though it was a minor interaction."],
            "emotions": ["Fear", "Sadness", "Neutral"],
            "suggestions": [
                "Practice mindfulness to ground yourself in the present. Gently interrupt the replay loop by reminding yourself that minor slips are rarely remembered.",
                "Give yourself a set limit (e.g. 5 minutes) to review a conversation, then deliberately pivot to another engaging activity."
            ],
            "improved": [
                "Overthinking is very common. When a replay starts, tell yourself: 'That conversation is in the past, and I did the best I could.' Let's focus on the present.",
                "Try saying to yourself: 'Most people don't analyze my words the way I do.' It's safe to let it go and focus on what you're doing right now."
            ]
        },
        "dating": {
            "context": "Dating",
            "category": "anxious",
            "prefixes": ["I am so scared to ", "I feel extremely anxious about ", "What if I ", "I don't know how to ", "I'm nervous to "],
            "cores": ["ask her out on a date", "go on a first date with this person", "start a conversation on a dating app", "admit my feelings to someone I like", "confess that I like them"],
            "suffixes": [" because I'm afraid of rejection.", " and worry we will run out of things to say.", " and end up sounding completely awkward.", " and get ghosted.", " and make things weird between us."],
            "emotions": ["Fear", "Nervousness", "Excitement"],
            "suggestions": [
                "Keep dating low-stakes. Reframe a first date as just a fun test run to see if you enjoy their company, rather than a performance.",
                "When starting a conversation, ask about a detail in their profile. This shows genuine interest and makes it easy to reply."
            ],
            "improved": [
                "Dating jitters are normal. Try asking an open-ended question about something you noticed on their profile, like: 'That travel photo looks amazing, where was it taken?'",
                "Remember, a date is just a chance to see if you have chemistry. You don't have to be perfect. If there's a pause, just ask about their favorite weekend activities."
            ]
        },
        "rejection": {
            "context": "Rejection",
            "category": "sad",
            "prefixes": ["A girl ", "The person I was talking to ", "The interviewer ", "The company ", "My crush "],
            "cores": ["stopped replying to my messages", "ghosted me after a great conversation", "rejected my job application", "said they just want to be friends", "turned me down when I asked them out"],
            "suffixes": [" and I feel like giving up.", " and it makes me feel totally worthless.", " and I feel so down about it.", " which makes me doubt myself.", " and I'm embarrassed."],
            "emotions": ["Sadness", "Disappointment", "Anger"],
            "suggestions": [
                "Rejection is not a reflection of your worth. It's just a misalignment of timing or compatibility. Be proud of taking the risk.",
                "Allow yourself to feel disappointed, but don't let it define your self-image. Focus on the next opportunity."
            ],
            "improved": [
                "Rejection is painful, but it doesn't define your value. Be proud that you put yourself out there. Each step is progress toward the right match.",
                "It's completely okay to feel disappointed. When someone stops replying, it's a reflection of their capacity, not your worth. Keep moving forward!"
            ]
        },
        "confidence": {
            "context": "Confidence",
            "category": "confident",
            "prefixes": ["How do I ", "I want to learn how to ", "I need to ", "I wish I could ", "I'm trying to "],
            "cores": ["become more confident when speaking", "stand up for myself in conversations", "express my opinions without feeling guilty", "stop being a people pleaser", "project confidence even when nervous"],
            "suffixes": [" in front of others.", " and command respect.", " and speak with authority.", " so I can be authentic.", " in group settings."],
            "emotions": ["Neutral", "Joy", "Nervousness"],
            "suggestions": [
                "Practice assertive communication. Stand tall, speak at a moderate pace, and use clear 'I' statements to own your perspective.",
                "Build confidence through small wins. Express a minor preference first, and gradually share larger opinions."
            ],
            "improved": [
                "Building confidence starts with owning your thoughts. Try using phrases like 'In my view...' or 'I recommend...' instead of apologetic language.",
                "Confidence is a skill you practice. Start by standing tall, maintaining eye contact, and expressing your genuine preferences in low-stakes situations."
            ]
        },
        "networking": {
            "context": "Networking",
            "category": "confident",
            "prefixes": ["I am going to a ", "How should I ", "I always struggle with ", "I feel awkward at a ", "I want to "],
            "cores": ["networking event tomorrow", "introduce myself to professionals", "pitching my skills to recruiters", "career fair or industry mixer", "connect with senior managers on LinkedIn"],
            "suffixes": [" and don't know what to say.", " in a way that stands out.", " without sounding arrogant.", " and want to make a good impression.", " and get a response."],
            "emotions": ["Fear", "Nervousness", "Neutral"],
            "suggestions": [
                "Prepare a concise, 2-sentence elevator pitch focusing on your passion and what you enjoy building. Ask about their work to build a real connection.",
                "Networking is just professional friend-making. Keep it conversational: ask about their career path and share your enthusiasm."
            ],
            "improved": [
                "At a networking event, a clean intro and a genuine question about their work opens the conversation. Try: 'Hi, I'm [Name]. I've been working on [Project/Field] and would love to hear about what you're working on here!'",
                "Try focusing on learning rather than selling yourself. Ask questions like: 'What's the most exciting project you're working on right now?' People love sharing their expertise."
            ]
        },
        "awkward": {
            "context": "Awkward Conversations",
            "category": "awkward",
            "prefixes": ["There was a ", "I accidentally ", "I'm worried about ", "How do I handle ", "I always make things "],
            "cores": ["long painful silence in our chat", "said something awkward and weird", "running out of things to talk about", "having an awkward interaction with a colleague", "feel uncomfortable during small talk"],
            "suffixes": [" and I didn't know what to say.", " and felt so embarrassed afterwards.", " which makes me feel self-conscious.", " and want to fix it.", " when meeting new people."],
            "emotions": ["Embarrassment", "Fear", "Neutral"],
            "suggestions": [
                "Embrace pauses naturally. You can call it out with a smile or transition to a new topic by asking an open-ended question.",
                "If you make a conversational slip, smile, make a lighthearted comment to diffuse it, and move forward."
            ],
            "improved": [
                "Conversational pauses are completely natural. If a silence feels long, try transitioning with: 'That reminds me, did you hear about...' or ask a light question about their week.",
                "If you say something awkward, just smile and say, 'Well, that came out a bit funny! What I meant was...' and keep the tone light."
            ]
        },
        "self_esteem": {
            "context": "Self-Esteem",
            "category": "sad",
            "prefixes": ["I feel like ", "I keep comparing myself to ", "I am constantly ", "Lately I feel so ", "It's hard not to "],
            "cores": ["I'm not good enough for this group", "successful peers and feeling like a failure", "doubting my abilities and skills", "insecure about my appearance and personality", "feel like I'm falling behind everyone else"],
            "suffixes": [" and it makes me feel so down.", " and losing my self-confidence.", " and worrying about my future.", " in every social interaction.", " and doubting my path."],
            "emotions": ["Sadness", "Disappointment", "Fear"],
            "suggestions": [
                "Practice self-compassion. Focus on your unique strengths and remind yourself that social media highlights are not reality.",
                "Interrupt negative self-talk. Treat yourself with the same kindness and encouragement you would offer to a close friend."
            ],
            "improved": [
                "You are worthy of connection just as you are. Try to replace self-criticism with self-compassion. Remind yourself of three things you did well this week.",
                "Comparing your behind-the-scenes with others' highlight reels is a recipe for doubt. Focus on your own growth and be proud of your progress."
            ]
        }
    }

    new_examples = []
    # Generate ~80 examples per category to get ~800 total new examples
    for label, info in categories_templates.items():
        count_generated = 0
        while count_generated < 85:
            prefix = random.choice(info["prefixes"])
            core = random.choice(info["cores"])
            suffix = random.choice(info["suffixes"])
            text = f"{prefix}{core}{suffix}"
            
            emotion = random.choice(info["emotions"])
            suggestion = random.choice(info["suggestions"])
            improved = random.choice(info["improved"])
            
            # Avoid duplicate texts
            if any(x["text"] == text for x in new_examples) or any(x["text"] == text for x in existing_data):
                continue
                
            new_examples.append({
                "text": text,
                "emotion": emotion,
                "suggestion": suggestion,
                "improved": improved,
                "category": info["category"],
                "context": info["context"]
            })
            count_generated += 1

    merged_data = existing_data + new_examples
    print(f"Generated {len(new_examples)} new examples. Total dataset size: {len(merged_data)}.")

    with open(COACHING_PATH, "w", encoding="utf-8") as f:
        json.dump(merged_data, f, indent=2, ensure_ascii=False)
    
    print("Successfully expanded coaching dataset and saved to coaching_dataset.json.")

if __name__ == "__main__":
    main()
