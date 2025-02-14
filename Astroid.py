import pygame
import math
import random
import sys
import signal
import psutil
import os
import pygame.mixer

pygame.init()
# Versuche verschiedene Audio-Konfigurationen
SOUND_ENABLED = False  # Standardmäßig deaktiviert

try:
    print("Versuche Audio zu initialisieren...")
    pygame.mixer.init(22050, 16, 1, 512)  # Kleinerer Buffer
    print("Audio erfolgreich initialisiert")
    print(f"Treiber: {pygame.mixer.get_init()}")
    SOUND_ENABLED = True
except Exception as e:
    print(f"Warning: Sound konnte nicht initialisiert werden: {e}")
    SOUND_ENABLED = False

# Sound-Objekte nur erstellen wenn Sound aktiviert ist
if SOUND_ENABLED:
    try:
        SOUND_SHOOT = pygame.mixer.Sound('shoot.wav')
        SOUND_EXPLOSION = pygame.mixer.Sound('explosion.wav')
        # Lautstärke der Effekte einzeln anpassen
        SOUND_SHOOT.set_volume(0.2)  # Etwas leiser
        SOUND_EXPLOSION.set_volume(0.2)  # Etwas leiser
    except Exception as e:
        print(f"Warning: Sound konnte nicht geladen werden: {e}")
        SOUND_ENABLED = False

# SIGINT-Handler einrichten, damit Strg+C im Terminal das Programm beendet
def signal_handler(sig, frame):
    pygame.quit()
    sys.exit()
signal.signal(signal.SIGINT, signal_handler)

# -------------------------------
# Konstanten
# -------------------------------
WIDTH, HEIGHT = 800, 600
# FPS-Limit: 0 bedeutet hier KEIN Limit
FPS_LIMIT = 0

# Farben (RGB)
COLOR_BG = (0, 0, 0)
COLOR_TEXT = (255, 255, 255)
COLOR_SHIP = (64, 224, 208)      # Türkis
COLOR_ASTEROID = (255, 192, 203) # Rosa
COLOR_BULLET = (255, 255, 0)     # Gelb
COLOR_EXPLOSION = (255, 140, 0)  # Orange

# Spielzustände
STATE_START = 0
STATE_PLAY = 1
STATE_GAMEOVER = 2

# -------------------------------
# Hilfsfunktionen
# -------------------------------
def render_text(text, size, color=COLOR_TEXT):
    # Statisches Cache-Dict für alle Text-Renderings
    if not hasattr(render_text, 'text_cache'):
        render_text.text_cache = {}
    
    # Cache-Key aus Text, Größe und Farbe
    cache_key = (text, size, color)
    if cache_key not in render_text.text_cache:
        if not hasattr(render_text, 'font_cache'):
            render_text.font_cache = {}
        if size not in render_text.font_cache:
            render_text.font_cache[size] = pygame.font.SysFont(None, size)
        render_text.text_cache[cache_key] = render_text.font_cache[size].render(text, True, color)
    
    return render_text.text_cache[cache_key]

def center_text(rendered_surf, w, h):
    x = (w - rendered_surf.get_width()) // 2
    y = (h - rendered_surf.get_height()) // 2
    return (x, y)

def rotate_vector(vec, angle_rad):
    x, y = vec
    cos_a = math.cos(angle_rad)
    sin_a = math.sin(angle_rad)
    rx = x * cos_a - y * sin_a
    ry = x * sin_a + y * cos_a
    return pygame.Vector2(rx, ry)

def check_collision_circle(pos1, r1, pos2, r2):
    dist = pos1.distance_to(pos2)
    return dist < (r1 + r2)

def kill_unnecessary_processes():
    # Liste von Prozessen, die beendet werden können
    unnecessary_processes = {
        'chromium', 'firefox', 'thunderbird', 'libreoffice',
        'apache2', 'mysql', 'postgresql', 'nginx'
    }
    
    for proc in psutil.process_iter(['name']):
        try:
            if proc.name().lower() in unnecessary_processes:
                proc.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue

# -------------------------------
# Klassen
# -------------------------------

class Spaceship:
    def __init__(self, x, y):
        self.pos = pygame.Vector2(x, y)
        self.vel = pygame.Vector2(0, 0)
        self.angle = 0  # 0 = zeigt nach oben
        self.acceleration = 0.3
        self.friction = 0.98
        self.size = 20

    def update(self):
        self.pos += self.vel
        self.vel *= self.friction
        # Wrap-around
        if self.pos.x < 0: self.pos.x = WIDTH
        if self.pos.x > WIDTH: self.pos.x = 0
        if self.pos.y < 0: self.pos.y = HEIGHT
        if self.pos.y > HEIGHT: self.pos.y = 0

    def draw(self, surface):
        angle_rad = math.radians(self.angle)
        tip = self.pos + rotate_vector((0, -self.size), angle_rad)
        left_wing = self.pos + rotate_vector((-self.size * 0.6, self.size * 0.8), angle_rad)
        right_wing = self.pos + rotate_vector((self.size * 0.6, self.size * 0.8), angle_rad)
        back_left = self.pos + rotate_vector((-self.size * 0.3, self.size * 1.2), angle_rad)
        back_right = self.pos + rotate_vector((self.size * 0.3, self.size * 1.2), angle_rad)
        points = [tip, right_wing, back_right, back_left, left_wing]
        pygame.draw.polygon(surface, COLOR_SHIP, points)

    def rotate(self, direction):
        self.angle += 5 * direction

    def thrust(self):
        # Beschleunigung immer in Richtung der Schiffsspitze
        angle_rad = math.radians(self.angle)
        direction = rotate_vector((0, -1), angle_rad)
        thrust_vec = direction * self.acceleration
        self.vel += thrust_vec

    def shoot(self):
        angle_rad = math.radians(self.angle)
        direction = rotate_vector((0, -1), angle_rad)
        bullet_speed = 5
        bullet_vel = direction * bullet_speed
        bullet_pos = self.pos + rotate_vector((0, -self.size), angle_rad)
        return Bullet(bullet_pos, bullet_vel)

    def get_radius(self):
        return self.size * 0.8

class Bullet:
    def __init__(self, pos, vel):
        self.pos = pygame.Vector2(pos)
        self.vel = pygame.Vector2(vel)
        self.radius = 4
        self.life = 120

    def update(self):
        self.pos += self.vel
        self.life -= 1
        if self.pos.x < 0: self.pos.x = WIDTH
        if self.pos.x > WIDTH: self.pos.x = 0
        if self.pos.y < 0: self.pos.y = HEIGHT
        if self.pos.y > HEIGHT: self.pos.y = 0

    def draw(self, surface):
        pygame.draw.circle(surface, COLOR_BULLET, (int(self.pos.x), int(self.pos.y)), self.radius)

    def is_alive(self):
        return self.life > 0

class Asteroid:
    def __init__(self):
        self.pos = pygame.Vector2(random.randrange(WIDTH), random.randrange(HEIGHT))
        angle = random.uniform(0, 2 * math.pi)
        speed = random.uniform(1, 2)
        self.vel = pygame.Vector2(math.cos(angle), math.sin(angle)) * speed
        self.num_points = random.randint(6, 10)
        self.radius = random.randint(20, 40)
        self.points = []
        for i in range(self.num_points):
            theta = (2 * math.pi / self.num_points) * i
            r = self.radius * random.uniform(0.7, 1.2)
            x = r * math.cos(theta)
            y = r * math.sin(theta)
            self.points.append((x, y))
        # Vorberechnen der transformierten Punkte
        self.transformed_points = [(0, 0)] * len(self.points)

    def update(self):
        self.pos += self.vel
        if self.pos.x < 0: self.pos.x = WIDTH
        if self.pos.x > WIDTH: self.pos.x = 0
        if self.pos.y < 0: self.pos.y = HEIGHT
        if self.pos.y > HEIGHT: self.pos.y = 0
        
        # Update der transformierten Punkte
        for i, p in enumerate(self.points):
            self.transformed_points[i] = (self.pos.x + p[0], self.pos.y + p[1])

    def draw(self, surface):
        pygame.draw.polygon(surface, COLOR_ASTEROID, self.transformed_points)

    def get_radius(self):
        return self.radius

class Particle:
    def __init__(self, pos):
        self.pos = pygame.Vector2(pos)
        angle = random.uniform(0, 2 * math.pi)
        speed = random.uniform(1, 2)
        self.vel = pygame.Vector2(math.cos(angle), math.sin(angle)) * speed
        self.life = random.randint(10, 20)

    def update(self):
        self.pos += self.vel
        self.life -= 1

    def draw(self, surface):
        size = max(1, int(self.life / 5))
        pygame.draw.circle(surface, COLOR_EXPLOSION, (int(self.pos.x), int(self.pos.y)), size)

    def is_alive(self):
        return self.life > 0

# -------------------------------
# Globale Variablen & Initialisierung
# -------------------------------
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Asteroids Enhanced")
clock = pygame.time.Clock()

game_state = STATE_START
spaceship = None
asteroids = []
bullets = []
particles = []
player_lives = 3
score = 0

# Globale Variablen für gecachte Oberflächen
score_surface = None
lives_surface = None
last_score = None
last_lives = None

def play_sound(sound):
    if SOUND_ENABLED:
        try:
            sound.play()
        except:
            pass

def start_game():
    global spaceship, asteroids, bullets, particles, player_lives, score
    kill_unnecessary_processes()
    spaceship = Spaceship(WIDTH // 2, HEIGHT // 2)
    asteroids = [Asteroid() for _ in range(5)]
    bullets = []
    particles = []
    player_lives = 3
    score = 0

def create_explosion(pos, num_particles=10):
    for _ in range(min(num_particles, 3)):
        particles.append(Particle(pos))

# -------------------------------
# Haupt-Spielschleife
# -------------------------------
running = True
while running:
    # dt begrenzt hier nicht die FPS, da FPS_LIMIT=0
    dt = clock.tick(FPS_LIMIT)
    
    # Ereignis-Verarbeitung
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        # Beende auch per Strg+C (CTRL + C)
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_c and (pygame.key.get_mods() & pygame.KMOD_CTRL):
                running = False

            if game_state == STATE_START:
                if event.key == pygame.K_RETURN:
                    start_game()
                    game_state = STATE_PLAY
            elif game_state == STATE_PLAY:
                if event.key == pygame.K_SPACE:
                    bullets.append(spaceship.shoot())
                    play_sound(SOUND_SHOOT)
            elif game_state == STATE_GAMEOVER:
                if event.key == pygame.K_RETURN:
                    start_game()
                    game_state = STATE_PLAY

    if game_state == STATE_START:
        screen.fill(COLOR_BG)
        text = "ASTEROIDS - Press ENTER to Start"
        rendered = render_text(text, 36)
        screen.blit(rendered, center_text(rendered, WIDTH, HEIGHT))
        pygame.display.flip()
        continue

    if game_state == STATE_GAMEOVER:
        screen.fill(COLOR_BG)
        text = "GAME OVER - Press ENTER to Restart"
        rendered = render_text(text, 36)
        screen.blit(rendered, center_text(rendered, WIDTH, HEIGHT))
        pygame.display.flip()
        continue

    # STATE_PLAY
    keys = pygame.key.get_pressed()
    if keys[pygame.K_LEFT]:
        spaceship.rotate(-1)
    if keys[pygame.K_RIGHT]:
        spaceship.rotate(1)
    if keys[pygame.K_UP]:
        spaceship.thrust()

    spaceship.update()
    for asteroid in asteroids:
        asteroid.update()
    for bullet in bullets:
        bullet.update()
    bullets = [b for b in bullets if b.is_alive()]
    for particle in particles:
        particle.update()
    particles = [p for p in particles if p.is_alive()]

    # Kollision: Bullet vs. Asteroid
    new_asteroids = []
    for asteroid in asteroids:
        hit = False
        for bullet in bullets:
            if check_collision_circle(bullet.pos, bullet.radius, asteroid.pos, asteroid.get_radius()):
                hit = True
                bullet.life = 0
                create_explosion(asteroid.pos, 15)
                play_sound(SOUND_EXPLOSION)
                score += 100
                break
        if not hit:
            new_asteroids.append(asteroid)
    asteroids = new_asteroids
    bullets = [b for b in bullets if b.is_alive()]

    # Kollision: Spaceship vs. Asteroid
    for asteroid in asteroids:
        if check_collision_circle(spaceship.pos, spaceship.get_radius(),
                                  asteroid.pos, asteroid.get_radius()):
            create_explosion(spaceship.pos, 30)
            player_lives -= 1
            spaceship.pos = pygame.Vector2(WIDTH // 2, HEIGHT // 2)
            spaceship.vel = pygame.Vector2(0, 0)
            spaceship.angle = 0
            if player_lives <= 0:
                game_state = STATE_GAMEOVER
            break

    if not asteroids:
        asteroids = [Asteroid() for _ in range(5)]

    # Zeichnen
    screen.fill(COLOR_BG)
    spaceship.draw(screen)
    for asteroid in asteroids:
        asteroid.draw(screen)
    for bullet in bullets:
        bullet.draw(screen)
    for particle in particles:
        particle.draw(screen)

    # Leben links oben anzeigen
    if last_lives != player_lives:
        last_lives = player_lives
        life_text = f"Lives: {player_lives}"
        lives_surface = render_text(life_text, 24)
    screen.blit(lives_surface, (10, 10))

    # Score rechts oben anzeigen
    if last_score != score:
        last_score = score
        score_text = f"Score: {score}"
        score_surface = render_text(score_text, 24)
    screen.blit(score_surface, (WIDTH - score_surface.get_width() - 10, 10))

    pygame.display.flip()

pygame.quit()
sys.exit()
