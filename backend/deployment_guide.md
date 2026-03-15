# AI Backend Deployment Guide (Render)

This guide helps you deploy your AI Backend to [Render.com](https://render.com/), which is a great choice for Flask apps with external dependencies.

## 1. Prerequisites
- A GitHub account.
- Your backend code pushed to a GitHub repository.
- A free account on [Upstash](https://upstash.com/) (for Redis).

## 2. Setup Redis (Upstash)
1. Go to [Upstash Console](https://console.upstash.com/).
2. Create a new "Redis" Database.
3. Select a region close to your target users (e.g., `us-east-1`).
4. Copy the **REST URL** or **Redis URL**. It looks like `redis://default:xxx@xxx.upstash.io:6379`.

## 3. Deploy to Render
1. Log in to [Render Dashboard](https://dashboard.render.com/).
2. Click **New +** -> **Web Service**.
3. Connect your GitHub repository.
4. Configure the service:
    - **Name**: `ai-quiz-backend` (or your choice).
    - **Language**: `Python 3`.
    - **Build Command**: `pip install -r requirements.txt`.
    - **Start Command**: `gunicorn app:app`.
5. Click **Advanced** to add **Environment Variables**:
    - `OPENAI_API_KEY`: Your OpenAI key.
    - `PINECONE_API_KEY`: Your Pinecone key.
    - `SUPABASE_URL`: Your Supabase URL.
    - `SUPABASE_KEY`: Your Supabase Service/Anon key.
    - `REDIS_URL`: The URL you copied from Upstash.
6. Click **Create Web Service**.

## 4. Update Flutter App
Once deployed, Render will give you a public URL (e.g., `https://ai-quiz-backend.onrender.com`).
1. Update your Flutter `AIService` or API constants to point to this new URL instead of `localhost`.

## 5. Verification
- Open your Render URL in a browser. You should see a blank page or a 404 (since there's no root `/` route defined, but it proves the server is up).
- Monitor logs in the Render dashboard to ensure Redis and other services initialize correctly.
