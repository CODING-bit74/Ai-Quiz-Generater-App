from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Knowledge base and generation logic
from rag_service import RAGService, TranscriptNotFoundError
from agentic_service import QuizAgent  # Import the new Agent

import os
import hashlib
import json
import redis
from functools import wraps
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

# --- REDIS CONFIGURATION ---
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
try:
    redis_client = redis.StrictRedis.from_url(REDIS_URL, decode_responses=True)
    # Test connection
    redis_client.ping()
    print("✅ Successfully connected to Redis!")
except Exception as e:
    print(f"⚠️ Warning: Redis connection failed. Caching will be disabled. Error: {e}")
    redis_client = None

# --- CONFIGURATION & MIDDLEWARE ---
@app.errorhandler(Exception)
def handle_exception(e):
    import traceback
    # Return JSON error even in case of system-level crashes
    return jsonify({
        "error": "Internal Server Error",
        "message": str(e),
        "traceback": traceback.format_exc()
    }), 500

# --- GLOBAL INSTANCES ---
rag_service = None
quiz_agent = None

# --- SUPABASE AUTHENTICATION ---
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_KEY")
try:
    if url and key:
        supabase: Client = create_client(url, key)
        print("✅ Supabase client initialized")
    else:
        print("⚠️ Warning: SUPABASE_URL or SUPABASE_KEY missing")
        supabase = None
except Exception as e:
    print(f"⚠️ Warning: Supabase client failed to initialize: {e}")
    supabase = None

# --- LAZY INITIALIZATION HELPERS ---
def get_rag_service():
    global rag_service
    if rag_service is None:
        try:
            print("Initializing RAG Service (Lazy)...")
            rag_service = RAGService()
            print("✅ RAG Service Initialized")
        except Exception as e:
            print(f"❌ Failed to initialize RAG Service: {e}")
    return rag_service

def get_quiz_agent():
    global quiz_agent
    if quiz_agent is None:
        try:
            print("Initializing Quiz Agent (Lazy)...")
            rs = get_rag_service()
            quiz_agent = QuizAgent(rag_service=rs)
            print("✅ Quiz Agent Initialized")
        except Exception as e:
            print(f"❌ Failed to initialize Quiz Agent: {e}")
    return quiz_agent

@app.route('/')
def home():
    """Root route to verify server is running."""
    return jsonify({
        "message": "AI Quiz Generator API is running!",
        "version": "1.0.0",
        "documentation": "https://github.com/CODING-bit74/Ai-Quiz-Generater-App"
    }), 200

@app.route('/health')
def health_check():
    """Simple health check for Render to detect the app is live."""
    return jsonify({
        "status": "healthy",
        "redis": "connected" if redis_client else "disconnected",
        "supabase": "connected" if supabase else "disconnected"
    }), 200

def verify_token(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"error": "Missing Authorization Header"}), 401
        
        try:
            # Expecting 'Bearer <token>'
            token = auth_header.split(" ")[1]
            if supabase:
                user = supabase.auth.get_user(token)
                if not user:
                     return jsonify({"error": "Invalid Token"}), 401
        except Exception as e:
            return jsonify({"error": f"Authentication Failed: {str(e)}"}), 401
            
        return f(*args, **kwargs)
    return decorated_function

@app.route('/add_context', methods=['POST'])
def add_context():
    """Endpoint to manually add text context to the knowledge base."""
    rs = get_rag_service()
    if not rs:
        return jsonify({"error": "RAG Service not initialized. Check API Key."}), 500
        
    # Extract the JSON payload
    data = request.json
    text = data.get('text')
    
    if not text:
        return jsonify({"error": "No text provided"}), 400
        
    # Trigger the indexing process
    rag_service.add_text_to_knowledge_base(text)
    return jsonify({"message": "Context added successfully"}), 200

@app.route('/upload_document', methods=['POST'])
def upload_document():
    """Endpoint to upload and index PDF or Text documents."""
    rs = get_rag_service()
    if not rs:
        return jsonify({"error": "RAG Service not initialized. Check API Key."}), 500
        
    # Check if a file was actually sent in the request
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
        
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
        
    if file:
        import tempfile
        import os
        
        # Step 1: Securely save the uploaded file to a temporary directory
        temp_dir = tempfile.gettempdir()
        file_path = os.path.join(temp_dir, file.filename)
        file.save(file_path)
        
        try:
            # Step 2: Delegate processing to the RAG service
            success = rs.add_document_file(file_path, file.filename)
            # Step 3: Delete the local temp file after indexing is complete
            os.remove(file_path)
            
            if success:
                return jsonify({"message": f"Successfully uploaded {file.filename} to knowledge base!"}), 200
            else:
                return jsonify({"error": "Failed to process document"}), 500
        except Exception as e:
            # Cleanup temp file even if an error occurs
            if os.path.exists(file_path):
                os.remove(file_path)
            return jsonify({"error": str(e)}), 500

@app.route('/generate_quiz', methods=['POST'])
@verify_token
def generate_quiz():
    """Main endpoint to generate a quiz using the Agentic Workflow."""
    qa = get_quiz_agent()
    if not qa:
        return jsonify({"error": "Quiz Agent not initialized. Check API Key."}), 500

    # Parse JSON data from the request body
    data = request.json
    topic = data.get('topic')
    num_questions = data.get('num_questions', 5)
    difficulty = data.get('difficulty', 'Medium')
    
    input_type = data.get('input_type', 'topic') # topic, text, link, or document
    language = data.get('language', 'English')
    
    # Target Configuration parameters
    exam_sector = data.get('exam_sector')
    exam_name = data.get('exam_name')
    subject = data.get('subject')
    
    # Validation
    if not topic:
        return jsonify({"error": "No topic or content provided"}), 400
        
    # --- REDIS CACHING LOGIC ---
    cache_key = None
    if redis_client:
        # Create a unique, deterministic hash for this specific quiz request
        # We sort dict keys to ensure consistent hashing
        cache_data = {
            "topic": topic, "num": num_questions, "diff": difficulty, 
            "type": input_type, "lang": language, "sector": exam_sector, 
            "exam": exam_name, "subj": subject
        }
        cache_str = json.dumps(cache_data, sort_keys=True)
        cache_key = f"quiz:{hashlib.sha256(cache_str.encode()).hexdigest()}"
        
        try:
            cached_quiz = redis_client.get(cache_key)
            if cached_quiz:
                print(f"⚡ CACHE HIT! Returning cached quiz for topic '{topic}'")
                return cached_quiz, 200, {'Content-Type': 'application/json'}
        except Exception as e:
            print(f"⚠️ Redis read error: {e}")

    try:
        # Call the Agentic Service
        quiz_json = qa.generate_quiz_agentic(
            topic, 
            num_questions=num_questions, 
            difficulty=difficulty, 
            input_type=input_type,
            language=language,
            exam_sector=exam_sector,
            exam_name=exam_name,
            subject=subject
        )
        
        # --- SAVE TO REDIS CACHE ---
        if redis_client and cache_key and ("error" not in quiz_json):
            try:
                # Cache successful quizzes for 24 hours (86400 seconds)
                redis_client.setex(cache_key, 86400, quiz_json)
                print(f"💾 Saved generated quiz to cache (TTL: 24h)")
            except Exception as e:
                 print(f"⚠️ Redis write error: {e}")

        return quiz_json, 200, {'Content-Type': 'application/json'}
    except TranscriptNotFoundError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# Application Entry Point
if __name__ == '__main__':
    # Start the Flask development server (Local only)
    app.run(host='0.0.0.0', port=5001, debug=True)
