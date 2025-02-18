import numpy as np
from scipy.io import wavfile

def create_shoot_sound():
    sample_rate = 44100
    duration = 0.1
    t = np.linspace(0, duration, int(sample_rate * duration))
    freq = 440 * np.exp(-t * 10)
    waveform = np.sin(2 * np.pi * freq * t) * np.exp(-t * 10)
    waveform = np.int16(waveform * 32767)
    wavfile.write('shoot.wav', sample_rate, waveform)

def create_explosion_sound():
    sample_rate = 44100
    duration = 0.2
    t = np.linspace(0, duration, int(sample_rate * duration))
    noise = np.random.normal(0, 1, len(t))
    freq = 220 * np.exp(-t * 5)
    tone = np.sin(2 * np.pi * freq * t)
    waveform = (noise * 0.3 + tone * 0.7) * np.exp(-t * 5)
    waveform = np.int16(waveform * 32767)
    wavfile.write('explosion.wav', sample_rate, waveform)

def create_powerup_sound():
    # Sampling rate
    sr = 44100
    duration = 0.3
    t = np.linspace(0, duration, int(sr * duration))
    
    # Aufsteigender Ton
    freq = np.linspace(440, 880, len(t))  # Von 440Hz zu 880Hz
    signal = np.sin(2 * np.pi * freq * t)
    
    # Hüllkurve
    envelope = np.exp(-3 * t)
    signal = signal * envelope
    
    # Normalisieren und als 16-bit speichern
    signal = np.int16(signal * 32767)
    wavfile.write('powerup.wav', sr, signal)

if __name__ == '__main__':
    print("Generiere Sounds...")
    create_shoot_sound()
    create_explosion_sound()
    create_powerup_sound()
    print("Fertig!") 