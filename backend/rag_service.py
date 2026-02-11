import os
# OpenAI integration for embeddings and chat models
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
# Pinecone vector database for storing and querying document embeddings
from pinecone import Pinecone, ServerlessSpec
# Document loaders for processing different file types
from langchain_community.document_loaders import PyPDFLoader, TextLoader
# Utility to split long documents into smaller, manageable chunks
from langchain_text_splitters import RecursiveCharacterTextSplitter
# Core data structures for LangChain
from langchain_core.documents import Document
from langchain_core.prompts import PromptTemplate
import json
import re
import requests
import tempfile
# BeautifulSoup for web scraping and HTML parsing
from bs4 import BeautifulSoup

# Load environment variables from .env file
from dotenv import load_dotenv
import os
current_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(current_dir, '.env')
load_dotenv(dotenv_path=env_path)

# Retrieve configuration from environment variables
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = "quiz-generator"

# Warn if critical keys are missing
if not OPENAI_API_KEY:
    print("WARNING: OPENAI_API_KEY not found in environment!")

class RAGService:
    """
    RAGService handles the Retrieval-Augmented Generation pipeline.
    It manages document indexing in Pinecone and quiz generation using OpenAI.
    """
    def __init__(self):
        # Initialize OpenAI Embeddings model for converting text to vectors
        self.embeddings = OpenAIEmbeddings(
            model="text-embedding-3-small",
            openai_api_key=OPENAI_API_KEY
        )
        
        # Connect to the Pinecone Vector Database
        self.pc = Pinecone(api_key=PINECONE_API_KEY)
        
        # Automatically create the index if it doesn't exist
        if PINECONE_INDEX_NAME not in [i.name for i in self.pc.list_indexes()]:
            print(f"Index {PINECONE_INDEX_NAME} not found. Creating...")
            from pinecone import ServerlessSpec
            self.pc.create_index(
                name=PINECONE_INDEX_NAME,
                dimension=1536, # Dimension for OpenAI text-embedding-3-small
                metric='cosine',
                spec=ServerlessSpec(
                    cloud='aws',
                    region='us-east-1'
                )
            )
            print(f"Index {PINECONE_INDEX_NAME} created successfully.")

        # Reference the specific index for operations
        self.index = self.pc.Index(PINECONE_INDEX_NAME)
        
        # Initialize the Grand Language Model (GPT-4o-mini) for content generation
        self.llm = ChatOpenAI(
            model="gpt-4o-mini", 
            temperature=0.7, # Balanced randomness for unique quizes
            openai_api_key=OPENAI_API_KEY
        )
        
        # Configure the text splitter for document indexing
        self.text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)

    def add_text_to_knowledge_base(self, text: str, metadata: dict = None):
        """Adds raw text strings to the Pinecone vector database."""
        try:
            # Step 1: Break text into smaller overlapping chunks
            chunks = self.text_splitter.split_text(text)
            
            # Step 2: Convert each chunk into an embedding vector
            vectors = []
            for i, chunk in enumerate(chunks):
                embedding = self.embeddings.embed_query(chunk)
                vector_id = f"text_{hash(chunk)}_{i}"
                vectors.append({
                    "id": vector_id,
                    "values": embedding,
                    "metadata": {**(metadata or {}), "text": chunk}
                })
            
            # Step 3: Upload the vectors to Pinecone
            self.index.upsert(vectors=vectors)
            print(f"Added context: {text[:50]}... ({len(vectors)} chunks) to Pinecone")
            return True
        except Exception as e:
            print(f"Error adding text to Pinecone: {e}")
            return False

    def add_document_file(self, file_path: str, filename: str):
        """Processes a PDF or Text file and indexes its content in Pinecone."""
        print(f"Processing document: {filename}")
        try:
            # Choose the appropriate loader based on file extension
            if filename.lower().endswith('.pdf'):
                loader = PyPDFLoader(file_path)
            else:
                loader = TextLoader(file_path)
            
            # Load the raw document data
            documents = loader.load()
            
            # Split the document into semantic chunks
            split_docs = self.text_splitter.split_documents(documents)
            
            # Prepare vectors with preservation of important metadata
            vectors = []
            for i, doc in enumerate(split_docs):
                embedding = self.embeddings.embed_query(doc.page_content)
                vector_id = f"doc_{filename}_{i}"
                vectors.append({
                    "id": vector_id,
                    "values": embedding,
                    "metadata": {
                        **doc.metadata, # Preserve original document metadata
                        "source": filename, # Critical for document filtering
                        "text": doc.page_content # The actual content for the LLM
                    }
                })
            
            # Bulk upload to Pinecone
            self.index.upsert(vectors=vectors)
            print(f"Successfully added {filename}: {len(vectors)} chunks to Pinecone.")
            return True
        except Exception as e:
            print(f"Error processing document: {e}")
            return False

    def generate_quiz(self, topic: str, num_questions: int = 5, difficulty: str = "Medium", 
                      input_type: str = "topic", language: str = "English", 
                      exam_sector: str = None, exam_name: str = None, subject: str = None):
        """Core method to compile context and generate a high-quality quiz via OpenAI."""
        print(f"Generating quiz: Sector={exam_sector}, Exam={exam_name}, Subject={subject}, Language={language}, Difficulty={difficulty}")
        
        context_text = ""
        
        # --- PHASE 1: CONTEXT RETRIEVAL ---
        
        # Handle scraping for external links
        if input_type == "link":
            print(f"Scraping URL: {topic}")
            context_text = self._scrape_url(topic)
            if not context_text:
                context_text = "Failed to scrape content from the link. Fallback to general knowledge."
        
        # Use user-provided text directly
        elif input_type == "text":
            print("Using provided text directly as context.")
            context_text = topic
            topic = topic[:100] + "..." if len(topic) > 100 else topic
            
        # Retrieval from a specifically uploaded document
        elif input_type == "document":
            print(f"Retrieving specific context from document: {topic}")
            try:
                # Target retrieval by filtering Pinecone metadata for the specific filename
                query_embedding = self.embeddings.embed_query("Generate comprehensive quiz content and main concepts")
                results = self.index.query(
                    vector=query_embedding,
                    top_k=15, # High k to capture enough specific document info
                    filter={"source": topic},
                    include_metadata=True
                )
                
                context_chunks = [match['metadata']['text'] for match in results['matches'] if 'text' in match['metadata']]
                context_text = "\n\n".join(context_chunks)
                print(f"Retrieved {len(context_chunks)} context chunks from {topic}")
                
                if not context_chunks:
                    print(f"WARNING: No content found in Pinecone for source: {topic}.")
                    
            except Exception as e:
                print(f"Error querying document context from Pinecone: {e}")
                context_text = ""
                
        # General knowledge retrieval for a simple topic
        else:
            try:
                # Semantic search across all indexed data for the topic keyword
                query_embedding = self.embeddings.embed_query(topic)
                results = self.index.query(
                    vector=query_embedding,
                    top_k=5,
                    include_metadata=True
                )
                
                context_chunks = [match['metadata']['text'] for match in results['matches'] if 'text' in match['metadata']]
                context_text = "\n\n".join(context_chunks)
            except Exception as e:
                print(f"Note: Pinecone search failed: {e}")
                context_text = ""

        # Default fallback if no context is found
        if not context_text:
            context_text = "No specific context found. Use your general knowledge."

        # --- PHASE 2: PROMPT CONSTRUCT AND GENERATION ---

        # Formatting detailed target info for the LLM
        target_info = f"Target Exam: {exam_name} ({exam_sector})" if exam_name else f"Target Sector: {exam_sector}"
        subject_info = f"Subject: {subject}" if subject else ""
        
        # High-fidelity prompt designed for strictly formatted JSON output
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
        # Create a dynamic seed to prevent repetitive LLM responses
        random_key = str(time.time())
        
        # Inject variety into the LLM's thought process
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

        # Build the chain and invoke the generation with dynamic variables
        prompt = PromptTemplate.from_template(prompt_template)
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
        
        # --- PHASE 3: JSON EXTRACTION & CLEANUP ---
        try:
            # Extract JSON array from potentially messy LLM response
            json_search = re.search(r'\[.*\]', response, re.DOTALL)
            if json_search:
                cleaned_response = json_search.group(0)
            else:
                cleaned_response = response.strip()
            
            # Validate JSON structure
            json.loads(cleaned_response)
            return cleaned_response
        except Exception as e:
            print(f"JSON parsing error: {e}")
            cleaned = response.strip()
            # Clean possible markdown code block wrappers
            if cleaned.startswith("```json"): cleaned = cleaned[7:-3]
            elif cleaned.startswith("```"): cleaned = cleaned[3:-3]
            return cleaned.strip()

    def _scrape_url(self, url: str) -> str:
        """Helper to extract clean readable text from any web URL."""
        try:
            # Emulate an actual browser request to avoid basic bot detection
            headers = {'User-Agent': 'Mozilla/5.0'}
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            # Parse HTML content
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Scrub non-content tags like scripts and styles
            for script in soup(["script", "style"]):
                script.decompose()
                
            # Process and clean the text content
            text = soup.get_text()
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            clean_text = '\n'.join(chunk for chunk in chunks if chunk)
            
            # Return a reasonable amount of context to fit LLM limits
            return clean_text[:10000]
        except Exception as e:
            print(f"Scraping error: {e}")
            return ""
