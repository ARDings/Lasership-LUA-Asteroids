import pygame
import math
import random
import sys
import signal
import psutil
import subprocess

pygame.init()

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
    font = pygame.font.SysFont(None, size)
    return font.render(text, True, color)

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

def get_gpu_temp():
    try:
        # vcgencmd liefert z. B. "temp=48.0'C\n"
        temp_str = subprocess.check_output(["vcgencmd", "measure_temp"]).decode()
        temp_val = temp_str.replace("temp=", "").replace("'C\n", "")
        return float(temp_val)
    except Exception:
        return None

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

    def update(self):
        self.pos += self.vel
        if self.pos.x < 0: self.pos.x = WIDTH
        if self.pos.x > WIDTH: self.pos.x = 0
        if self.pos.y < 0: self.pos.y = HEIGHT
        if self.pos.y > HEIGHT: self.pos.y = 0

    def draw(self, surface):
        transformed_points = [(self.pos.x + p[0], self.pos.y + p[1]) for p in self.points]
        pygame.draw.polygon(surface, COLOR_ASTEROID, transformed_points)

    def get_radius(self):
        return self.radius

class Particle:
    def __init__(self, pos):
        self.pos = pygame.Vector2(pos)
        angle = random.uniform(0, 2 * math.pi)
        speed = random.uniform(1, 3)
        self.vel = pygame.Vector2(math.cos(angle), math.sin(angle)) * speed
        self.life = random.randint(20, 40)

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

def start_game():
    global spaceship, asteroids, bullets, particles, player_lives
    spaceship = Spaceship(WIDTH // 2, HEIGHT // 2)
    asteroids = [Asteroid() for _ in range(5)]
    bullets = []
    particles = []
    player_lives = 3

def create_explosion(pos, num_particles=10):
    for _ in range(num_particles):
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

    # Leben anzeigen
    life_text = f"Lives: {player_lives}"
    life_rendered = render_text(life_text, 24)
    screen.blit(life_rendered, (10, 10))

    # Metriken oben rechts anzeigen: FPS, CPU-Auslastung und GPU-Temperatur
    cpu_usage = psutil.cpu_percent(interval=None)
    gpu_temp = get_gpu_temp()
    metrics_lines = [
        f"FPS: {int(clock.get_fps())}",
        f"CPU: {cpu_usage}%",
    ]
    if gpu_temp is not None:
        metrics_lines.append(f"GPU Temp: {gpu_temp}°C")
    y_offset = 0
    for line in metrics_lines:
        line_surf = render_text(line, 20)
        screen.blit(line_surf, (WIDTH - line_surf.get_width() - 10, 10 + y_offset))
        y_offset += line_surf.get_height()

    pygame.display.flip()

pygame.quit()
sys.exit()
