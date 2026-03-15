import os
import redis
from dotenv import load_dotenv

load_dotenv()

REDIS_URL = os.environ.get("REDIS_URL")
print(f"Connecting to: {REDIS_URL.split('@')[-1]}") # Hide credentials in output

try:
    client = redis.StrictRedis.from_url(REDIS_URL, decode_responses=True)
    response = client.ping()
    if response:
        print("✅ Redis connection successful!")
    else:
        print("❌ Redis ping failed.")
except Exception as e:
    print(f"❌ Redis connection failed: {e}")
