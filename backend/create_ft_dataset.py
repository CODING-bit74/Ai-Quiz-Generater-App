import os
import json
import time
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate
from rag_service import RAGService

# Load environment variables
load_dotenv()

# We use the existing RAG service to fetch real contexts
rag_service = RAGService()

# The "Teacher" model. We use the most capable model to generate the gold standard data.
# Note: In production, you might use gpt-4o for the highest quality examples.
# We'll stick to gpt-4o-mini here for speed and cost during dataset generation, 
# but we prompt it extremely heavily.
teacher_llm = ChatOpenAI(
    model="gpt-4o-mini", 
    temperature=0.7,
    openai_api_key=os.getenv("OPENAI_API_KEY")
)

# A list of diverse topics found in Indian Competitive Exams (UPSC, SSC, Banking, etc.)
TOPICS = [
    # History
    {"topic": "The Salt March 1930", "subject": "History", "sector": "UPSC", "difficulty": "Hard"},
    {"topic": "Battle of Panipat", "subject": "History", "sector": "SSC", "difficulty": "Medium"},
    {"topic": "Harappan Civilization", "subject": "History", "sector": "State PSC", "difficulty": "Easy"},
    # Polity
    {"topic": "Fundamental Rights Article 21", "subject": "Polity", "sector": "UPSC", "difficulty": "Hard"},
    {"topic": "Panchayati Raj System", "subject": "Polity", "sector": "SSC", "difficulty": "Medium"},
    {"topic": "President of India Election", "subject": "Polity", "sector": "Railway", "difficulty": "Easy"},
    # Science
    {"topic": "Photosynthesis", "subject": "Science", "sector": "SSC", "difficulty": "Easy"},
    {"topic": "Human Blood Groups", "subject": "Science", "sector": "Railway", "difficulty": "Medium"},
    {"topic": "Structure of Atom", "subject": "Science", "sector": "Defence", "difficulty": "Hard"},
    # Geography
    {"topic": "Himalayan River System", "subject": "Geography", "sector": "UPSC", "difficulty": "Hard"},
    {"topic": "Soils of India", "subject": "Geography", "sector": "SSC", "difficulty": "Medium"},
    # Economics
    {"topic": "Monetary Policy of RBI", "subject": "Economics", "sector": "Banking", "difficulty": "Hard"},
    {"topic": "Five Year Plans", "subject": "Economics", "sector": "State PSC", "difficulty": "Medium"},
]

# The precise system prompt that the FINE-TUNED model will eventually use in production.
# Notice how short it is! We rely on the fine-tuning to teach it the JSON format and behavior.
FINAL_SYSTEM_PROMPT = """You are the AI Quiz Professor for Indian Government Exams.
Generate highly factual, appropriately difficult MCQs strictly based on the provided context.
Output ONLY a JSON array of question objects."""

# The heavy prompt used by the TEACHER model to generate the perfect output.
TEACHER_PROMPT = """
You are generating "Gold Standard" training data to fine-tune a specialized quiz model.
Generate a perfectly formatted JSON array containing exactly 1 MCQ based on the criteria.

TARGET EXAM: {sector}
DIFFICULTY: {difficulty} ({difficulty_rules})
TOPIC: {topic}

CONTEXT (Source of Truth):
{context}

JSON FORMAT REQUIRED:
[
  {{
    "question": "The question text",
    "options": ["A. Option", "B. Option", "C. Option", "D. Option"],
    "answer": "B. Exact string match",
    "explanation": "Why B is correct, and why others are wrong. + Pro-Tip."
  }}
]

Return strictly the JSON array.
"""

def generate_example():
    examples = []
    
    # Generate 5 examples per topic to build a diverse dataset quickly
    for topic_data in TOPICS:
        print(f"Generating dataset examples for: {topic_data['topic']} ({topic_data['sector']} - {topic_data['difficulty']})")
        
        # 1. Fetch real context using the existing RAG pipeline
        try:
            query_embedding = rag_service.embeddings.embed_query(topic_data['topic'])
            results = rag_service.index.query(vector=query_embedding, top_k=3, include_metadata=True)
            context_chunks = [match['metadata']['text'] for match in results['matches'] if 'text' in match['metadata']]
            context = "\n\n".join(context_chunks)
        except Exception as e:
            print(f"Skipping {topic_data['topic']} due to Pinecone error: {e}")
            continue
            
        if not context or len(context) < 50:
             # Fallback context if not in DB
             context = f"General educational content about {topic_data['topic']} for {topic_data['sector']} exams."

        # Define specific rules based on difficulty to enforce quality in the teacher
        diff_rules = ""
        if topic_data['difficulty'] == "Hard":
             diff_rules = "multi-statement reasoning, 'Assertion-Reasoning', complex concepts"
        elif topic_data['difficulty'] == "Medium":
             diff_rules = "analytical patterns, logical comparisons"
        else:
             diff_rules = "direct facts, single-sentence memory recall"

        # 2. Ask the Teacher Model to generate the perfect output
        prompt = PromptTemplate.from_template(TEACHER_PROMPT)
        chain = prompt | teacher_llm
        
        # Generate 3 variations per topic
        for _ in range(3):
            try:
                response = chain.invoke({
                    "sector": topic_data['sector'],
                    "difficulty": topic_data['difficulty'],
                    "difficulty_rules": diff_rules,
                    "topic": topic_data['topic'],
                    "context": context[:3000] # Use top chunks
                })
                
                # Clean up teacher response to get pure JSON
                content = response.content.strip()
                if content.startswith("```json"):
                    content = content.replace("```json", "").replace("```", "").strip()
                elif content.startswith("```"):
                     content = content.replace("```", "").strip()
                
                # Verify it parses correctly
                json.loads(content)
                
                # 3. Format into OpenAI's JSONL chat schema
                user_message = f"Generate {topic_data['difficulty']} {topic_data['sector']} quiz on '{topic_data['topic']}'.\n\nContext:\n{context[:3000]}"
                
                jsonl_entry = {
                    "messages": [
                        {"role": "system", "content": FINAL_SYSTEM_PROMPT},
                        {"role": "user", "content": user_message},
                        {"role": "assistant", "content": content}
                    ]
                }
                examples.append(jsonl_entry)
                print(f" ✅ Success")
                time.sleep(1) # Rate limit protection
                
            except Exception as e:
                print(f" ❌ Failed generating variation: {e}")

    return examples

if __name__ == "__main__":
    print("Starting Fine-Tuning Dataset Generation...")
    dataset = generate_example()
    
    file_path = "fine_tune_data.jsonl"
    with open(file_path, 'w', encoding='utf-8') as f:
        for entry in dataset:
            f.write(json.dumps(entry) + '\n')
            
    print(f"\n🎉 Dataset Created! Saved {len(dataset)} examples to {file_path}")
    print("Next Step: Upload this file to https://platform.openai.com/finetune")
