import os
from pinecone import Pinecone
from dotenv import load_dotenv

# Path to the .env file in the backend directory
current_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(current_dir, '.env')
load_dotenv(dotenv_path=env_path)

PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = "quiz-generator"

def verify_connection():
    if not PINECONE_API_KEY:
        print("❌ Error: PINECONE_API_KEY not found in .env file.")
        return

    try:
        # Initialize Pinecone
        pc = Pinecone(api_key=PINECONE_API_KEY)
        
        # List indexes to verify connection
        indexes = pc.list_indexes()
        index_names = [i.name for i in indexes]
        
        print("✅ Connection to Pinecone successful!")
        print(f"Available Indexes: {index_names}")
        
        if PINECONE_INDEX_NAME in index_names:
            print(f"✅ Index '{PINECONE_INDEX_NAME}' is active and connected.")
            # Check index stats
            index = pc.Index(PINECONE_INDEX_NAME)
            stats = index.describe_index_stats()
            print(f"📊 Index Stats: {stats}")
        else:
            print(f"⚠️ Index '{PINECONE_INDEX_NAME}' not found in your Pinecone account.")
            
    except Exception as e:
        print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    verify_connection()
