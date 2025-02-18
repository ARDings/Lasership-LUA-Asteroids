#!/usr/bin/env python3
import board
import neopixel
import time
import math

# LED Strip Konfiguration
LED_COUNT = 6
LED_PIN = board.D18
BRIGHTNESS = 0.2  # Basis-Helligkeit

# Vorbereitete Farben
OFF = (0, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)

def pulse_color(color):
    """Erzeugt einen pulsierenden Effekt zwischen 5% und 20% Helligkeit"""
    pulse = 0.05 + (math.sin(time.time() * 3) + 1) * 0.075  # Pulsiert zwischen 0.05 und 0.2
    return tuple(int(c * pulse) for c in color)

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
                self.pixels[0] = pulse_color(BLUE) if 'timewarp=1' in data else OFF
                self.pixels[1] = pulse_color(YELLOW) if 'tripleshot=1' in data else OFF
                
                # Leben (LEDs 3-5)
                try:
                    lives = int(data.split('lives=')[1].split(',')[0])
                except:
                    lives = 0
                
                # Setze erst alle Leben-LEDs aus
                for i in range(3, 6):
                    self.pixels[i] = OFF
                    
                # Dann setze die aktiven Leben mit Pulsieren
                for i in range(lives):
                    if i < 3:
                        self.pixels[i + 3] = pulse_color(GREEN)
                
                self.pixels.show()
        except:
            self.pixels.fill(OFF)
            self.pixels.show()

    def run(self):
        try:
            with open("/tmp/game_apm_pipe", 'r') as pipe:
                while True:
                    data = pipe.readline().strip()
                    if data:
                        self.update_display(data)
                    time.sleep(0.016)  # 60Hz Update für sanftes Pulsieren
        except KeyboardInterrupt:
            self.cleanup()

    def cleanup(self):
        self.clear()

if __name__ == "__main__":
    visualizer = LEDVisualizer()
    visualizer.run() 