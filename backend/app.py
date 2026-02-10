from flask import Flask, request, jsonify
from rag_service import RAGService
import os

app = Flask(__name__)

# Initialize RAG Service
# Note: This might fail if API Key is not set, handled in main block
rag_service = None

@app.route('/add_context', methods=['POST'])
def add_context():
    global rag_service
    if not rag_service:
        return jsonify({"error": "RAG Service not initialized. Check API Key."}), 500
        
    data = request.json
    text = data.get('text')
    
    if not text:
        return jsonify({"error": "No text provided"}), 400
        
    rag_service.add_text_to_knowledge_base(text)
@app.route('/upload_document', methods=['POST'])
def upload_document():
    global rag_service
    if not rag_service:
        return jsonify({"error": "RAG Service not initialized. Check API Key."}), 500
        
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
        
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
        
    if file:
        import tempfile
        import os
        
        # Save to temp file
        temp_dir = tempfile.gettempdir()
        file_path = os.path.join(temp_dir, file.filename)
        file.save(file_path)
        
        try:
            success = rag_service.add_document_file(file_path, file.filename)
            os.remove(file_path) # Cleanup
            
            if success:
                return jsonify({"message": f"Successfully uploaded {file.filename} to knowledge base!"}), 200
            else:
                return jsonify({"error": "Failed to process document"}), 500
        except Exception as e:
            if os.path.exists(file_path):
                os.remove(file_path)
            return jsonify({"error": str(e)}), 500

@app.route('/generate_quiz', methods=['POST'])
def generate_quiz():
    global rag_service
    if not rag_service:
        return jsonify({"error": "RAG Service not initialized. Check API Key."}), 500

    data = request.json
    topic = data.get('topic')
    num_questions = data.get('num_questions', 5)
    difficulty = data.get('difficulty', 'Medium')
    
    input_type = data.get('input_type', 'topic')
    language = data.get('language', 'English')
    
    # New parameters for Sector and Subject
    exam_sector = data.get('exam_sector')
    exam_name = data.get('exam_name')
    subject = data.get('subject')
    
    if not topic:
        return jsonify({"error": "No topic or content provided"}), 400
        
    try:
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
        return quiz_json, 200, {'Content-Type': 'application/json'}
    except Exception as e:
        import traceback
        traceback.print_exc() # Show full error in terminal
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    try:
        rag_service = RAGService()
        print("RAG Service Initialized Successfully")
    except Exception as e:
        print(f"Failed to initialize RAG Service: {e}")
        
    app.run(host='0.0.0.0', port=5001, debug=True)
