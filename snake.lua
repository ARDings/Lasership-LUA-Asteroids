function love.load()
    -- Konstanten
    GRID_SIZE = 20
    CELL_SIZE = 30
    WIDTH = GRID_SIZE * CELL_SIZE
    HEIGHT = GRID_SIZE * CELL_SIZE
    
    -- Spielzustände
    gameState = "menu"  -- menu, game, gameover
    
    -- Snake initialisieren
    snake = {
        x = math.floor(GRID_SIZE/2),
        y = math.floor(GRID_SIZE/2),
        dx = 1,
        dy = 0,
        body = {},
        length = 1
    }
    
    -- Futter
    food = {
        x = love.math.random(0, GRID_SIZE-1),
        y = love.math.random(0, GRID_SIZE-1)
    }
    
    -- Score
    score = 0
    highscore = loadHighscore()
    
    -- Timer für Bewegung
    moveTimer = 0
    moveDelay = 0.1  -- Geschwindigkeit
end

function love.update(dt)
    if gameState == "game" then
        moveTimer = moveTimer + dt
        if moveTimer >= moveDelay then
            moveTimer = 0
            
            -- Alte Position speichern
            table.insert(snake.body, 1, {x = snake.x, y = snake.y})
            while #snake.body > snake.length do
                table.remove(snake.body)
            end
            
            -- Neue Position
            snake.x = snake.x + snake.dx
            snake.y = snake.y + snake.dy
            
            -- Wrap-around
            if snake.x >= GRID_SIZE then snake.x = 0 end
            if snake.x < 0 then snake.x = GRID_SIZE-1 end
            if snake.y >= GRID_SIZE then snake.y = 0 end
            if snake.y < 0 then snake.y = GRID_SIZE-1 end
            
            -- Kollision mit sich selbst
            for i, segment in ipairs(snake.body) do
                if snake.x == segment.x and snake.y == segment.y then
                    gameState = "gameover"
                    if score > highscore then
                        highscore = score
                        saveHighscore(highscore)
                    end
                end
            end
            
            -- Futter essen
            if snake.x == food.x and snake.y == food.y then
                snake.length = snake.length + 1
                score = score + 100
                -- Neues Futter
                repeat
                    food.x = love.math.random(0, GRID_SIZE-1)
                    food.y = love.math.random(0, GRID_SIZE-1)
                    local valid = true
                    for _, segment in ipairs(snake.body) do
                        if food.x == segment.x and food.y == segment.y then
                            valid = false
                            break
                        end
                    end
                until valid
            end
        end
    end
end

function love.draw()
    if gameState == "menu" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("SNAKE", WIDTH/2-50, HEIGHT/3, 0, 2, 2)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Press ENTER to start", WIDTH/2-80, HEIGHT/2)
        love.graphics.print("Arrow keys to move", WIDTH/2-70, HEIGHT/2+30)
        
    elseif gameState == "game" then
        -- Schlange zeichnen
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", snake.x*CELL_SIZE, snake.y*CELL_SIZE, CELL_SIZE-1, CELL_SIZE-1)
        for _, segment in ipairs(snake.body) do
            love.graphics.rectangle("fill", segment.x*CELL_SIZE, segment.y*CELL_SIZE, CELL_SIZE-1, CELL_SIZE-1)
        end
        
        -- Futter zeichnen
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", food.x*CELL_SIZE, food.y*CELL_SIZE, CELL_SIZE-1, CELL_SIZE-1)
        
        -- Score
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, 10, 10)
        
    elseif gameState == "gameover" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("GAME OVER", WIDTH/2-50, HEIGHT/3, 0, 2, 2)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, WIDTH/2-30, HEIGHT/2)
        love.graphics.print("Highscore: " .. highscore, WIDTH/2-50, HEIGHT/2+30)
        love.graphics.print("Press ENTER to restart", WIDTH/2-80, HEIGHT/2+60)
    end
end

function love.keypressed(key)
    if gameState == "menu" and key == "return" then
        gameState = "game"
    elseif gameState == "game" then
        if key == "up" and snake.dy == 0 then
            snake.dx = 0
            snake.dy = -1
        elseif key == "down" and snake.dy == 0 then
            snake.dx = 0
            snake.dy = 1
        elseif key == "left" and snake.dx == 0 then
            snake.dx = -1
            snake.dy = 0
        elseif key == "right" and snake.dx == 0 then
            snake.dx = 1
            snake.dy = 0
        end
    elseif gameState == "gameover" and key == "return" then
        -- Reset
        snake.x = math.floor(GRID_SIZE/2)
        snake.y = math.floor(GRID_SIZE/2)
        snake.dx = 1
        snake.dy = 0
        snake.body = {}
        snake.length = 1
        score = 0
        gameState = "game"
    end
end

function loadHighscore()
    local file = io.open("highscore.txt", "r")
    if file then
        local score = tonumber(file:read("*all"))
        file:close()
        return score or 0
    end
    return 0
end

function saveHighscore(score)
    local file = io.open("highscore.txt", "w")
    if file then
        file:write(tostring(score))
        file:close()
    end
end 