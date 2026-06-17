# SocialSync AI - Deployment Guide

This guide describes how to deploy the SocialSync AI backend (FastAPI) and frontend (Flutter Web) for free.

---

## 1. Deploying the Backend (FastAPI + WebSockets)

Since the backend requires persistent WebSockets and runs machine learning pipelines (`transformers`, `torch`), it **cannot** be hosted on serverless platforms like Vercel. 

Instead, use **Hugging Face Spaces** (highly recommended, free 16GB RAM container) or **Render** (free 512MB RAM web service).

### Option A: Hugging Face Spaces (Recommended)

Hugging Face Spaces allows you to host Docker containers for free with ample CPU and RAM.

1. **Create an account** on [Hugging Face](https://huggingface.co/).
2. **Create a new Space**:
   - Go to Spaces -> **Create new Space**.
   - Choose a name (e.g., `socialsync-api`).
   - Select **Docker** as the SDK.
   - Choose the **Blank** template.
   - Select **Public** or **Private** (Public spaces run on free hardware).
3. **Commit and Push files**:
   - Clone your new Space repository.
   - Copy the files from `/backend` to the root of the Space repository, including `Dockerfile`, `requirements.txt`, and `main.py`.
   - Copy the `/scripts` folder and `socialsync_dataset.json` into the root of the Space repository as well (so the Dockerfile paths resolve correctly).
   - Push the files. Hugging Face will automatically build and run the Docker container.
4. **Get the WebSocket URL**:
   - Once running, your space will have a URL like: `https://<username>-<space-name>.hf.space`.
   - Your WebSocket URL will be: `wss://<username>-<space-name>.hf.space/ws`.

### Option B: Render Web Service

Render offers a free tier for Web Services running Docker.

1. **Create an account** on [Render](https://render.com/).
2. **Create a New Web Service** and link your Git repository.
3. **Configure Settings**:
   - **Root Directory**: `backend`
   - **Runtime**: `Docker`
   - **Plan**: `Free`
4. **Environment Variables**:
   - Add a key `PORT` with value `8000` (or let Render assign it).
5. **Deploy**:
   - Render will build the container from `backend/Dockerfile` and deploy it.
   - Your secure WebSocket URL will be: `wss://<your-service-name>.onrender.com/ws`.

---

## 2. Deploying the Frontend (Flutter Web)

You can build the Flutter frontend for Web and host it for free on **Vercel** or **GitHub Pages**.

### Step 1: Build the Flutter Web App

Run the build command from the `frontend` directory, supplying the secure WebSocket URL (`wss://...`) of your deployed backend using `--dart-define`:

```bash
cd frontend
flutter build web --release --dart-define=BACKEND_URL=wss://your-backend-domain.com/ws
```

This generates the static web build in the `build/web/` directory.

### Step 2: Deploy to Vercel (For Free)

1. Install the Vercel CLI or link your repository to Vercel:
   - If using the **Vercel CLI**:
     ```bash
     cd build/web
     vercel deploy --prod
     ```
   - If using **GitHub Git integration**:
     - Connect your repo on the [Vercel Dashboard](https://vercel.com/).
     - Set the **Root Directory** of the project to `frontend`.
     - Set the **Build Command** to:
       `flutter build web --release --dart-define=BACKEND_URL=wss://your-backend-domain.com/ws`
     - Set the **Output Directory** to:
       `build/web`
2. Vercel will build the web app and provide a free `.vercel.app` URL.

---

## 3. Configuring Supabase

Ensure that you have set up your Supabase database tables (`conversations` and `anxiety_logs`) using the schemas provided in `backend/schema.sql`. Also, update the auth redirect URLs in your Supabase dashboard to point to your deployed frontend Vercel URL.
