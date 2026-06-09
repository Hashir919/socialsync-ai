-- SocialSync AI Database Schema for Supabase

-- Profiles Table (holds user details synced from Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Conversations Table (holds live-assist and chat logs)
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    transcript TEXT,
    emotion TEXT,
    pace TEXT,
    confidence TEXT,
    suggestion TEXT,
    context TEXT,
    mode TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Anxiety Logs (tracks real-time performance metrics for analytics)
CREATE TABLE IF NOT EXISTS public.anxiety_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    session_id UUID,
    anxiety INTEGER NOT NULL, -- 0-100
    confidence INTEGER NOT NULL, -- 0-100
    clarity INTEGER NOT NULL, -- 0-100
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Practice Sessions (saved simulated roleplay sessions with AI coaches)
CREATE TABLE IF NOT EXISTS public.practice_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    persona TEXT NOT NULL,
    duration_seconds INTEGER,
    final_anxiety INTEGER,
    final_confidence INTEGER,
    final_clarity INTEGER,
    feedback_tips TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- User Progress (tracks streaks and overall training statistics)
CREATE TABLE IF NOT EXISTS public.user_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    streak_days INTEGER DEFAULT 0 NOT NULL,
    total_practice_minutes INTEGER DEFAULT 0 NOT NULL,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anxiety_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies allowing users to read and write their own data
CREATE POLICY "Users can view own profiles" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profiles" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own conversations" ON public.conversations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own conversations" ON public.conversations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own anxiety logs" ON public.anxiety_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own anxiety logs" ON public.anxiety_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own practice sessions" ON public.practice_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own practice sessions" ON public.practice_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert/update own progress" ON public.user_progress FOR ALL USING (auth.uid() = user_id);
