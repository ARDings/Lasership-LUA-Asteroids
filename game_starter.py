import tkinter as tk
import subprocess
import time

# Warte auf System
time.sleep(5)

def start_game():
    root.destroy()
    subprocess.run(['love', '.'])

# Fenster erstellen
root = tk.Tk()
root.title('Asteroids')
root.attributes('-fullscreen', True)
root.configure(bg='black')

# Start-Button
button = tk.Button(root, 
                  text='START GAME', 
                  command=start_game,
                  font=('Arial', 24),
                  bg='gray',
                  fg='white')
button.pack(expand=True)

# ESC zum Beenden
root.bind('<Escape>', lambda e: root.destroy())

root.mainloop() 