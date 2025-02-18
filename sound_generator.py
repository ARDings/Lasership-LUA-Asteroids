import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, filtfilt

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
    b, a = butter(4, 0.1)
    waveform = filtfilt(b, a, waveform)
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('explosion.wav', sample_rate, waveform)

def create_thruster_sound():
    # Sampling rate
    sample_rate = 44100
    duration = 1.0  # 1 Sekunde
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Basis-Frequenz für den Thruster (tiefer Brummton)
    base_freq = 80
    
    # Mehrere Frequenzkomponenten für reicheren Klang
    signal = np.sin(2 * np.pi * base_freq * t) * 0.3
    signal += np.sin(2 * np.pi * (base_freq * 2) * t) * 0.2
    signal += np.sin(2 * np.pi * (base_freq * 3) * t) * 0.1
    
    # Rauschen hinzufügen
    noise = np.random.normal(0, 0.1, len(t))
    signal += noise * 0.2
    
    # Leichtes Pulsieren
    modulation = np.sin(2 * np.pi * 8 * t)  # 8 Hz Modulation
    signal *= (1 + modulation * 0.2)
    
    # Normalisierung
    signal = signal / np.max(np.abs(signal))
    
    # Konvertierung zu 16-bit Integer
    signal = (signal * 32767).astype(np.int16)
    
    # Sound speichern
    wavfile.write('thruster.wav', sample_rate, signal)

def create_powerup_sound():
    # Power-up Sound mit aufsteigender Frequenz und Harmonischen
    sample_rate = 22050
    duration = 0.3
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Aufsteigende Hauptfrequenz
    freq_start = 300
    freq_end = 900
    frequency = np.linspace(freq_start, freq_end, len(t))
    
    # Hauptton plus Harmonische
    waveform = np.sin(2 * np.pi * frequency * t) * 0.5
    waveform += np.sin(4 * np.pi * frequency * t) * 0.25  # Erste Harmonische
    waveform += np.sin(6 * np.pi * frequency * t) * 0.125  # Zweite Harmonische
    
    # Hüllkurve mit schnellem Anstieg und langsamem Abfall
    envelope = np.exp(-t * 5)
    envelope[:int(len(t)*0.1)] = np.linspace(0, 1, int(len(t)*0.1))
    waveform = waveform * envelope
    
    # Leichtes Vibrato
    vibrato = np.sin(2 * np.pi * 30 * t) * 0.1
    waveform = waveform * (1 + vibrato)
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('powerup.wav', sample_rate, waveform)

def create_time_warp_sound():
    # Zeitverzerrungseffekt
    sample_rate = 22050
    duration = 0.5
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Aufsteigende Frequenz mit Wobble
    base_freq = np.linspace(200, 800, len(t))
    wobble = np.sin(2 * np.pi * 20 * t) * 50  # 20 Hz Wobble
    frequency = base_freq + wobble
    
    # Mehrere Frequenzkomponenten
    waveform = np.sin(2 * np.pi * frequency * t) * 0.5
    waveform += np.sin(4 * np.pi * frequency * t) * 0.25
    
    # Zeitverzerrungseffekt durch Phasemodulation
    phase_mod = np.sin(2 * np.pi * 8 * t) * 0.5
    waveform *= (1 + phase_mod)
    
    # Hüllkurve
    envelope = np.exp(-t * 4)
    waveform = waveform * envelope
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('time_warp.wav', sample_rate, waveform)

def create_photon_blast_sound():
    # Energieexplosion
    sample_rate = 22050
    duration = 0.4
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Hauptton (aufsteigend)
    freq = np.linspace(100, 2000, len(t))
    waveform = np.sin(2 * np.pi * freq * t)
    
    # Energetisches Rauschen mit Tiefpass-Filter
    noise = np.random.normal(0, 1, len(t))
    b, a = butter(4, 0.1)  # Filter-Koeffizienten hier definieren
    filtered_noise = filtfilt(b, a, noise)
    
    # Kombinieren
    waveform = (waveform * 0.7 + filtered_noise * 0.3)
    
    # Schneller Anstieg, langsamer Abfall
    envelope = np.exp(-t * 8)
    envelope[:int(len(t)*0.1)] = np.linspace(0, 1, int(len(t)*0.1))
    waveform = waveform * envelope
    
    # Normalisieren und konvertieren
    waveform = np.int16(waveform * 32767)
    wavfile.write('photon_blast.wav', sample_rate, waveform)

if __name__ == '__main__':
    print("Generiere Sound-Effekte...")
    create_shoot_sound()
    create_explosion_sound()
    create_thruster_sound()
    create_powerup_sound()
    create_time_warp_sound()
    create_photon_blast_sound()
    print("Fertig! Sound-Dateien wurden erstellt.") 