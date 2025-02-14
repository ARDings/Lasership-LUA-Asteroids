import numpy as np
from scipy.io import wavfile

def create_shoot_sound():
    # Laser-ähnlicher Schuss-Sound
    sample_rate = 22050
    duration = 0.2
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Frequenz von hoch nach tief
    frequency = np.linspace(1000, 300, len(t))
    waveform = np.sin(2 * np.pi * frequency * t) * np.exp(-t * 10)
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('shoot.wav', sample_rate, waveform)

def create_explosion_sound():
    # Explosions-Sound mit weißem Rauschen
    sample_rate = 22050
    duration = 0.5
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Weißes Rauschen mit Abklingkurve
    noise = np.random.normal(0, 1, len(t))
    envelope = np.exp(-t * 8)  # Schnelles Abklingen
    waveform = noise * envelope
    
    # Tiefpass-Filter simulieren
    from scipy.signal import butter, filtfilt
    b, a = butter(4, 0.1)
    waveform = filtfilt(b, a, waveform)
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('explosion.wav', sample_rate, waveform)

def create_thrust_sound():
    # Düsen-Sound
    sample_rate = 22050
    duration = 0.3
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Basis-Rauschen
    noise = np.random.normal(0, 1, len(t))
    
    # Mehrere gefilterte Frequenzbänder
    from scipy.signal import butter, filtfilt
    b1, a1 = butter(2, [0.1, 0.3], btype='band')
    b2, a2 = butter(2, [0.2, 0.4], btype='band')
    
    noise1 = filtfilt(b1, a1, noise)
    noise2 = filtfilt(b2, a2, noise)
    
    waveform = (noise1 + noise2) * 0.5
    envelope = np.ones_like(t)
    envelope[:int(0.05*sample_rate)] = np.linspace(0, 1, int(0.05*sample_rate))
    
    waveform = waveform * envelope
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767 * 0.7)  # Etwas leiser
    wavfile.write('thrust.wav', sample_rate, waveform)

if __name__ == '__main__':
    print("Generiere Sound-Effekte...")
    create_shoot_sound()
    create_explosion_sound()
    create_thrust_sound()
    print("Fertig! Sound-Dateien wurden erstellt.") 