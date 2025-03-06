#!/usr/bin/env python3
import board
import neopixel
import time
import os
import sys

# Einfachere Konfiguration
LED_COUNT = 6
LED_PIN = board.D18
BRIGHTNESS = 0.2

# Einfache statische Farben ohne Pulsierung
OFF = (0, 0, 0)
GREEN = (0, 25, 0)  # Gedimmtes Grün für Stabilität
BLUE = (0, 0, 25)   # Gedimmtes Blau
YELLOW = (25, 25, 0) # Gedimmtes Gelb

class LEDVisualizer:
    def __init__(self):
        print("LED-Visualizer startet...")
        try:
            self.pixels = neopixel.NeoPixel(
                LED_PIN, 
                LED_COUNT, 
                brightness=BRIGHTNESS,
                auto_write=False
            )
            self.clear_all()
            print("Erfolgreich initialisiert")
        except Exception as e:
            print(f"Fehler: {e}")
            self.pixels = None
    
    def clear_all(self):
        """Alle LEDs aus"""
        if self.pixels:
            try:
                self.pixels.fill(OFF)
                self.pixels.show()
            except:
                pass
    
    def update_display(self, data):
        if not self.pixels:
            return
            
        try:
            # Vereinfachte Logik
            if 'state=menu' in data or 'state=gameover' in data:
                self.clear_all()
                return
            
            if 'state=game' in data:
                # Setze alle auf OFF
                self.pixels.fill(OFF)
                
                # Power-ups - KEINE Pulsierung mehr (stabiler)
                if 'timewarp=1' in data:
                    self.pixels[0] = BLUE
                if 'tripleshot=1' in data:
                    self.pixels[1] = YELLOW
                
                # Leben
                try:
                    lives = int(data.split('lives=')[1].split(',')[0])
                    for i in range(min(lives, 3)):
                        self.pixels[i + 3] = GREEN
                except:
                    pass
                
                # Explizit LED 2 aus
                self.pixels[2] = OFF
                
                # Anzeigen
                self.pixels.show()
                
        except:
            # Bei Fehlern nichts tun (keine erneuten Fehler verursachen)
            pass

    def run(self):
        # Stelle sicher, dass Pipe existiert
        pipe_path = "/tmp/game_apm_pipe"
        if not os.path.exists(pipe_path):
            try:
                os.mkfifo(pipe_path)
            except:
                pass
        
        # Hauptschleife mit robuster Fehlerbehandlung
        while True:
            try:
                with open(pipe_path, 'r') as pipe:
                    print("Bereit und warte auf Daten...")
                    while True:
                        data = pipe.readline().strip()
                        if data:
                            self.update_display(data)
                        time.sleep(0.1)  # Längere Pause (10 Updates/Sekunde)
            except KeyboardInterrupt:
                break
            except:
                time.sleep(1)  # Längere Pause bei Fehlern

    def cleanup(self):
        self.clear_all()

if __name__ == "__main__":
    visualizer = LEDVisualizer()
    try:
        visualizer.run()
    finally:
        visualizer.cleanup() 