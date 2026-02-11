# Import Flask for API routing and JSON utilities
from flask import Flask, request, jsonify
# Import our custom RAG logic service
from rag_service import RAGService
import os

# Initialize the Flask application
app = Flask(__name__)

# Initialize RAG Service global instance
# This service handles all vector DB interactions and LLM calls
rag_service = None

@app.route('/add_context', methods=['POST'])
def add_context():
    """Endpoint to manually add text context to the knowledge base."""
    global rag_service
    if not rag_service:
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
    global rag_service
    if not rag_service:
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
            success = rag_service.add_document_file(file_path, file.filename)
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
def generate_quiz():
    """Main endpoint to generate a quiz based on various input parameters."""
    global rag_service
    if not rag_service:
        return jsonify({"error": "RAG Service not initialized. Check API Key."}), 500

    # Parse JSON data from the request body
    data = request.json
    topic = data.get('topic')
    num_questions = data.get('num_questions', 5)
    difficulty = data.get('difficulty', 'Medium')
    
    input_type = data.get('input_type', 'topic') # topic, text, link, or document
    language = data.get('language', 'English')
    
    # Target Configuration parameters (Specific to Indian Exam use case)
    exam_sector = data.get('exam_sector')
    exam_name = data.get('exam_name')
    subject = data.get('subject')
    
    # Validation: A topic or content source is mandatory
    if not topic:
        return jsonify({"error": "No topic or content provided"}), 400
        
    try:
        # Step 1: Call the RAG service to generate the quiz JSON
        quiz_json = rag_service.generate_quiz(
            topic, 
            num_questions=num_questions, 
            difficulty=difficulty, 
            input_type=input_type,
            language=language,
            exam_sector=exam_sector,
            exam_name=exam_name,
            subject=subject
        )
        # Step 2: Return the raw JSON string with correct Content-Type header
        return quiz_json, 200, {'Content-Type': 'application/json'}
    except Exception as e:
        import traceback
        traceback.print_exc() # Useful for debugging in the backend console
        return jsonify({"error": str(e)}), 500

# Application Entry Point
if __name__ == '__main__':
    try:
        # Attempt to bootstrap the RAG service (connects to Pinecone/OpenAI)
        rag_service = RAGService()
        print("RAG Service Initialized Successfully")
    except Exception as e:
        print(f"Failed to initialize RAG Service: {e}")
        
    # Start the Flask development server on port 5001
    app.run(host='0.0.0.0', port=5001, debug=True)
