#!/usr/bin/env python3
import board
import neopixel
import time

# Alle LEDs ausschalten
pixels = neopixel.NeoPixel(board.D18, 12, brightness=0.1)
pixels.fill((0, 0, 0))
pixels.show()
time.sleep(0.1)
pixels.show()  # Zweimal zur Sicherheit 