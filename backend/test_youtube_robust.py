from youtube_transcript_api import YouTubeTranscriptApi
import sys

def test_fetch(video_id):
    print(f"Testing fetch for: {video_id}")
    try:
        # 1. Try Direct (Instance Method)
        print("Attempting direct fetch (en, hi)...")
        # Instantiate
        api = YouTubeTranscriptApi() 
        transcript = api.fetch(video_id, languages=['en', 'hi', 'en-IN', 'hi-IN'])
        print(f"Direct Success! Items: {len(transcript)}")
        
        # Verify access pattern
        full_text = ""
        for item in transcript:
            # Check if item has .text attribute or is a dict
            if hasattr(item, 'text'):
                full_text += item.text + " "
            elif isinstance(item, dict) and 'text' in item:
                full_text += item['text'] + " "
            else:
                full_text += str(item) + " "
        
        print(f"Preview Text: {full_text[:100]}...")
        return
    except Exception as e:
        print(f"Direct failed: {e}")

    try:
        # 2. Try List & Find
        print("Attempting list_transcripts...")
        api = YouTubeTranscriptApi()
        tx_list = api.list(video_id)
        for t in tx_list:
            print(f"Found: {t.language_code} ({t.is_generated})")
        
        print("Attempting to find 'en' or 'hi'...")
        found = tx_list.find_transcript(['en', 'hi', 'en-IN', 'hi-IN'])
        print(f"Found transcript: {found.language_code}")
        data = found.fetch()
        print(f"Fetch Success! Items: {len(data)}")
    except Exception as e:
        print(f"Fallback failed: {e}")

if __name__ == "__main__":
    vid = "dQw4w9WgXcQ" # Default
    if len(sys.argv) > 1:
        vid = sys.argv[1]
    test_fetch(vid)
