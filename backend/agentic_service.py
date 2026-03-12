
import os
import json
import re
import requests
import asyncio
from typing import List, Dict, Any, Optional
import json_repair

# LangChain Imports for Agentic Workflow
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_core.prompts import PromptTemplate
from langchain_core.runnables import RunnablePassthrough, RunnableLambda

# Pinecone & Existing Logic
from pinecone import Pinecone
from rag_service import RAGService, TranscriptNotFoundError

# Initialize Environment
from dotenv import load_dotenv
load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = "quiz-generator"

class QuizAgent:
    """
    An Agentic wrapper around the RAG pipeline.
    Uses LLM reasoning to Plan -> Retrieve -> Generate.
    (Deep Learning & NLP components removed per user request)
    """
    def __init__(self):
        # 1. Initialize Core Components with our new FINE-TUNED model
        self.llm = ChatOpenAI(
            model="ft:gpt-4o-mini-2024-07-18:personal:quiz-generator:DIGxdncf", 
            temperature=0.7,
            openai_api_key=OPENAI_API_KEY
        )
        self.embeddings = OpenAIEmbeddings(
            model="text-embedding-3-small", 
            openai_api_key=OPENAI_API_KEY
        )
        
        # Reuse existing RAG service for low-level ops
        self.rag_service = RAGService()
        try:
            self.index = self.rag_service.index 
        except AttributeError:
            print("Warning: Could not access RAGService index directly.")

        # 2. Define the Agent's "Brain" (The Planner)
        self.planner_prompt = PromptTemplate.from_template("""
        You are the **Lead Quiz Architect** for an exam prep platform.
        A user wants a quiz. Analyze their request and decide the best strategy.

        Request:
        topic: "{topic}" (User Input)
        input_type: "{input_type}" (Source Type: topic, link, document, text, pyq_search)
        
        Available Strategies:
        1. SEARCH_KB: Broad topic (e.g., "Mughal Empire"). Search Knowledge Base (Vector DB).
        2. SCRAPE_URL: Specific URL provided (YouTube or Article). Fetch and study it.
        3. READ_DOC: File reference provided. Read document context from Vector DB.
        4. DIRECT_GEN: Full text provided OR extremely general topic (e.g., "Maths").
        5. PYQ_SEARCH: specifically search for Previous Year Questions regarding the topic using the Vector DB.
        
        Logic Rules:
        - If 'topic' looks like a URL (http/https) -> Choose SCRAPE_URL even if input_type is 'topic'.
        - If input_type is 'link' -> SCRAPE_URL.
        - If input_type is 'document' -> READ_DOC.
        - If input_type is 'text' -> DIRECT_GEN.
        - If input_type == 'pyq_search' -> Choose PYQ_SEARCH.
        - If input_type is 'topic':
            - Context-heavy / specific? SEARCH_KB
            - Very generic / no context found? DIRECT_GEN
        
        Return STRICT JSON:
        {{
            "strategy": "SEARCH_KB" | "SCRAPE_URL" | "READ_DOC" | "DIRECT_GEN" | "PYQ_SEARCH",
            "reasoning": "Short explanation",
            "suggested_topic": "Concise topic if original was a messy URL"
        }}
        
        Return ONLY the JSON object.
        """)
        
        # 3. Define the Query Expander (For SEARCH_KB)
        self.expander_prompt = PromptTemplate.from_template("""
        You are a Research Assistant. The user wants a quiz on "{topic}".
        Generate 3 distinct search queries to find comprehensive information in a Vector Database.
        1. Broad overview
        2. Key specific details, facts, and figures
        3. Related sub-topics and advanced concepts
        
        Return ONLY valid JSON array of strings: ["query1", "query2", "query3"]
        """)

    def generate_quiz_agentic(self, topic: str, **kwargs) -> str:
        """
        The main entry point for the Agentic Workflow.
        """
        print(f"\n🤖 [AGENT START] Topic: {topic}")
        
        # --- Pre-Planning Check for URLs ---
        current_input_type = kwargs.get('input_type', 'topic')
        if current_input_type == 'topic' and (topic.startswith('http') or 'youtube.com' in topic or 'youtu.be' in topic):
            print("🚀 [AGENT] URL detected in Topic. Overriding input_type to 'link'.")
            kwargs['input_type'] = 'link'
            current_input_type = 'link'

        # --- Step 1: PLANNING ---
        # Enhance topic for better retrieval context
        subject = kwargs.get('subject')
        sector = kwargs.get('exam_sector')
        
        search_topic = topic
        if current_input_type == 'topic':
            if subject and sector:
                search_topic = f"{subject} ({topic}) for {sector} Exams"
            elif subject:
                 search_topic = f"{subject}: {topic}"
             
        plan_data = self._plan_strategy(search_topic, current_input_type)
        strategy = plan_data.get('strategy', 'DIRECT_GEN')
        reasoning = plan_data.get('reasoning', 'Defaulting')
        
        # Use suggested topic if provided (useful for cleaning up URL topics)
        if plan_data.get('suggested_topic'):
            effective_topic = plan_data.get('suggested_topic')
        else:
            effective_topic = search_topic
        
        print(f"🧠 [PLANNER] Strategy: {strategy} ({reasoning})")
        
        context_text = ""
        
        # --- Step 2: EXECUTION (Retrieval) ---
        if strategy == "SEARCH_KB":
            context_text = self._execute_search_kb(effective_topic)
        elif strategy == "SCRAPE_URL":
            context_text = self._execute_scrape(topic)
            # --- INTELLIGENT FALLBACK: If scrape failed or is too small, try searching Knowledge Base ---
            if not context_text or len(context_text) < 200:
                print("⚠️ [AGENT] Scrape yield too low. Swapping to SEARCH_KB fallback.")
                # If it's a YouTube URL, we might have title/desc in context_text now
                search_query = effective_topic
                if "Topic: " in context_text:
                    # Extract the title we just scraped
                    search_query = context_text.split("\n")[0].replace("Topic: ", "")
                
                context_text = self._execute_search_kb(search_query)
        
        elif strategy == "READ_DOC":
            context_text = self._execute_read_doc(topic)
        elif strategy == "PYQ_SEARCH":
            # Enhance the topic to specifically ask for Previous Year Questions
            pyq_topic = f"{effective_topic} Previous Year Questions PYQs"
            context_text = self._execute_search_kb(pyq_topic)
            if not context_text or len(context_text) < 100:
                print("⚠️ [AGENT] No specific PYQs found. Searching general knowledge base.")
                context_text = self._execute_search_kb(effective_topic)
        elif strategy == "DIRECT_GEN":
            if current_input_type == 'text':
                context_text = "User Provided Text: " + topic[:5000]
                effective_topic = "Custom Study Material"
            else:
                context_text = "General Knowledge (Direct Generation)"
        
        # Final Fallback for empty context
        if not context_text or len(context_text) < 100:
             print("⚠️ [AGENT] Final context yield empty. Forcing general knowledge fallback.")
             context_text = "General Knowledge"

        # --- Step 3: GENERATION ---
        print("✍️ [GENERATOR] Crafting quiz with agent-retrieved context...")
        
        return self._generate_final_quiz(
            context=context_text,
            topic=effective_topic,
            num=kwargs.get('num_questions', 5),
            diff=kwargs.get('difficulty', 'Medium'),
            lang=kwargs.get('language', 'English'),
            input_type=current_input_type,
            sector=kwargs.get('exam_sector'),
            exam=kwargs.get('exam_name'),
            subject=kwargs.get('subject'),
            persona=self._get_persona(
                kwargs.get('difficulty', 'Medium'),
                kwargs.get('exam_sector')
            )
        )

    # --- HELPER FUNCTIONS ---

    def _plan_strategy(self, topic: str, input_type: str) -> Dict:
        """Decides the retrieval strategy using LLM."""
        try:
            chain = self.planner_prompt | self.llm
            response = chain.invoke({"topic": topic, "input_type": input_type})
            text = self._clean_json(response.content)
            return json.loads(text)
        except Exception as e:
            print(f"❌ Planner Error: {e}. Defaulting based on input_type.")
            if input_type == 'link': return {"strategy": "SCRAPE_URL"}
            if input_type == 'document': return {"strategy": "READ_DOC"}
            return {"strategy": "SEARCH_KB"}

    def _execute_search_kb(self, topic: str) -> str:
        """Agentic Search: Expands query -> Searches -> Aggregates."""
        try:
            # 1. Expand Query
            exp_chain = self.expander_prompt | self.llm
            response = exp_chain.invoke({"topic": topic})
            queries = json.loads(self._clean_json(response.content))
            print(f"🔍 [SEARCH] Execution Queries: {queries}")
            
            # 2. Multi-Query Search
            aggregated_docs = []
            for q in queries:
                embedding = self.embeddings.embed_query(q)
                results = self.index.query(
                    vector=embedding,
                    top_k=5, # Increased k for better coverage
                    include_metadata=True
                )
                for match in results['matches']:
                    if 'score' in match and match['score'] > 0.3: # Relevance threshold
                        if 'metadata' in match and 'text' in match['metadata']:
                             aggregated_docs.append(match['metadata']['text'])
            
            # 3. Deduplication and Ranking (Simple)
            unique_docs = list(dict.fromkeys(aggregated_docs)) # Preserves order
            print(f"📚 [SEARCH] Found {len(unique_docs)} unique chunks.")
            
            if not unique_docs:
                # Fallback: One last broad search
                print("🔄 [SEARCH] No results. Trying broad fallback search.")
                embedding = self.embeddings.embed_query(topic)
                results = self.index.query(vector=embedding, top_k=3, include_metadata=True)
                unique_docs = [m['metadata']['text'] for m in results['matches'] if 'text' in m['metadata']]

            return "\n\n".join(unique_docs[:8]) # Return more chunks for richer context
            
        except Exception as e:
            print(f"❌ Search Error: {e}")
            return ""

    def _execute_scrape(self, url: str) -> str:
        """Executes URL scraping via RAGService."""
        print(f"🌐 [SCRAPER] Fetching content from: {url}")
        if "youtube.com" in url or "youtu.be" in url:
            return self.rag_service._fetch_youtube_transcript(url)
        return self.rag_service._scrape_url(url)

    def _execute_read_doc(self, filename: str) -> str:
        """Executes document retrieval with specific filtering."""
        print(f"📄 [DOC_READER] Searching for content in: {filename}")
        # Try both direct match and contains match for safety
        context = self.rag_service._retrieve_context(filename, "Summarize all key educational concepts and facts")
        if not context:
             print(f"⚠️ [DOC_READER] No direct match for {filename}. Trying partial match.")
             # This would require more complex filtering in Pinecone, 
             # but we'll stick to what _retrieve_context provides for now.
             pass
        return context

    def _get_persona(self, difficulty: str, sector: str = None, agent_style: str = "Professor") -> str:
        # 1. Base Persona by Sector
        sector_mapping = {
            "Banking": "Expert Banking Faculty (IBPS/SBI PO Level). Focus on speed, accuracy, and financial awareness.",
            "SSC": "SSC CGL Mentor. Focus on standard patterns, static GK, and previous year trends.",
            "UPSC": "Senior Civil Services Faculty. Focus on deep conceptual understanding and multi-dimensional analysis.",
            "Railway": "Railway Exam Tactician. Focus on direct facts, general science, and current affairs.",
            "Defence": "Defence Academy Instructor. Focus on physical sciences, defense GK, and logical reasoning.",
            "Teaching": "Pedagogy & Education Expert (CTET/NET). Focus on child development theories and subject methodology.",
            "Law": "Legal Scholar & CLAT Expert. Focus on legal reasoning, constitution, and legal aptitude.",
            "Medical": "NEET/Medical Prep Expert. Focus on NCERT-based deep biological and chemical concepts.",
            "Police": "Police Exam Trainer. Focus on reasoning, state GK, and basic laws.",
            "State PSC": "State Civil Services Expert. Focus on state-specific geography, history, and administration."
        }
        
        base_role = sector_mapping.get(sector, "General Competitive Exam Expert.")
        
        # 2. Agent Style Nuance
        style_nuance = ""
        if agent_style == "Drill Sergeant":
            style_nuance = "ACT LIKE A STRICT DRILL SERGEANT. Be intense, demand precision, and call out laziness. Use phrases like 'LISTEN UP CADET!' or 'DROP AND GIVE ME 20!'. Focus on eliminating mistakes."
        elif agent_style == "Study Buddy":
            style_nuance = "ACT LIKE A SUPPORTIVE STUDY BUDDY. Be encouraging, fun, and simplified. Use emojis, simple analogies, and cheer on the student. 'You got this!', 'Let's crush it together!'."
        else: # Professor (Default)
            style_nuance = "ACT LIKE A DISTINGUISHED PROFESSOR. Be formal, academic, and deeply knowledgeable. Focus on clear concepts, derivation of answers, and intellectual curiosity."

        # 3. Difficulty Nuance
        diff_nuance = ""
        if difficulty == "Easy":
            diff_nuance = "Keep questions straightforward and fundamental."
        elif difficulty == "Medium":
            diff_nuance = "Balance between facts and application."
        elif difficulty == "Hard":
            diff_nuance = "Create complex, multi-statement, or critical thinking questions."
            
        return f"{base_role} {style_nuance} {diff_nuance} Mode: Agentic."

    def _generate_final_quiz(self, context, topic, num, diff, lang, input_type, sector, exam, subject, persona):
        """
        Direct generation using the retrieved context. 
        """
        target_info = f"target: {exam} ({sector})" if exam else f"Sector: {sector}"
        pyq_rule = "5. PYQ STYLE: The user requested Previous Year Questions. Format, structure, and difficulty MUST match official exam questions. Cite the exam where possible in the explanation." if input_type == 'pyq_search' else ""
        
        all_questions = []
        # We allow up to num + 2 attempts to gather enough questions
        max_attempts = num + 2
        attempts = 0
        
        while len(all_questions) < num and attempts < max_attempts:
            attempts += 1
            remaining = num - len(all_questions)
            
            # Create a localized prompt for the current batch
            batch_prompt = f"""You are acting as the following AI Tutor persona: {persona}
Your task is to generate EXACTLY {remaining} {diff} level MCQs in {lang} language based on the context.
Output ONLY a JSON array of {remaining} question objects.

TOPIC: '{topic}'
TARGET: {target_info}
"""
            if all_questions:
                batch_prompt += "\nAvoid repeating these questions:\n" + "\n".join([q.get('question', '')[:50] for q in all_questions])

            current_prompt_template = batch_prompt + "\n\nContext:\n{context}"

            try:
                # Use a fresh prompt each time to clear previous state
                prompt = PromptTemplate.from_template(current_prompt_template)
                chain = prompt | self.llm
                
                response_msg = chain.invoke({"context": context[:15000]})
                
                cleaned = self._clean_json(response_msg.content)
                new_questions = json_repair.loads(cleaned)
                
                if isinstance(new_questions, list):
                    all_questions.extend(new_questions)
                elif isinstance(new_questions, dict):
                    all_questions.append(new_questions)
                
                # Deduplicate and clamp
                unique_qs = []
                seen = set()
                for q in all_questions:
                    txt = q.get('question', '').strip().lower()
                    if txt and txt not in seen:
                        seen.add(txt)
                        unique_qs.append(q)
                all_questions = unique_qs[:num]

            except Exception as e:
                print(f"Attempt {attempts} failed: {e}")
                time.sleep(0.5)

        return json.dumps({
            "questions": all_questions,
            "detected_subject": subject,
            "detected_topic": topic
        })

    @staticmethod
    def _clean_json(text: str) -> str:
        match = re.search(r'```json\s*(.*?)\s*```', text, re.DOTALL)
        if match: return match.group(1)
        match = re.search(r'\[.*\]', text, re.DOTALL) 
        if match: return match.group(0)
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if match: return match.group(0)
        return text
