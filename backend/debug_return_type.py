from youtube_transcript_api import YouTubeTranscriptApi
import sys

def test_type(video_id):
    print(f"Testing type for: {video_id}")
    try:
        api = YouTubeTranscriptApi() 
        data = api.fetch(video_id, languages=['en', 'hi', 'en-IN', 'hi-IN'])
        
        print(f"Data type: {type(data)}")
        if isinstance(data, list) and len(data) > 0:
            item = data[0]
            print(f"Item type: {type(item)}")
            print(f"Item dir: {dir(item)}")
            print(f"Item representation: {item}")
            
            try:
                print(f"Try dict access: {item['text']}")
            except Exception as e:
                print(f"Dict access failed: {e}")
                
            try:
                print(f"Try attr access: {item.text}")
            except Exception as e:
                print(f"Attr access failed: {e}")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_type("dQw4w9WgXcQ")
