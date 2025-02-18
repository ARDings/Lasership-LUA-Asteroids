# Asteroids on Raspberry Pi with LED Feedback

A modern take on the classic Asteroids game, built with LÖVE (Lua) and running on a Raspberry Pi with LED strip visualization. The game features smooth 60 FPS gameplay, retro CRT effects, and real-time game state feedback through WS281x LED strips.

## Features

- Classic Asteroids gameplay with modern touches
- Smooth 60 FPS performance on Raspberry Pi
- Real-time LED feedback for:
  - Lives (Green LEDs)
  - Time Warp power-up (Blue LED)
  - Triple Shot power-up (Yellow LED)
- Retro CRT shader effects
- Gamepad support
- Particle effects for explosions and thrusters

## Requirements

### Hardware
- Raspberry Pi (tested on Pi Zero)
- WS281x LED Strip (6 LEDs minimum)
- Optional: USB Gamepad

### Software
- LÖVE (11.4+)
- Python 3.7+
- rpi_ws281x library
- Adafruit NeoPixel library

## Installation

1. Clone the repository:
