import json
import os


TARGET_SIZE = 1200


CONTEXT_BLUEPRINTS = {
    "Dating": {
        "topics": [
            "coffee after work",
            "dinner on Friday",
            "a weekend walk",
            "trying a new cafe",
            "checking out that art market",
            "watching the new movie downtown",
            "grabbing brunch",
            "going to a rooftop event",
        ],
        "categories": {
            "anxious": {
                "emotion": "Anxiety",
                "anxiety_base": 0.86,
                "original_templates": [
                    "Sorry to bother you, but maybe we could {topic} if you are not too busy.",
                    "I know this might be random, but would you maybe want to {topic} sometime?",
                    "I hope I am not being awkward, but I was wondering if you would like to {topic}.",
                    "If you are free, maybe we could {topic}, but no pressure at all.",
                    "I am probably overthinking this, but would you be open to {topic}?",
                ],
                "improved_templates": [
                    "I've enjoyed talking with you. Would you like to {topic} this week?",
                    "I'd love to spend more time together. Are you free for {topic} soon?",
                    "You seem really fun to be around. Want to {topic} sometime this week?",
                    "I'd like to take you out for {topic}. What day works best for you?",
                    "Let's make a plan for {topic}. Are you free this weekend?",
                ],
            },
            "dry": {
                "emotion": "Neutral",
                "anxiety_base": 0.16,
                "original_templates": [
                    "ok",
                    "cool",
                    "sounds good",
                    "nothing much",
                    "yeah maybe",
                ],
                "improved_templates": [
                    "That sounds great. What are you most looking forward to about it?",
                    "Nice, I'm into that. How did you get interested in it?",
                    "Sounds good to me. What time were you thinking?",
                    "Pretty relaxed on my side, but I'm curious about your day. How has it been?",
                    "I'm open to that. What kind of plan did you have in mind?",
                ],
            },
            "awkward": {
                "emotion": "Anger",
                "anxiety_base": 0.58,
                "original_templates": [
                    "Why did you not reply to me yesterday?",
                    "You looked different than your photos.",
                    "I guess if you are busy I will stop trying.",
                    "My ex used to love places like this.",
                    "Are you even interested in seeing me again?",
                ],
                "improved_templates": [
                    "Hey, hope your day went well. Let me know when you're free to catch up.",
                    "It's really nice to finally spend time together in person.",
                    "No rush at all. Reach out when you have a free moment and want to talk.",
                    "This place has a great vibe. I'm glad we picked it.",
                    "I had a great time with you. I'd be happy to see you again if you're interested.",
                ],
            },
            "confident": {
                "emotion": "Joy",
                "anxiety_base": 0.12,
                "original_templates": [
                    "I had fun today.",
                    "I liked talking with you.",
                    "That was nice.",
                    "I think you are cool.",
                    "I want to see you again.",
                ],
                "improved_templates": [
                    "I had a really good time with you today. I'd love to do it again soon.",
                    "Talking with you felt easy and fun. I'd like to keep that going.",
                    "That was such a nice time. We should plan another hangout soon.",
                    "You have a great energy. I'd love to get to know you better.",
                    "I enjoyed being with you and would love to see you again next week.",
                ],
            },
        },
    },
    "Interview": {
        "topics": [
            "state management",
            "system design",
            "cross-functional teamwork",
            "leading a project",
            "debugging production issues",
            "performance optimization",
            "customer empathy",
            "shipping under deadlines",
        ],
        "categories": {
            "anxious": {
                "emotion": "Anxiety",
                "anxiety_base": 0.83,
                "original_templates": [
                    "I am not sure I am the best candidate, but I will try my best.",
                    "Sorry if this answer is not very good, but I worked on {topic} a little.",
                    "I guess I can help with {topic}, although others probably know more than me.",
                    "I hope this does not sound silly, but I have some experience with {topic}.",
                    "I get nervous talking about my work, but I did support {topic}.",
                ],
                "improved_templates": [
                    "I bring hands-on experience with {topic} and a strong track record of delivering thoughtful results.",
                    "I've worked directly on {topic} and can explain both the technical decisions and the impact.",
                    "My experience with {topic} has helped me build clear, scalable solutions in fast-moving teams.",
                    "I am confident discussing {topic} because I've applied it in real projects and learned what works well.",
                    "I can contribute immediately in areas like {topic}, collaboration, and execution under pressure.",
                ],
            },
            "dry": {
                "emotion": "Neutral",
                "anxiety_base": 0.18,
                "original_templates": [
                    "Yes, I know {topic}.",
                    "I like teamwork.",
                    "The project was fine.",
                    "I solved bugs.",
                    "I can learn fast.",
                ],
                "improved_templates": [
                    "Yes, I have practical experience with {topic} and can share how I've used it to improve outcomes.",
                    "I work well in collaborative teams and make a point of keeping communication clear and proactive.",
                    "That project was especially valuable because it sharpened my judgment around delivery and prioritization.",
                    "I regularly troubleshoot issues methodically and communicate progress clearly while resolving them.",
                    "I ramp up quickly by asking good questions, documenting what I learn, and turning feedback into action.",
                ],
            },
            "awkward": {
                "emotion": "Fear",
                "anxiety_base": 0.62,
                "original_templates": [
                    "Please hire me, I really need this job.",
                    "I think I did okay, maybe not amazing.",
                    "I do not know why you should pick me over other people.",
                    "I am not great at talking about myself.",
                    "I probably messed up that question.",
                ],
                "improved_templates": [
                    "I'm excited about this role because my background aligns well with what your team is building.",
                    "I approached that challenge with a focus on clarity, ownership, and measurable impact.",
                    "What sets me apart is the mix of technical execution, collaboration, and steady follow-through I bring.",
                    "I communicate best by grounding my experience in real examples and outcomes.",
                    "If it would be helpful, I can revisit that answer and structure it more clearly.",
                ],
            },
            "confident": {
                "emotion": "Joy",
                "anxiety_base": 0.1,
                "original_templates": [
                    "I am excited about this role.",
                    "I like solving hard problems.",
                    "I have led projects before.",
                    "I enjoy mentoring teammates.",
                    "I care a lot about product quality.",
                ],
                "improved_templates": [
                    "I'm excited about this role because it matches both my strengths and the kind of impact I want to make.",
                    "I enjoy solving hard problems by breaking them down, aligning the team, and executing with focus.",
                    "I've led projects from planning through delivery and kept stakeholders aligned along the way.",
                    "I enjoy mentoring because it strengthens the whole team and helps good habits spread quickly.",
                    "I care deeply about product quality, especially where user trust and long-term maintainability are involved.",
                ],
            },
        },
    },
    "Workplace": {
        "topics": [
            "the release plan",
            "this bug",
            "handoff notes",
            "the API contract",
            "the design feedback",
            "the team timeline",
            "the incident review",
            "the client request",
        ],
        "categories": {
            "anxious": {
                "emotion": "Anxiety",
                "anxiety_base": 0.79,
                "original_templates": [
                    "Sorry if this is a dumb question, but can you explain {topic}?",
                    "I might have made a mistake on {topic}, please do not be upset.",
                    "I hope I am not bothering you, but I need help with {topic}.",
                    "I think I messed up {topic} and I feel really bad about it.",
                    "This may be obvious to everyone else, but I want to ask about {topic}.",
                ],
                "improved_templates": [
                    "I have a quick question about {topic} and would appreciate your perspective.",
                    "I've reviewed {topic} and want to confirm one detail so we stay aligned.",
                    "When you have a moment, I'd appreciate your help thinking through {topic}.",
                    "I found an issue in {topic} and I'm already working on the next step to address it.",
                    "I want to clarify {topic} so I can move forward confidently and avoid rework.",
                ],
            },
            "dry": {
                "emotion": "Neutral",
                "anxiety_base": 0.14,
                "original_templates": [
                    "I did it.",
                    "That works.",
                    "Fine by me.",
                    "I can help.",
                    "It is done.",
                ],
                "improved_templates": [
                    "I've completed it and can walk you through the key changes if helpful.",
                    "That approach works for me. I can start on it this afternoon.",
                    "I'm aligned with that direction and ready to move forward.",
                    "I'm happy to help. Tell me which piece would be most useful for me to take.",
                    "It's finished on my side, and I documented the main decisions for the team.",
                ],
            },
            "awkward": {
                "emotion": "Anger",
                "anxiety_base": 0.49,
                "original_templates": [
                    "You need to fix {topic} right now because it is blocking me.",
                    "That idea is bad and will not work.",
                    "Do not blame me for {topic}.",
                    "They never listen when I talk about {topic}.",
                    "This is frustrating and I am tired of repeating myself about {topic}.",
                ],
                "improved_templates": [
                    "Could we look at {topic} together soon? It's currently blocking my progress.",
                    "I have some concerns about {topic}. Could we compare a couple of alternatives?",
                    "Let's review {topic} together so we can align on what happened and what to do next.",
                    "I want to make sure my concerns about {topic} are understood. Can we talk through them directly?",
                    "I'm feeling some frustration around {topic}, and I'd like to reset on a constructive path forward.",
                ],
            },
            "confident": {
                "emotion": "Joy",
                "anxiety_base": 0.11,
                "original_templates": [
                    "I have an idea for {topic}.",
                    "I can own {topic}.",
                    "I think we can improve {topic}.",
                    "I want to lead the discussion on {topic}.",
                    "I am ready to present {topic}.",
                ],
                "improved_templates": [
                    "I have a clear proposal for {topic} and would love to walk the team through it.",
                    "I'm happy to take ownership of {topic} and keep everyone updated on progress.",
                    "I see a strong opportunity to improve {topic} with a few focused changes.",
                    "I'm ready to lead the discussion on {topic} and help us reach a concrete decision.",
                    "I've prepared a structured update on {topic} and can present the key points clearly.",
                ],
            },
        },
    },
    "Friendship": {
        "topics": [
            "catching up this week",
            "talking through what happened",
            "making weekend plans",
            "checking in after a rough day",
            "reconnecting after some distance",
            "clearing up a misunderstanding",
            "planning something fun together",
            "supporting each other better",
        ],
        "categories": {
            "anxious": {
                "emotion": "Anxiety",
                "anxiety_base": 0.81,
                "original_templates": [
                    "Are you mad at me? I am sorry if I did something wrong.",
                    "I know I am probably overreacting, but can we talk about {topic}?",
                    "I feel like I am bothering you, so maybe I should stop texting.",
                    "Sorry for reaching out again, I just wanted to ask about {topic}.",
                    "I am worried you do not want to be friends anymore.",
                ],
                "improved_templates": [
                    "Hey, I wanted to check in and see how you're doing. I'm here if you want to talk.",
                    "I'd really value a conversation about {topic} when you have the space for it.",
                    "I care about our friendship and wanted to reach out instead of making assumptions.",
                    "When you have a moment, I'd love to talk about {topic} and make sure we're okay.",
                    "You matter to me, and I'd appreciate a chance to reconnect when you're ready.",
                ],
            },
            "dry": {
                "emotion": "Neutral",
                "anxiety_base": 0.18,
                "original_templates": [
                    "k",
                    "sure",
                    "whatever works",
                    "nothing really",
                    "yeah",
                ],
                "improved_templates": [
                    "Okay, sounds good. Let me know what time works best for you.",
                    "Sure, I'm in. What did you have in mind?",
                    "That works for me. I'm happy to go with whatever feels fun.",
                    "Not much on my side, but I'd love to hear what's new with you.",
                    "Yeah, definitely. Tell me more about what you're thinking.",
                ],
            },
            "awkward": {
                "emotion": "Anger",
                "anxiety_base": 0.54,
                "original_templates": [
                    "Why are you ignoring me?",
                    "You always make jokes at my expense.",
                    "I guess I am not important to you.",
                    "You never show up when I need you.",
                    "I am tired of pretending that comment did not hurt.",
                ],
                "improved_templates": [
                    "I wanted to check in because I felt a little disconnected and would like to talk.",
                    "That joke landed hard for me, and I'd appreciate talking about it privately.",
                    "Our friendship matters to me, which is why I want to be honest about how I felt.",
                    "I felt unsupported in that moment, and I'd like us to clear it up together.",
                    "That comment stayed with me, and I think a quick conversation could help us reset.",
                ],
            },
            "confident": {
                "emotion": "Joy",
                "anxiety_base": 0.1,
                "original_templates": [
                    "I miss hanging out.",
                    "You are a good friend.",
                    "We should do something soon.",
                    "I appreciate you.",
                    "I want to be more intentional about keeping in touch.",
                ],
                "improved_templates": [
                    "I miss spending time with you. Let's make a plan soon and actually lock it in.",
                    "You're a really good friend, and I appreciate the way you show up.",
                    "We should do something soon. Want to plan something for this weekend?",
                    "I appreciate you a lot and wanted to say that directly.",
                    "I'd love to be more intentional about staying in touch because our friendship matters to me.",
                ],
            },
        },
    },
    "Public Speaking": {
        "topics": [
            "opening the talk",
            "explaining the main point",
            "answering audience questions",
            "managing stage nerves",
            "presenting the roadmap",
            "sharing a personal story",
            "closing with confidence",
            "staying calm under pressure",
        ],
        "categories": {
            "anxious": {
                "emotion": "Fear",
                "anxiety_base": 0.91,
                "original_templates": [
                    "I am scared people will judge me when I start {topic}.",
                    "My hands shake every time I think about {topic}.",
                    "I do not think anyone wants to hear me talk about {topic}.",
                    "I am worried I will mess up {topic} in front of everyone.",
                    "Sorry if I sound nervous, I am struggling with {topic}.",
                ],
                "improved_templates": [
                    "I'm focusing on a calm, clear start and pacing myself while {topic}.",
                    "I can handle {topic} one sentence at a time and keep my delivery steady.",
                    "The audience is here to learn, and I have useful insight to share while {topic}.",
                    "I'm preparing a clear structure so I can stay grounded while {topic}.",
                    "Even with nerves, I can speak with clarity and keep moving through {topic}.",
                ],
            },
            "dry": {
                "emotion": "Neutral",
                "anxiety_base": 0.2,
                "original_templates": [
                    "Today I will talk about {topic}.",
                    "That is my point.",
                    "Any questions?",
                    "This matters.",
                    "Thanks.",
                ],
                "improved_templates": [
                    "Today I want to walk you through {topic} and why it matters right now.",
                    "That point matters because it shapes how we make the next decision.",
                    "I'd love to hear your questions and where you'd like to go deeper.",
                    "This matters because it affects outcomes, trust, and long-term momentum.",
                    "Thank you for your time and attention. I'm happy to keep the conversation going.",
                ],
            },
            "awkward": {
                "emotion": "Sadness",
                "anxiety_base": 0.57,
                "original_templates": [
                    "I am probably explaining this badly.",
                    "This slide is confusing, sorry.",
                    "I lost my train of thought.",
                    "I know this is boring.",
                    "That answer might not make sense.",
                ],
                "improved_templates": [
                    "Let me reframe that more clearly and connect it back to the main idea.",
                    "I'll simplify this slide and focus on the one point that matters most.",
                    "Let me pause for a second and pick the thread back up clearly.",
                    "I'll keep this concise and focus on the part that is most useful to you.",
                    "Let me answer that in a clearer structure so it is easier to follow.",
                ],
            },
            "confident": {
                "emotion": "Joy",
                "anxiety_base": 0.09,
                "original_templates": [
                    "I am ready for this talk.",
                    "I know this material well.",
                    "I want the audience to leave with one clear idea.",
                    "I have a strong opening prepared.",
                    "I can answer tough questions.",
                ],
                "improved_templates": [
                    "I'm ready for this talk and prepared to lead the room with clarity and energy.",
                    "I know this material deeply and can explain it in a way that feels accessible.",
                    "I want the audience to leave with one clear takeaway they can act on immediately.",
                    "I have a strong opening prepared that will earn attention right away.",
                    "I can handle tough questions by staying calm, listening closely, and answering directly.",
                ],
            },
        },
    },
    "Networking": {
        "topics": [
            "introducing myself",
            "following up after the event",
            "asking about their work",
            "sharing my background",
            "suggesting a coffee chat",
            "staying memorable",
            "building a long-term connection",
            "talking about opportunities",
        ],
        "categories": {
            "anxious": {
                "emotion": "Anxiety",
                "anxiety_base": 0.77,
                "original_templates": [
                    "I am not great at networking, but I thought I should say hi.",
                    "Sorry if I am interrupting, I just wanted to ask about {topic}.",
                    "I never know what to say when {topic}.",
                    "I hope this is not awkward, but could we talk about {topic}?",
                    "I feel nervous meeting new people when {topic}.",
                ],
                "improved_templates": [
                    "Hi, it's great to meet you. I'd love to hear more about your experience with {topic}.",
                    "I wanted to introduce myself and ask about {topic} because your work caught my attention.",
                    "I'm glad we connected. I'd enjoy hearing your perspective on {topic}.",
                    "I'd love to talk about {topic} for a few minutes if now is a good time.",
                    "Meeting new people gets easier when I stay curious, so I'd love to hear about {topic}.",
                ],
            },
            "dry": {
                "emotion": "Neutral",
                "anxiety_base": 0.15,
                "original_templates": [
                    "Nice to meet you.",
                    "I work in tech.",
                    "Cool event.",
                    "Maybe we can connect.",
                    "Sounds interesting.",
                ],
                "improved_templates": [
                    "Nice to meet you. What kind of work are you most excited about these days?",
                    "I work in tech, mostly around product and delivery. What space are you focused on?",
                    "This has been a great event so far. What brought you here today?",
                    "I'd be glad to stay connected. Are you open to trading LinkedIn details?",
                    "That sounds interesting. I'd love to hear how you got into that area.",
                ],
            },
            "awkward": {
                "emotion": "Anger",
                "anxiety_base": 0.46,
                "original_templates": [
                    "I need a job, so I am talking to everyone here.",
                    "Can you refer me right now?",
                    "I do not really care about the event, I just need contacts.",
                    "I am just trying to get something out of this.",
                    "I should probably pitch myself before you walk away.",
                ],
                "improved_templates": [
                    "I'm exploring new opportunities and would love to learn more about your work first.",
                    "If it makes sense after we chat, I'd value any advice on how to position myself well.",
                    "I'm hoping to build real connections here and learn from people doing thoughtful work.",
                    "I want to understand where I might add value before I ask for anything specific.",
                    "I'd love to share a quick snapshot of my background and hear what you're working on too.",
                ],
            },
            "confident": {
                "emotion": "Joy",
                "anxiety_base": 0.08,
                "original_templates": [
                    "I have a clear story about what I do.",
                    "I like meeting people in this space.",
                    "I can explain my work well.",
                    "I enjoy learning about other teams.",
                    "I know how I want to follow up.",
                ],
                "improved_templates": [
                    "I have a clear story about what I do and how I help teams move faster with better alignment.",
                    "I genuinely enjoy meeting people in this space and learning what challenges they are solving.",
                    "I can explain my work clearly, especially where strategy and execution meet.",
                    "I enjoy learning how other teams operate because it sharpens my own judgment too.",
                    "I know how I want to follow up and keep the conversation useful for both sides.",
                ],
            },
        },
    },
}


CURATED_SEEDS = [
    {
        "original_message": "Please hire me, I'm begging.",
        "improved_message": "I look forward to the possibility of contributing to your team's success.",
        "context": "Interview",
        "emotion": "Anxiety",
        "anxiety_score": 0.92,
        "category": "anxious",
    },
    {
        "original_message": "Why are you ignoring me?",
        "improved_message": "Hey, I just wanted to check in. Is everything okay?",
        "context": "Friendship",
        "emotion": "Anger",
        "anxiety_score": 0.74,
        "category": "awkward",
    },
    {
        "original_message": "I hope I'm not bothering you, but could you maybe help me?",
        "improved_message": "Whenever you have a moment, I'd appreciate your help with this task.",
        "context": "Workplace",
        "emotion": "Fear",
        "anxiety_score": 0.8,
        "category": "anxious",
    },
    {
        "original_message": "I am really nervous about this presentation and my hands are shaking.",
        "improved_message": "Thank you all for being here today. I'm excited to share these updates.",
        "context": "Public Speaking",
        "emotion": "Fear",
        "anxiety_score": 0.95,
        "category": "anxious",
    },
    {
        "original_message": "We are definitely going to win this pitch. I'm so excited.",
        "improved_message": "We have a strong proposal, and I'm very excited about our chances of success.",
        "context": "Networking",
        "emotion": "Joy",
        "anxiety_score": 0.09,
        "category": "confident",
    },
]


def clean_sentence(text):
    return " ".join(text.split())


def clamp_score(value):
    return round(max(0.05, min(0.99, value)), 2)


def generate_dataset():
    dataset = []
    seen_messages = set()

    def add_example(original, improved, context, emotion, anxiety_score, category):
        original = clean_sentence(original)
        improved = clean_sentence(improved)
        if original.lower() in seen_messages:
            return
        seen_messages.add(original.lower())
        dataset.append(
            {
                "original_message": original,
                "improved_message": improved,
                "context": context,
                "emotion": emotion,
                "anxiety_score": clamp_score(anxiety_score),
                "category": category,
            }
        )

    for item in CURATED_SEEDS:
        add_example(**item)

    for context, blueprint in CONTEXT_BLUEPRINTS.items():
        topics = blueprint["topics"]
        for category, spec in blueprint["categories"].items():
            originals = spec["original_templates"]
            improved = spec["improved_templates"]
            for topic_index, topic in enumerate(topics):
                for original_index, original_template in enumerate(originals):
                    improved_template = improved[(topic_index + original_index) % len(improved)]
                    variation = ((topic_index * len(originals)) + original_index) % 6
                    anxiety_score = spec["anxiety_base"] + (variation - 2.5) * 0.03
                    add_example(
                        original=original_template.format(topic=topic),
                        improved=improved_template.format(topic=topic),
                        context=context,
                        emotion=spec["emotion"],
                        anxiety_score=anxiety_score,
                        category=category,
                    )

    # Add escalation, repair, and follow-up variants to broaden coverage without becoming repetitive.
    expansion_suffixes = {
        "anxious": [
            (" I know I may be overthinking it.", " I want to be direct and respectful."),
            (" I just did not want to say the wrong thing.", " I want to communicate this clearly."),
            (" I have been second-guessing how to phrase it.", " I am trying to be thoughtful and clear."),
            (" I kept rewriting this in my head.", " I want to say it with calm confidence."),
        ],
        "dry": [
            ("", " I'd love to keep the conversation moving."),
            ("", " Let me know what stands out to you."),
            ("", " I'm happy to hear your thoughts too."),
            ("", " I'm curious what your take is."),
        ],
        "awkward": [
            (" and it has been bothering me.", " I want us to handle it constructively."),
            (" and I do not want resentment to build.", " I care more about solving it well than blaming anyone."),
            (" because I do not want this to stay weird.", " I want to clear the air and move forward well."),
            (" and I would rather address it directly.", " I want us to leave with more understanding than tension."),
        ],
        "confident": [
            ("", " I'm looking forward to where this can go."),
            ("", " I want to bring good energy and clarity to it."),
            ("", " I feel ready to handle it thoughtfully."),
            ("", " I'm comfortable taking the lead on the next step."),
        ],
    }

    base_snapshot = list(dataset)
    for item in base_snapshot:
        category = item["category"]
        for original_tail, improved_tail in expansion_suffixes.get(category, []):
            add_example(
                original=item["original_message"] + original_tail,
                improved=item["improved_message"] + improved_tail,
                context=item["context"],
                emotion=item["emotion"],
                anxiety_score=item["anxiety_score"] + (0.02 if category == "anxious" else 0.0),
                category=category,
            )
            if len(dataset) >= TARGET_SIZE:
                break
        if len(dataset) >= TARGET_SIZE:
            break

    if len(dataset) < TARGET_SIZE:
        raise RuntimeError(f"Dataset generation produced only {len(dataset)} items, expected at least {TARGET_SIZE}.")

    dataset = dataset[:TARGET_SIZE]

    print(f"Generated custom SocialSync dataset with {len(dataset)} examples.")
    dest_path = os.path.join(os.path.dirname(__file__), "..", "socialsync_dataset.json")
    with open(dest_path, "w", encoding="utf-8") as f:
        json.dump(dataset, f, indent=2)


if __name__ == "__main__":
    generate_dataset()
