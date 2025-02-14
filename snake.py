import pygame
import random
import sys
import json
import os

# Initialisierung
pygame.init()
pygame.mixer.init(44100, -16, 1, 512)

# Konstanten
GRID_SIZE = 20
GRID_WIDTH = 30
GRID_HEIGHT = 20
WIDTH = GRID_WIDTH * GRID_SIZE
HEIGHT = GRID_HEIGHT * GRID_SIZE
FPS = 10

# Spielzustände
STATE_MENU = 0
STATE_GAME = 1
STATE_GAMEOVER = 2

# Farben
BLACK = (0, 0, 0)
GREEN = (0, 255, 0)
RED = (255, 0, 0)
WHITE = (255, 255, 255)
YELLOW = (255, 255, 0)

# Richtungen
UP = (0, -1)
DOWN = (0, 1)
LEFT = (-1, 0)
RIGHT = (1, 0)

# Sound-Effekte
try:
    EAT_SOUND = pygame.mixer.Sound('eat.wav')
    CRASH_SOUND = pygame.mixer.Sound('crash.wav')
    EAT_SOUND.set_volume(0.2)
    CRASH_SOUND.set_volume(0.2)
    SOUND_ENABLED = True
except:
    SOUND_ENABLED = False

class Snake:
    def __init__(self):
        self.reset()
    
    def reset(self):
        self.length = 1
        self.positions = [(GRID_WIDTH//2, GRID_HEIGHT//2)]
        self.direction = RIGHT
        self.score = 0
        self.speed = FPS
        
    def get_head_position(self):
        return self.positions[0]
    
    def update(self):
        cur = self.get_head_position()
        x, y = self.direction
        new = ((cur[0] + x) % GRID_WIDTH, (cur[1] + y) % GRID_HEIGHT)
        if new in self.positions[3:]:
            if SOUND_ENABLED:
                CRASH_SOUND.play()
            return False
        self.positions.insert(0, new)
        if len(self.positions) > self.length:
            self.positions.pop()
        return True
    
    def draw(self, surface):
        for i, p in enumerate(self.positions):
            color = GREEN if i == 0 else (0, 200, 0)  # Kopf heller
            pygame.draw.rect(surface, color,
                           (p[0] * GRID_SIZE, p[1] * GRID_SIZE,
                            GRID_SIZE-1, GRID_SIZE-1))

class Food:
    def __init__(self, snake):
        self.snake = snake
        self.position = (0, 0)
        self.randomize_position()
        
    def randomize_position(self):
        while True:
            pos = (random.randint(0, GRID_WIDTH-1),
                  random.randint(0, GRID_HEIGHT-1))
            if pos not in self.snake.positions:
                self.position = pos
                break
    
    def draw(self, surface):
        pygame.draw.rect(surface, RED,
                        (self.position[0] * GRID_SIZE,
                         self.position[1] * GRID_SIZE,
                         GRID_SIZE-1, GRID_SIZE-1))

def load_highscore():
    try:
        with open('snake_highscore.json', 'r') as f:
            return json.load(f)['highscore']
    except:
        return 0

def save_highscore(score):
    with open('snake_highscore.json', 'w') as f:
        json.dump({'highscore': score}, f)

def render_text(text, size, color=WHITE):
    font = pygame.font.SysFont(None, size)
    return font.render(text, True, color)

def main():
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption('Snake')
    clock = pygame.time.Clock()
    
    snake = Snake()
    food = Food(snake)
    game_state = STATE_MENU
    highscore = load_highscore()
    
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_q:
                    pygame.quit()
                    sys.exit()
                    
                if game_state == STATE_MENU:
                    if event.key == pygame.K_RETURN:
                        game_state = STATE_GAME
                    elif event.key in [pygame.K_1, pygame.K_2, pygame.K_3]:
                        if event.key == pygame.K_1:
                            FPS = 8
                        elif event.key == pygame.K_2:
                            FPS = 12
                        elif event.key == pygame.K_3:
                            FPS = 16
                        snake.speed = FPS
                        
                elif game_state == STATE_GAME:
                    if event.key == pygame.K_UP and snake.direction != DOWN:
                        snake.direction = UP
                    elif event.key == pygame.K_DOWN and snake.direction != UP:
                        snake.direction = DOWN
                    elif event.key == pygame.K_LEFT and snake.direction != RIGHT:
                        snake.direction = LEFT
                    elif event.key == pygame.K_RIGHT and snake.direction != LEFT:
                        snake.direction = RIGHT
                        
                elif game_state == STATE_GAMEOVER:
                    if event.key == pygame.K_RETURN:
                        snake.reset()
                        food.randomize_position()
                        game_state = STATE_GAME
        
        screen.fill(BLACK)
        
        if game_state == STATE_MENU:
            title = render_text("SNAKE", 72, YELLOW)
            screen.blit(title, (WIDTH//2 - title.get_width()//2, HEIGHT//4))
            
            text = render_text("Press ENTER to Start", 36)
            screen.blit(text, (WIDTH//2 - text.get_width()//2, HEIGHT//2))
            
            diff = render_text("Select Difficulty (1-3)", 24)
            screen.blit(diff, (WIDTH//2 - diff.get_width()//2, HEIGHT*3//4))
            
        elif game_state == STATE_GAME:
            if not snake.update():
                game_state = STATE_GAMEOVER
                if snake.score > highscore:
                    highscore = snake.score
                    save_highscore(highscore)
                continue
                
            if snake.get_head_position() == food.position:
                snake.length += 1
                snake.score += 1
                if SOUND_ENABLED:
                    EAT_SOUND.play()
                food.randomize_position()
                
            snake.draw(screen)
            food.draw(screen)
            
            # Score anzeigen
            score_text = render_text(f"Score: {snake.score}", 24)
            screen.blit(score_text, (10, 10))
            
        elif game_state == STATE_GAMEOVER:
            text = render_text("GAME OVER", 72, RED)
            screen.blit(text, (WIDTH//2 - text.get_width()//2, HEIGHT//4))
            
            score = render_text(f"Score: {snake.score}", 36)
            screen.blit(score, (WIDTH//2 - score.get_width()//2, HEIGHT//2))
            
            high = render_text(f"Highscore: {highscore}", 36)
            screen.blit(high, (WIDTH//2 - high.get_width()//2, HEIGHT//2 + 50))
            
            restart = render_text("Press ENTER to Restart", 24)
            screen.blit(restart, (WIDTH//2 - restart.get_width()//2, HEIGHT*3//4))
        
        pygame.display.flip()
        clock.tick(snake.speed)

if __name__ == '__main__':
    main() 