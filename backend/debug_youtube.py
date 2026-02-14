from youtube_transcript_api import YouTubeTranscriptApi
import sys

def test_video(video_id):
    print(f"--- Testing Video: {video_id} ---")
    try:
        # Try fetching with preferred languages
        transcript_list = YouTubeTranscriptApi.get_transcript(video_id, languages=['en', 'hi', 'en-IN'])
        
        full_text = " ".join([item['text'] for item in transcript_list])
        print(f"SUCCESS! Fetched {len(full_text)} characters.")
        print(f"Preview: {full_text[:200]}...")
        return True
    except Exception as e:
        print(f"FAILED: {e}")
        
        # Try listing available transcripts to see what went wrong
        try:
            print("Listing available transcripts:")
            transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
            for transcript in transcript_list:
                print(f" - {transcript.language} ({transcript.language_code}) | Generated: {transcript.is_generated}")
        except Exception as e2:
            print(f"Could not list transcripts: {e2}")
        return False

if __name__ == "__main__":
    # Test with a few known IDs or user provided one
    # 1. A standard English video (e.g., Flutter tutorial)
    # 2. A Hindi video (e.g., Current Affairs)
    
    # You can pass a video ID as arg
    if len(sys.argv) > 1:
        test_video(sys.argv[1])
    else:
        print("No video ID provided. Testing hardcoded examples...")
        test_video("dQw4w9WgXcQ") # Rick Roll (English)
        test_video("_GuOjXYl5ew") # Random Hindi generic video ID (Placeholder)
