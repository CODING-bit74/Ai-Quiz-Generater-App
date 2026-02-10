import os
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from pinecone import Pinecone, ServerlessSpec
from langchain_community.document_loaders import PyPDFLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from langchain_core.prompts import PromptTemplate
import json
import re
import requests
import tempfile
from bs4 import BeautifulSoup

# Load environment variables
from dotenv import load_dotenv
import os
current_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(current_dir, '.env')
load_dotenv(dotenv_path=env_path)

# Configure API Keys
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = "quiz-generator"

if not OPENAI_API_KEY:
    print("WARNING: OPENAI_API_KEY not found in environment!")

class RAGService:
    def __init__(self):
        # Use OpenAI Embeddings
        self.embeddings = OpenAIEmbeddings(
            model="text-embedding-3-small",
            openai_api_key=OPENAI_API_KEY
        )
        
        # Initialize Pinecone Client
        self.pc = Pinecone(api_key=PINECONE_API_KEY)
        
        # Check if index exists, if not create it
        if PINECONE_INDEX_NAME not in [i.name for i in self.pc.list_indexes()]:
            print(f"Index {PINECONE_INDEX_NAME} not found. Creating...")
            from pinecone import ServerlessSpec
            self.pc.create_index(
                name=PINECONE_INDEX_NAME,
                dimension=1536, # OpenAI text-embedding-3-small
                metric='cosine',
                spec=ServerlessSpec(
                    cloud='aws',
                    region='us-east-1'
                )
            )
            print(f"Index {PINECONE_INDEX_NAME} created successfully.")

        self.index = self.pc.Index(PINECONE_INDEX_NAME)
        
        # Use GPT-4o-mini
        self.llm = ChatOpenAI(
            model="gpt-4o-mini", 
            temperature=0.7,
            openai_api_key=OPENAI_API_KEY
        )
        self.text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)

    def add_text_to_knowledge_base(self, text: str, metadata: dict = None):
        """Adds raw text to the Pinecone vector database."""
        try:
            # Split text into chunks
            chunks = self.text_splitter.split_text(text)
            
            # Embed chunks
            vectors = []
            for i, chunk in enumerate(chunks):
                embedding = self.embeddings.embed_query(chunk)
                vector_id = f"text_{hash(chunk)}_{i}"
                vectors.append({
                    "id": vector_id,
                    "values": embedding,
                    "metadata": {**(metadata or {}), "text": chunk}
                })
            
            # Upsert in batches of 100
            self.index.upsert(vectors=vectors)
            print(f"Added context: {text[:50]}... ({len(vectors)} chunks) to Pinecone")
            return True
        except Exception as e:
            print(f"Error adding text to Pinecone: {e}")
            return False

    def add_document_file(self, file_path: str, filename: str):
        """Parses a file (PDF/Text) and adds it to the vector store."""
        print(f"Processing document: {filename}")
        try:
            if filename.lower().endswith('.pdf'):
                loader = PyPDFLoader(file_path)
            else:
                loader = TextLoader(file_path)
            
            documents = loader.load()
            # Split into chunks
            split_docs = self.text_splitter.split_documents(documents)
            
            vectors = []
            for i, doc in enumerate(split_docs):
                embedding = self.embeddings.embed_query(doc.page_content)
                vector_id = f"doc_{filename}_{i}"
                vectors.append({
                    "id": vector_id,
                    "values": embedding,
                    "metadata": {
                        "source": filename,
                        "text": doc.page_content,
                        **doc.metadata
                    }
                })
            
            # Upsert in batches
            self.index.upsert(vectors=vectors)
            print(f"Successfully added {filename}: {len(vectors)} chunks to Pinecone.")
            return True
        except Exception as e:
            print(f"Error processing document: {e}")
            return False

    def generate_quiz(self, topic: str, num_questions: int = 5, difficulty: str = "Medium", input_type: str = "topic", language: str = "English", exam_sector: str = None, exam_name: str = None, subject: str = None):
        """Generates a quiz based on the topic, relevant context, and specific language/exam/subject requirements."""
        print(f"Generating quiz: Sector={exam_sector}, Exam={exam_name}, Subject={subject}, Language={language}, Difficulty={difficulty}")
        
        context_text = ""
        
        # 1. Handle different input types
        if input_type == "link":
            print(f"Scraping URL: {topic}")
            context_text = self._scrape_url(topic)
            if not context_text:
                context_text = "Failed to scrape content from the link. Fallback to general knowledge."
        
        elif input_type == "text":
            print("Using provided text directly as context.")
            context_text = topic
            topic = topic[:100] + "..." if len(topic) > 100 else topic
            
        else: # Default: topic
            try:
                # Manual search in Pinecone
                query_embedding = self.embeddings.embed_query(topic)
                results = self.index.query(
                    vector=query_embedding,
                    top_k=3,
                    include_metadata=True
                )
                
                context_chunks = []
                for match in results['matches']:
                    if 'text' in match['metadata']:
                        context_chunks.append(match['metadata']['text'])
                
                context_text = "\n\n".join(context_chunks)
            except Exception as e:
                print(f"Note: Pinecone search failed: {e}")
                context_text = ""

        if not context_text:
            context_text = "No specific context found. Use your general knowledge."

        # 2. Build the high-fidelity prompt
        # Construct the target context string
        target_info = f"Target Exam: {exam_name} ({exam_sector})" if exam_name else f"Target Sector: {exam_sector}"
        subject_info = f"Subject: {subject}" if subject else ""
        
        prompt_template = """
You are an expert quiz generator specializing in Indian Government Examinations.
Task: Generate {num_questions} unique and fresh {difficulty} level multiple-choice questions.
Target: {target_info}
{subject_info}
Topic Area: "{topic}"

Randomization Seed: {random_key}
Generation Perspective: {perspective}
Requirement: Ensure the questions are completely different from common sets. AVoid repeating questions from previous sessions.

Context for Questions:
{context}

Requirements:
1. Factually accurate and strictly relevant to the {subject_name}.
2. Adhere to the question pattern, standard, and difficulty level of {exam_context} examinations.
3. Every question must have exactly 4 options.
4. Provide a clear, concise explanation.
5. Generate ALL output (questions, options, answer, and explanation) strictly in {language} language.

Output Format (STRICT JSON list of objects):
[
    {{
        "question": "Question text in {language}",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "answer": "Correct Option Text",
        "explanation": "Brief explanation in {language}"
    }}
]

Return ONLY the JSON. No conversational text.
"""
        import time
        import random
        random_key = str(time.time())
        
        # Inject random perspective to force variety
        perspectives = [
            "Focus on real-world application and case studies.",
            "Emphasize conceptual understanding and definitions.",
            "Target numerical ability and data interpretation.",
            "Focus on chronological events and verified facts.",
            "Challenge the user with statement-based questions (True/False/None).",
            "PRIORITY: Ask questions that are rarely found in standard textbooks.",
            "Focus on recent trends and current developments in this topic.",
            "Mix simple direct questions with complex reasoning-based ones."
        ]
        selected_perspective = random.choice(perspectives)

        prompt = PromptTemplate.from_template(prompt_template)
        
        # INCREASE TEMPERATURE FOR RANDOMNESS
        # We override the default 0.7 to 0.9 for this specific call if possible, 
        # or we can re-instantiate LLM. 
        # Since we use self.llm (already init), we will rely on the prompt engineering.
        
        chain = prompt | self.llm
        
        response_msg = chain.invoke({
            "context": context_text,
            "topic": topic,
            "num_questions": num_questions,
            "difficulty": difficulty,
            "language": language,
            "target_info": target_info,
            "subject_info": subject_info,
            "subject_name": subject if subject else topic,
            "exam_context": exam_name if exam_name else exam_sector,
            "random_key": f"{random_key}-{selected_perspective}", # Combine for stronger seed effect
            "perspective": selected_perspective
        })
        
        response = response_msg.content
        print(f"Raw LLM Response: {response}")
        
        # Robust JSON extraction
        try:
            json_search = re.search(r'\[.*\]', response, re.DOTALL)
            if json_search:
                cleaned_response = json_search.group(0)
            else:
                cleaned_response = response.strip()
            
            json.loads(cleaned_response)
            return cleaned_response
        except Exception as e:
            print(f"JSON parsing error: {e}")
            cleaned = response.strip()
            if cleaned.startswith("```json"): cleaned = cleaned[7:-3]
            elif cleaned.startswith("```"): cleaned = cleaned[3:-3]
            return cleaned.strip()

    def _scrape_url(self, url: str) -> str:
        """Helper to extract text from a URL."""
        try:
            headers = {'User-Agent': 'Mozilla/5.0'}
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Remove script and style elements
            for script in soup(["script", "style"]):
                script.decompose()
                
            # Get text
            text = soup.get_text()
            
            # Basic cleanup: break into lines and remove leading/trailing whitespace
            lines = (line.strip() for line in text.splitlines())
            # break multi-headlines into a line each
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            # drop blank lines
            text = '\n'.join(chunk for chunk in chunks if chunk)
            
            return text[:10000] # Limit context size for LLM
        except Exception as e:
            print(f"Scraping error: {e}")
            return ""
