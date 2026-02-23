import wave
import math
import struct
import os

def generate_tone(filename, frequency, duration_ms, volume=0.5):
    sample_rate = 44100
    n_frames = int(sample_rate * (duration_ms / 1000.0))
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes per sample (16-bit)
        wav_file.setframerate(sample_rate)
        
        for i in range(n_frames):
            t = float(i) / sample_rate
            # Generate sine wave
            value = int(volume * 32767.0 * math.sin(2.0 * math.pi * frequency * t))
            # Convert to little-endian 16-bit signed integer
            data = struct.pack('<h', value)
            wav_file.writeframes(data)
    print(f"Generated {filename}")

# Ensure directory exists
os.makedirs('assets/audio', exist_ok=True)

# Generate a 'smooth click' sound (Soft, short, pleasant)
# 400Hz for 80ms with a slight fade out (simulated by short duration)
generate_tone('assets/audio/click.wav', 440, 80, volume=0.3)
