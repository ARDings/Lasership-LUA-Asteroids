#!/usr/bin/env python3
import board
import neopixel
import time

# LED Strip Konfiguration
LED_COUNT = 6  # Nur die ersten 6 LEDs nutzen
LED_PIN = board.D18
BRIGHTNESS = 0.5

# Vorbereitete Farben
OFF = (0, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)

class LEDVisualizer:
    def __init__(self):
        self.pixels = neopixel.NeoPixel(
            LED_PIN, 
            LED_COUNT, 
            brightness=BRIGHTNESS,
            auto_write=False
        )
        self.clear()
        print("Warte auf Spieldaten...")

    def clear(self):
        self.pixels.fill(OFF)
        self.pixels.show()

    def update_display(self, data):
        try:
            # Prüfe Spielzustand
            if 'state=gameover' in data or 'state=menu' in data:
                self.pixels.fill(OFF)
                self.pixels.show()
                return
                
            # Nur im Spielzustand LEDs aktualisieren
            if 'state=game' in data:
                # Items (LEDs 0-1)
                self.pixels[0] = BLUE if 'timewarp=1' in data else OFF
                self.pixels[1] = YELLOW if 'tripleshot=1' in data else OFF
                
                # Leben (LEDs 3-5)
                try:
                    lives = int(data.split('lives=')[1].split(',')[0])
                except:
                    lives = 0  # Fallback wenn Parse fehlschlägt
                
                # Setze erst alle Leben-LEDs aus
                for i in range(3, 6):
                    self.pixels[i] = OFF
                    
                # Dann setze die aktiven Leben
                for i in range(lives):
                    if i < 3:  # Sicherheitscheck
                        self.pixels[i + 3] = GREEN
                
                self.pixels.show()
        except:
            # Im Fehlerfall alle LEDs aus
            self.pixels.fill(OFF)
            self.pixels.show()

    def run(self):
        try:
            with open("/tmp/game_apm_pipe", 'r') as pipe:
                while True:
                    data = pipe.readline().strip()
                    if data:
                        self.update_display(data)
                    time.sleep(0.02)  # Längere Pause (50Hz statt 100Hz)
        except KeyboardInterrupt:
            self.cleanup()

    def cleanup(self):
        self.clear()

if __name__ == "__main__":
    visualizer = LEDVisualizer()
    visualizer.run() 