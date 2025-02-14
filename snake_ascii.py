import pygame
import random
import time
import json
import os

# Initialisierung
pygame.init()

# Konstanten
CELL_SIZE = 30
GRID_WIDTH = 30
GRID_HEIGHT = 20
WIDTH = GRID_WIDTH * CELL_SIZE
HEIGHT = GRID_HEIGHT * CELL_SIZE
FPS = 100

# Farben
BLACK = (0, 0, 0)
GREEN = (0, 255, 0)
DARK_GREEN = (0, 200, 0)
RED = (255, 0, 0)
WHITE = (255, 255, 255)
YELLOW = (255, 255, 0)

# Richtungen
UP = (0, -1)
DOWN = (0, 1)
LEFT = (-1, 0)
RIGHT = (1, 0)

class Snake:
    def __init__(self):
        self.reset()
    
    def reset(self):
        self.length = 1
        self.positions = [(GRID_WIDTH//2, GRID_HEIGHT//2)]
        self.direction = RIGHT
        self.score = 0
        self.speed = FPS
        
    def update(self):
        cur = self.positions[0]
        x, y = self.direction
        new = ((cur[0] + x) % GRID_WIDTH, (cur[1] + y) % GRID_HEIGHT)
        if new in self.positions[3:]:
            return False
        self.positions.insert(0, new)
        if len(self.positions) > self.length:
            self.positions.pop()
        return True

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
    font = pygame.font.SysFont('Courier', size)
    return font.render(text, True, color)

def draw_cell(surface, x, y, char, color):
    font = pygame.font.SysFont('Courier', CELL_SIZE)
    text = font.render(char, True, color)
    rect = text.get_rect(center=(x * CELL_SIZE + CELL_SIZE//2,
                                y * CELL_SIZE + CELL_SIZE//2))
    surface.blit(text, rect)

def main():
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption('Snake ASCII')
    clock = pygame.time.Clock()
    
    snake = Snake()
    food = Food(snake)
    game_state = "MENU"
    highscore = load_highscore()
    
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                return
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_q:
                    pygame.quit()
                    return
                    
                if game_state == "MENU":
                    if event.key == pygame.K_RETURN:
                        game_state = "GAME"
                        snake.reset()
                        food.randomize_position()
                    elif event.key in [pygame.K_1, pygame.K_2, pygame.K_3]:
                        snake.speed = FPS * (1 + event.key - pygame.K_1)
                        
                elif game_state == "GAME":
                    if event.key == pygame.K_UP and snake.direction != DOWN:
                        snake.direction = UP
                    elif event.key == pygame.K_DOWN and snake.direction != UP:
                        snake.direction = DOWN
                    elif event.key == pygame.K_LEFT and snake.direction != RIGHT:
                        snake.direction = LEFT
                    elif event.key == pygame.K_RIGHT and snake.direction != LEFT:
                        snake.direction = RIGHT
                        
                elif game_state == "GAMEOVER":
                    if event.key == pygame.K_RETURN:
                        game_state = "GAME"
                        snake.reset()
                        food.randomize_position()
        
        screen.fill(BLACK)
        
        if game_state == "MENU":
            title = render_text("SNAKE", CELL_SIZE*2, YELLOW)
            screen.blit(title, (WIDTH//2 - title.get_width()//2, HEIGHT//4))
            
            text = render_text("Press ENTER to Start", CELL_SIZE)
            screen.blit(text, (WIDTH//2 - text.get_width()//2, HEIGHT//2))
            
            diff = render_text("Select Difficulty (1-3)", CELL_SIZE)
            screen.blit(diff, (WIDTH//2 - diff.get_width()//2, HEIGHT*3//4))
            
        elif game_state == "GAME":
            if not snake.update():
                game_state = "GAMEOVER"
                if snake.score > highscore:
                    highscore = snake.score
                    save_highscore(highscore)
                continue
                
            if snake.positions[0] == food.position:
                snake.length += 1
                snake.score += 1
                food.randomize_position()
            
            # Zeichne Schlange
            head = snake.positions[0]
            draw_cell(screen, head[0], head[1], '@', GREEN)
            for x, y in snake.positions[1:]:
                draw_cell(screen, x, y, 'o', DARK_GREEN)
            
            # Zeichne Futter
            fx, fy = food.position
            draw_cell(screen, fx, fy, '*', RED)
            
            # Score
            score_text = render_text(f"Score: {snake.score}", CELL_SIZE)
            screen.blit(score_text, (10, 10))
            
        elif game_state == "GAMEOVER":
            text = render_text("GAME OVER", CELL_SIZE*2, RED)
            screen.blit(text, (WIDTH//2 - text.get_width()//2, HEIGHT//4))
            
            score = render_text(f"Score: {snake.score}", CELL_SIZE)
            screen.blit(score, (WIDTH//2 - score.get_width()//2, HEIGHT//2))
            
            high = render_text(f"Highscore: {highscore}", CELL_SIZE)
            screen.blit(high, (WIDTH//2 - high.get_width()//2, HEIGHT//2 + CELL_SIZE))
            
            restart = render_text("Press ENTER to Restart", CELL_SIZE)
            screen.blit(restart, (WIDTH//2 - restart.get_width()//2, HEIGHT*3//4))
        
        pygame.display.flip()
        clock.tick(snake.speed)

if __name__ == '__main__':
    main()