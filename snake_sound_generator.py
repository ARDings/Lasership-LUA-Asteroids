import numpy as np
from scipy.io import wavfile

def create_eat_sound():
    sample_rate = 44100
    duration = 0.1
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Aufsteigender Ton
    frequency = np.linspace(440, 880, len(t))
    waveform = np.sin(2 * np.pi * frequency * t)
    
    # Hüllkurve
    envelope = np.exp(-t * 20)
    waveform = waveform * envelope
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('eat.wav', sample_rate, waveform)

def create_crash_sound():
    sample_rate = 44100
    duration = 0.2
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Absteigender Ton mit Rauschen
    frequency = np.linspace(440, 110, len(t))
    tone = np.sin(2 * np.pi * frequency * t)
    noise = np.random.normal(0, 1, len(t))
    
    waveform = tone * 0.7 + noise * 0.3
    
    # Hüllkurve
    envelope = np.exp(-t * 10)
    waveform = waveform * envelope
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('crash.wav', sample_rate, waveform)

if __name__ == '__main__':
    print("Generiere Sound-Effekte...")
    create_eat_sound()
    create_crash_sound()
    print("Fertig!") 