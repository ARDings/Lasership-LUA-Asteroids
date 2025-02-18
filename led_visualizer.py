#!/usr/bin/env python3
import board
import neopixel
import time
import math

# LED Strip Konfiguration
LED_COUNT = 6
LED_PIN = board.D18
BRIGHTNESS = 0.2

# Vorbereitete Farben
OFF = (0, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)

def pulse_color(color):
    """Sanftes Pulsieren zwischen 10% und 20% Helligkeit"""
    pulse = 0.1 + (math.sin(time.time() * 2) + 1) * 0.05  # Pulsiert zwischen 0.1 und 0.2
    return tuple(int(c * pulse) for c in color)

class LEDVisualizer:
    def __init__(self):
        try:
            # Explizit alle LEDs ausschalten bevor wir den Strip initialisieren
            pixels_temp = neopixel.NeoPixel(LED_PIN, 12, brightness=0)  # Temporär alle möglichen LEDs
            pixels_temp.fill(OFF)
            pixels_temp.show()
            del pixels_temp
            
            # Jetzt unseren eigentlichen Strip initialisieren
            self.pixels = neopixel.NeoPixel(
                LED_PIN, 
                LED_COUNT, 
                brightness=BRIGHTNESS,
                auto_write=False
            )
            self.reset_leds()
            
            # Mehrmals resetten um sicherzugehen
            for _ in range(3):
                self.reset_leds()
                time.sleep(0.1)
                
        except Exception as e:
            print(f"Fehler bei LED-Initialisierung: {e}")
            self.pixels = None

    def reset_leds(self):
        """Setzt alle LEDs zurück"""
        if self.pixels:
            self.pixels.fill(OFF)
            # Explizit 2 und 6 ausschalten
            self.pixels[2] = OFF
            if len(self.pixels) > 6:
                self.pixels[6] = OFF
            self.pixels.show()

    def update_display(self, data):
        if not self.pixels:
            return

        try:
            # Immer LEDs 2 und 6 ausschalten
            self.pixels[2] = OFF
            if len(self.pixels) > 6:  # Sicherheitscheck
                self.pixels[6] = OFF

            # Im Menu oder Game Over alles aus
            if 'state=menu' in data or 'state=gameover' in data:
                self.reset_leds()
                return

            # Nur im Spielzustand LEDs aktualisieren
            if 'state=game' in data:
                # Erst alles aus
                self.pixels.fill(OFF)
                # Nochmal explizit 2 und 6 aus
                self.pixels[2] = OFF
                if len(self.pixels) > 6:
                    self.pixels[6] = OFF

                # Items (LEDs 0-1)
                if 'timewarp=1' in data:
                    self.pixels[0] = pulse_color(BLUE)
                if 'tripleshot=1' in data:
                    self.pixels[1] = pulse_color(YELLOW)

                # Leben (LEDs 3-5)
                try:
                    lives = int(data.split('lives=')[1].split(',')[0])
                    for i in range(min(lives, 3)):
                        self.pixels[i + 3] = pulse_color(GREEN)
                except:
                    pass

                self.pixels.show()

        except Exception as e:
            self.reset_leds()

    def run(self):
        self.reset_leds()  # Sicherstellen, dass alle LEDs aus sind beim Start
        try:
            with open("/tmp/game_apm_pipe", 'r') as pipe:
                while True:
                    data = pipe.readline().strip()
                    if data:
                        self.update_display(data)
                    time.sleep(0.033)  # ~30Hz Updates für bessere Performance
        except KeyboardInterrupt:
            self.reset_leds()

    def cleanup(self):
        self.reset_leds()

if __name__ == "__main__":
    visualizer = LEDVisualizer()
    try:
        visualizer.run()
    finally:
        visualizer.cleanup() 