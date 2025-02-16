import os
import shutil
import zipfile
import subprocess

def create_windows_build():
    print("Starte Build-Prozess...")
    
    # Erstelle build Ordner
    if not os.path.exists('build'):
        os.makedirs('build')
        print("Build-Ordner erstellt")
    
    # Erstelle .love Datei
    print("Erstelle game.love...")
    with zipfile.ZipFile('build/game.love', 'w', zipfile.ZIP_DEFLATED) as zf:
        # Füge alle .lua und .wav Dateien hinzu
        for file in os.listdir('.'):
            if file.endswith(('.lua', '.wav')):
                zf.write(file)
                print(f"Füge hinzu: {file}")
    
    # Suche LÖVE-Installation
    possible_paths = [
        "C:/Program Files/LOVE",
        "C:/Program Files (x86)/LOVE",
        os.path.expanduser("~/AppData/Local/Programs/LOVE")
    ]
    
    love_path = None
    for path in possible_paths:
        if os.path.exists(path) and os.path.exists(os.path.join(path, 'love.exe')):
            love_path = path
            break
    
    if not love_path:
        print("LÖVE nicht gefunden! Bitte installiere LÖVE von https://love2d.org/")
        return
    
    print(f"LÖVE gefunden in: {love_path}")
    
    # Kopiere benötigte Dateien
    required_files = [
        'love.exe',
        'lua51.dll',
        'mpg123.dll',
        'OpenAL32.dll',
        'SDL2.dll',
        'love.dll',
        'msvcp140.dll',
        'vcruntime140.dll',
        'vcruntime140_1.dll'
    ]
    
    print("Kopiere LÖVE-Dateien...")
    for file in required_files:
        src = os.path.join(love_path, file)
        dst = os.path.join('build', file)
        if os.path.exists(src):
            shutil.copy(src, dst)
            print(f"Kopiert: {file}")
        else:
            print(f"Warnung: {file} nicht gefunden!")
    
    # Kombiniere love.exe und game.love
    print("Erstelle ausführbare Datei...")
    with open('build/game.exe', 'wb') as f:
        with open('build/love.exe', 'rb') as love_exe:
            f.write(love_exe.read())
        with open('build/game.love', 'rb') as game_love:
            f.write(game_love.read())
    
    # Cleanup
    os.remove('build/love.exe')
    os.remove('build/game.love')
    
    print("\nBuild erfolgreich erstellt!")
    print("Die ausführbare Datei befindet sich im 'build' Ordner")
    print("Hinweis: Alle DLL-Dateien müssen zusammen mit game.exe bleiben")

if __name__ == '__main__':
    try:
        create_windows_build()
    except Exception as e:
        print(f"Fehler beim Erstellen des Builds: {e}")
    
    input("\nDrücke Enter zum Beenden...") 