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

1. Clone the repository: bash
git clone https://github.com/yourusername/asteroids-pi
cd asteroids-pi

2. Set up the Python virtual environment: bash
python3 -m venv led_env
source led_env/bin/activate
pip install rpi_ws281x adafruit-circuitpython-neopixel

3. Make the scripts executable: bash
chmod +x start_led.sh
chmod +x led_visualizer.py
chmod +x reset_leds.py

## Running the Game

1. Reset the LED strip (optional): bash
sudo python3 reset_leds.py
2. Start the game: bash
love .

## Controls

- Arrow Keys / Gamepad Left Stick: Rotate ship
- Up Arrow / Gamepad Right Trigger: Thrust
- Space / Gamepad A Button: Shoot
- Escape: Quit game

## LED Layout

The game uses 6 LEDs in the following configuration:
- LED 0: Time Warp power-up (Blue)
- LED 1: Triple Shot power-up (Yellow)
- LED 3-5: Lives remaining (Green)

## Credits

- Original Asteroids game by Atari
- LÖVE framework (https://love2d.org)
- Adafruit NeoPixel library


