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
from youtube_transcript_api import YouTubeTranscriptApi

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
 
class TranscriptNotFoundError(Exception):
    """Custom exception raised when a YouTube transcript cannot be retrieved."""
    pass
 
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

    def _upsert_batches(self, vectors: list, batch_size: int = 50):
        """Helper to upload vectors in batches to avoid Pinecone's request size limit (2MB)."""
        if not vectors:
            return
        total_batches = (len(vectors) - 1) // batch_size + 1
        for i in range(0, len(vectors), batch_size):
            batch = vectors[i:i + batch_size]
            print(f"Upserting batch {i//batch_size + 1}/{total_batches} ({len(batch)} vectors)...")
            self.index.upsert(vectors=batch)

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
            
            # Step 3: Upload the vectors to Pinecone using batching
            self._upsert_batches(vectors)
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
            
            # Bulk upload to Pinecone using batching
            self._upsert_batches(vectors)
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
        # Reset metadata for each generation session
        self._last_detected_subject = None
        self._last_detected_topic = None
        
        # --- PHASE 1: CONTEXT RETRIEVAL ---
        
        # Handle scraping for external links
        if input_type == "link":
            if "youtube.com" in topic or "youtu.be" in topic:
                print(f"Detected YouTube URL: {topic}")
                raw_scraped = self._fetch_youtube_transcript(topic)
                if not raw_scraped:
                    # STRICT MODE: If user wants a video quiz, we MUST have the video content.
                    # Fallback to general knowledge would be misleading.
                    context_text = "ERROR: Could not fetch transcript. Please ensure the video has closed captions (CC) enabled."
                    # We will handle this error string in the response or let the prompt handle it, 
                    # but better to raise an exception to stop generation if we want to be strict.
                    # For now, let's set a specific error flag in the text that the prompt might catch, 
                    # OR just raise an actual value error to return 500/400.
                    raise TranscriptNotFoundError("Could not fetch transcript from YouTube video. Please check if the video has captions.")
                else:
                    print("Refining YouTube transcript for factual precision...")
                    context_text = self._refine_context(raw_scraped, "YouTube Video Transcript")
            else:
                print(f"Scraping URL: {topic}")
                raw_scraped = self._scrape_url(topic)
                if not raw_scraped:
                    context_text = "Failed to scrape content. Fallback to general knowledge."
                else:
                    # STAGE 1: Refinement (Study the content first)
                    print("Refining scraped content for factual precision...")
                    context_text = self._refine_context(raw_scraped, topic)
        
        # Use user-provided text directly
        elif input_type == "text":
            print("Refining user text for factual precision & metadata...")
            context_text = self._refine_context(topic, "User Provided Text")
            topic = topic[:100] + "..." if len(topic) > 100 else topic
            
        # Retrieval from a specifically uploaded document
        elif input_type == "document":
            print(f"Retrieving specific context from document: {topic}")
            raw_context = self._retrieve_context(topic, "Generate comprehensive quiz content and main concepts")
            if raw_context:
                print("Refining document context for factual precision & metadata...")
                context_text = self._refine_context(raw_context, topic)
            else:
                context_text = "No specific context found in document. Use general knowledge."
                
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

        # OVERRIDE: If we detected a specific subject from the content (YouTube/Doc/Link), use it!
        # This prevents the frontend default "Quant" from forcing math questions on a History video.
        if self._last_detected_subject and input_type in ["link", "document", "text"]:
            print(f"Overriding provided subject '{subject}' with detected subject '{self._last_detected_subject}'")
            subject = self._last_detected_subject
            # Also update topic to the detected concise topic if available
            if self._last_detected_topic:
                topic = self._last_detected_topic

        # Formatting detailed target info for the LLM
        target_info = f"Target Exam: {exam_name} ({exam_sector})" if exam_name else f"Target Sector: {exam_sector}"
        
        # --- PHASE 2: EXAM-SPECIFIC DIFFICULTY PERSONAS ---
        difficulty_mapping = {
            "Easy": "Persona: SSC/Railway Junior Level. Focus on direct factual recall. Single-sentence questions. Direct answers. Memory-based.",
            "Medium": "Persona: Banking/Central Govt Group B. Focus on analytical patterns, logical comparisons, and slightly deeper factual nuance.",
            "Hard": "Persona: UPSC/State PSC/NET. Focus on multi-statement reasoning, 'Assertion-Reasoning', and 'Which of the following are correct' style questions. High complexity."
        }
        selected_persona = difficulty_mapping.get(difficulty, difficulty_mapping["Medium"])

        # High-fidelity prompt designed for strictly formatted JSON output
        prompt_template = """
You are the **Ultimate AI Quiz Professor** for Indian Government Competitive Exams.
Your goal is to help students CRACK their exams by providing highly accurate, challenging, and educational content.

TASK: Generate {num_questions} "{difficulty}" level MCQs.
EXAM TARGET: {target_info}
SUBJECT: {subject_name}
TOPIC: "{topic}"

STUDENT PERSONA: {persona}

CORE MATERIAL (The "Truth" for this quiz):
{context}

STRICT QUALITY REQUIREMENTS:
1. FACTUAL SUPREMACY: Questions must be derived from the Core Material. No hallucinations.
2. SMART DISTRACTORS: Options should be tricky but logically distinct. No 'All of the above' unless absolutely necessary.
3. EDUCATIONAL EXPLANATIONS:
   - Start with WHY the answer is correct.
   - Mention a 'Pro-Tip' or 'Memory Trick' to help the student remember this.
   - For Hard questions, explain the subtle nuances that make the distractors incorrect.
4. EXAM NUANCE: If difficulty is 'Hard', use UPSC-style Statement reasoning (I, II, III).
5. NO REPETITION: Ensure unique questions.

Language: {language}

Output STrictly as a JSON array:
[
    {{
        "question": "Clear, specific, and exam-relevant question",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "answer": "Exact correct option text",
        "explanation": "Detailed breakdown + Pro-Tip for students."
    }}
]

Return ONLY the JSON. No markdown wrappers.
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
            "subject_name": subject if subject else topic,
            "persona": selected_persona
        })
        
        response = response_msg.content
        print(f"Raw LLM Response: {response}")
        
        # --- PHASE 3: JSON EXTRACTION & CLEANUP ---
        try:
            # Extract JSON array from potentially messy LLM response
            json_search = re.search(r'\[.*\]', response, re.DOTALL)
            if json_search:
                cleaned_questions = json.loads(json_search.group(0))
            else:
                cleaned_questions = json.loads(response.strip())
            
            # Return questions along with detected metadata
            return json.dumps({
                "questions": cleaned_questions,
                "detected_subject": getattr(self, '_last_detected_subject', None),
                "detected_topic": getattr(self, '_last_detected_topic', None)
            })
        except Exception as e:
            print(f"JSON parsing error in generation: {e}")
            return json.dumps({
                "questions": [],
                "error": str(e)
            })

    def _refine_context(self, raw_text: str, source: str) -> str:
        """STAGE 1: Uses the LLM to study the raw text and extract core factual context + metadata."""
        refinement_prompt = """
You are an expert Educator. Study the provided raw content from "{source}".
Perform three tasks:
1. Extract a clean, bulleted Factual Summary of core data points, dates, and definitions relevant for Indian Exams.
2. Categorize this content into exactly one of these SUBJECTS:
   - 'Quant': Mathematics, Arithmetic, Algebra, Geometry, Data Interpretation.
   - 'Reasoning': Logic, Puzzles, Coding-Decoding, Syllogisms.
   - 'English': Grammar, Comprehension, Vocabulary, Vocabulary, Sentence Correction.
   - 'GA/GS': History, Geography, Polity, Science, Current Affairs, Static GK, Economics.
3. Generate a concise, human-readable TOPIC TITLE (e.g., "The Mughal Empire", "Ratio & Proportion Concepts").

Raw Content:
{content}

Output format (STRICT JSON):
{{
  "summary": "The factual summary text...",
  "subject": "Exactly one of the 4 allowed subjects",
  "topic": "The concise topic title"
}}

Return ONLY the JSON. No conversational text.
"""
        import re
        try:
            prompt = PromptTemplate.from_template(refinement_prompt)
            chain = prompt | self.llm
            response_msg = chain.invoke({"content": raw_text[:8000], "source": source})
            response = response_msg.content
            
            # Use regex to find JSON block in case LLM wraps it in markdown ```json ... ```
            json_search = re.search(r'\{.*\}', response, re.DOTALL)
            if json_search:
                data = json.loads(json_search.group(0))
            else:
                data = json.loads(response.strip())
            
            # Map detected subject to the strict allowed set
            subject = data.get('subject', 'GA/GS')
            # Normalize common subject variations
            subject_map = {
                'Math': 'Quant', 'Mathematics': 'Quant', 'Arithmetic': 'Quant',
                'Logical': 'Reasoning', 'Logical Reasoning': 'Reasoning',
                'General Awareness': 'GA/GS', 'General Studies': 'GA/GS', 'GK': 'GA/GS', 'History': 'GA/GS',
                'English Language': 'English'
            }
            final_subject = subject_map.get(subject, subject)
            if final_subject not in ['Quant', 'Reasoning', 'English', 'GA/GS']:
                final_subject = "GA/GS"
            
            self._last_detected_subject = final_subject
            self._last_detected_topic = data.get('topic', 'Manual Content')
            
            return data.get('summary', raw_text[:4000])
        except Exception as e:
            print(f"Refinement error: {e}")
            self._last_detected_subject = "GA/GS"
            self._last_detected_topic = "Manual Content"
            return raw_text[:4000]

    def _retrieve_context(self, source_name: str, query: str) -> str:
        """Helper to query Pinecone for specific source context."""
        try:
            query_embedding = self.embeddings.embed_query(query)
            results = self.index.query(
                vector=query_embedding,
                top_k=20, # Higher k for a better "study" pool
                filter={"source": source_name},
                include_metadata=True
            )
            context_chunks = [match['metadata']['text'] for match in results['matches'] if 'text' in match['metadata']]
            return "\n\n".join(context_chunks)
        except Exception as e:
            print(f"Retrieval error for {source_name}: {e}")
            return ""

    def _scrape_url(self, url: str) -> str:
        """Specialized student-centric web scraper with domain handlers."""
        try:
            # Emulate a high-reputation browser
            headers = {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            }
            response = requests.get(url, headers=headers, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # --- Domain-Specific Handling (Heuristic) ---
            # If it's an educational blog, focus on the article content container
            edu_patterns = ['gktoday', 'testbook', 'byjus', 'jagranjosh', 'studyiq', 'unacademy']
            is_edu_site = any(p in url.lower() for p in edu_patterns)

            # Noise reduction
            for tag in soup(["script", "style", "nav", "footer", "header", "aside", "form", "iframe", "noscript", "button"]):
                tag.decompose()
            
            # Smart targeting
            if is_edu_site:
                # Most Indian EDU sites use 'article' or specific entry-content classes
                content = soup.find('article') or soup.find('div', class_=re.compile(r'content|post|entry|main', re.I))
            else:
                content = soup.find('main') or soup.find('article') or soup.body

            if not content:
                content = soup

            # Extraction with semantic spacing
            text = content.get_text(separator=' | ')
            
            # Post-processing: Remove typical noise sequences
            lines = []
            for line in text.splitlines():
                l = line.strip()
                # Skip tiny crumbs, social prompts, or typical 'Read More' fluff
                if len(l) > 25 and not any(noise in l.lower() for noise in ['subscribe', 'share this', 'follow us', 'rights reserved']):
                    lines.append(l)
            
            clean_text = '\n'.join(lines)
            print(f"Scraped {len(clean_text)} study characters from {url}")
            return clean_text[:15000]
            
        except Exception as e:
            print(f"Scraping error: {e}")
            return ""

    def _fetch_youtube_transcript(self, url: str) -> str:
        """Fetches the transcript of a YouTube video with standard API methods."""
        try:
            # Enhanced video ID extraction regex (Supports watch, embed, live, youtu.be)
            regex = r"(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|live)\/|.*[?&]v=)|youtu\.be\/)([^\"&?\/\s]{11})"
            match = re.search(regex, url)
            video_id = match.group(1) if match else None
            
            if not video_id:
                # Manual fallback check
                if "v=" in url:
                    video_id = url.split("v=")[1].split("&")[0]
                elif "youtu.be/" in url:
                    video_id = url.split("youtu.be/")[1].split("?")[0]
                elif "/live/" in url:
                    video_id = url.split("/live/")[1].split("?")[0]
            
            if not video_id:
                print("❌ Could not extract video ID from URL")
                return ""

            print(f"🎬 [YOUTUBE] video_id: {video_id}")
            
            try:
                # IMPORTANT: Some versions of this library require instantiation
                yt_api = YouTubeTranscriptApi()
                
                # 1. Try listing transcripts to find best match
                try:
                    # Try instance method first (based on current inspection)
                    transcript_list = yt_api.list(video_id)
                except AttributeError:
                    # Fallback to class method if it somehow exists but wasn't in dir
                    try:
                        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
                    except:
                        # Final fallback: Class-level list
                        transcript_list = YouTubeTranscriptApi.list(video_id)
                
                # 2. Prefer manually created, then auto, priority languages
                try:
                    transcript = transcript_list.find_transcript(['en', 'hi', 'en-IN', 'hi-IN'])
                except:
                    # Fallback to any English or Hindi then first available
                    try:
                        transcript = transcript_list.find_generated_transcript(['en', 'hi'])
                    except:
                        # Handle different return types
                        try:
                            transcript = next(iter(transcript_list))
                        except:
                            # Try one last direct search
                            transcript = transcript_list.find_transcript(['en', 'hi'])
                
                data = transcript.fetch()
                
                # Robust extraction: handle both objects with .text and dicts with ['text']
                full_text_parts = []
                for item in data:
                    if hasattr(item, 'text'):
                        full_text_parts.append(item.text)
                    elif isinstance(item, dict) and 'text' in item:
                        full_text_parts.append(item['text'])
                    else:
                        # Fallback for unexpected formats
                        full_text_parts.append(str(item))
                
                full_text = " ".join(full_text_parts)
                
                print(f"✅ [YOUTUBE] Successfully fetched {len(full_text)} characters.")
                return full_text[:25000]
                
            except Exception as e:
                print(f"⚠️ [YOUTUBE] Transcript missing/disabled: {e}")
                # FALLBACK: Try to scrape page title/description if transcript fails
                return self._scrape_youtube_metadata(url)
        
        except Exception as e:
            print(f"❌ [YOUTUBE] Critical Error: {e}")
            return ""

    def _scrape_youtube_metadata(self, url: str) -> str:
        """Fallback: Scrapes YouTube page title and description if transcript is missing."""
        try:
            print(f"🔎 [YOUTUBE] Scrapping metadata as fallback for: {url}")
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
            response = requests.get(url, headers=headers, timeout=10)
            if response.status_code != 200: return ""
            
            soup = BeautifulSoup(response.text, 'html.parser')
            title = soup.find('title').text.replace('- YouTube', '').strip() if soup.find('title') else ""
            
            # Description is often in meta tags
            description = ""
            desc_tag = soup.find('meta', attrs={'name': 'description'})
            if desc_tag:
                description = desc_tag.get('content', '')
            
            if title or description:
                print(f"✅ [YOUTUBE] Metadata found: {title}")
                return f"Topic: {title}\nSummary: {description}"
            return ""
        except Exception as e:
            print(f"❌ [YOUTUBE] Metadata scraping failed: {e}")
            return ""
