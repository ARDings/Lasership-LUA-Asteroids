function love.load()
    -- Konstanten
    WIDTH = 800
    HEIGHT = 600
    ACCELERATION = 300
    ROTATION_SPEED = 5
    FRICTION = 0.99
    MAX_ASTEROIDS = 5
    
    -- Spielzustände
    gameState = "menu"  -- menu, game, gameover
    
    -- Spieler
    player = {
        x = WIDTH/2,
        y = HEIGHT/2,
        dx = 0,
        dy = 0,
        angle = 0,
        radius = 15,
        points = generateShipPoints(),
        lives = 3
    }
    
    -- Listen für Spielobjekte
    bullets = {}
    asteroids = {}
    particles = {}
    
    -- Score
    score = 0
    highscore = loadHighscore()
    
    -- Sounds laden
    sounds = {
        shoot = love.audio.newSource("shoot.wav", "static"),
        explosion = love.audio.newSource("explosion.wav", "static")
    }
    
    -- Spiel starten
    resetGame()
end

function love.update(dt)
    if gameState == "game" then
        updatePlayer(dt)
        updateBullets(dt)
        updateAsteroids(dt)
        updateParticles(dt)
        checkCollisions()
    end
end

function love.draw()
    if gameState == "menu" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("ASTEROIDS", WIDTH/2-100, HEIGHT/3, 0, 3, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Press ENTER to start", WIDTH/2-80, HEIGHT/2)
        
    elseif gameState == "game" then
        -- Spieler zeichnen
        drawPlayer()
        
        -- Asteroiden zeichnen
        for _, asteroid in ipairs(asteroids) do
            drawAsteroid(asteroid)
        end
        
        -- Schüsse zeichnen
        for _, bullet in ipairs(bullets) do
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", bullet.x, bullet.y, 2)
        end
        
        -- Partikel zeichnen
        for _, particle in ipairs(particles) do
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.circle("fill", particle.x, particle.y, particle.size)
        end
        
        -- HUD
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, 10, 10)
        love.graphics.print("Lives: " .. player.lives, 10, 30)
        
    elseif gameState == "gameover" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("GAME OVER", WIDTH/2-100, HEIGHT/3, 0, 3, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, WIDTH/2-30, HEIGHT/2)
        love.graphics.print("Highscore: " .. highscore, WIDTH/2-50, HEIGHT/2+30)
        love.graphics.print("Press ENTER to restart", WIDTH/2-80, HEIGHT/2+60)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    if gameState == "menu" and key == "return" then
        gameState = "game"
        resetGame()
    elseif gameState == "game" then
        if key == "space" then
            shoot()
        end
    elseif gameState == "gameover" and key == "return" then
        gameState = "game"
        resetGame()
    end
end

function updatePlayer(dt)
    -- Rotation (Änderung: Winkel in Radiant umrechnen)
    if love.keyboard.isDown("left") then
        player.angle = player.angle - ROTATION_SPEED * dt
    end
    if love.keyboard.isDown("right") then
        player.angle = player.angle + ROTATION_SPEED * dt
    end
    
    -- Schub (Änderung: Bewegung immer in Richtung der Spitze)
    if love.keyboard.isDown("up") then
        -- Richtungsvektor basierend auf der Rotation
        local thrust_x = math.cos(player.angle) * ACCELERATION * dt
        local thrust_y = math.sin(player.angle) * ACCELERATION * dt
        player.dx = player.dx + thrust_x
        player.dy = player.dy + thrust_y
    end
    
    -- Bewegung und Reibung
    player.dx = player.dx * FRICTION
    player.dy = player.dy * FRICTION
    player.x = player.x + player.dx * dt
    player.y = player.y + player.dy * dt
    
    -- Bildschirmgrenzen
    if player.x < 0 then player.x = WIDTH end
    if player.x > WIDTH then player.x = 0 end
    if player.y < 0 then player.y = HEIGHT end
    if player.y > HEIGHT then player.y = 0 end
end

function updateBullets(dt)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.x = bullet.x + bullet.dx * dt
        bullet.y = bullet.y + bullet.dy * dt
        bullet.lifetime = bullet.lifetime - dt
        
        -- Bildschirmgrenzen
        if bullet.x < 0 then bullet.x = WIDTH end
        if bullet.x > WIDTH then bullet.x = 0 end
        if bullet.y < 0 then bullet.y = HEIGHT end
        if bullet.y > HEIGHT then bullet.y = 0 end
        
        if bullet.lifetime <= 0 then
            table.remove(bullets, i)
        end
    end
end

function updateAsteroids(dt)
    for _, asteroid in ipairs(asteroids) do
        asteroid.x = asteroid.x + asteroid.dx * dt
        asteroid.y = asteroid.y + asteroid.dy * dt
        asteroid.angle = asteroid.angle + asteroid.spin * dt
        
        -- Bildschirmgrenzen
        if asteroid.x < 0 then asteroid.x = WIDTH end
        if asteroid.x > WIDTH then asteroid.x = 0 end
        if asteroid.y < 0 then asteroid.y = HEIGHT end
        if asteroid.y > HEIGHT then asteroid.y = 0 end
    end
end

function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.lifetime = p.lifetime - dt
        p.size = p.size * 0.95
        
        if p.lifetime <= 0 then
            table.remove(particles, i)
        end
    end
end

function shoot()
    -- Änderung: Schuss startet an der Spitze und fliegt in deren Richtung
    local bullet = {
        x = player.x + math.cos(player.angle) * 20,  -- Offset von der Schiffsmitte
        y = player.y + math.sin(player.angle) * 20,
        dx = math.cos(player.angle) * 500,  -- Geschwindigkeit in Richtung der Spitze
        dy = math.sin(player.angle) * 500,
        lifetime = 1.5
    }
    table.insert(bullets, bullet)
    sounds.shoot:play()
end

function createAsteroid(size, x, y)
    local asteroid = {
        x = x or math.random(0, WIDTH),
        y = y or math.random(0, HEIGHT),
        dx = math.random(-100, 100),
        dy = math.random(-100, 100),
        radius = size or 40,
        angle = 0,
        spin = math.random(-3, 3),
        points = generateAsteroidPoints(size or 40)
    }
    table.insert(asteroids, asteroid)
end

function createExplosion(x, y)
    for i = 1, 10 do
        local particle = {
            x = x,
            y = y,
            dx = math.random(-200, 200),
            dy = math.random(-200, 200),
            size = math.random(2, 4),
            lifetime = math.random(0.5, 1)
        }
        table.insert(particles, particle)
    end
    sounds.explosion:play()
end

function generateShipPoints()
    -- Änderung: Schiff zeigt nach rechts (0°) als Basis
    return {
        {15, 0},    -- Spitze
        {-15, -10}, -- Links hinten
        {-10, 0},   -- Mitte hinten
        {-15, 10}   -- Rechts hinten
    }
end

function generateAsteroidPoints(radius)
    local points = {}
    local numPoints = 5  -- Fünfeck
    for i = 1, numPoints do
        local angle = (i-1) * 2 * math.pi / numPoints
        local dist = radius * (0.8 + math.random() * 0.4)
        table.insert(points, {
            math.cos(angle) * dist,
            math.sin(angle) * dist
        })
    end
    return points
end

function drawPlayer()
    love.graphics.setColor(0, 1, 1)  -- Cyan
    local vertices = {}
    for _, point in ipairs(player.points) do
        local x = point[1]
        local y = point[2]
        -- Rotation um Ursprung
        local rotated_x = x * math.cos(player.angle) - y * math.sin(player.angle)
        local rotated_y = x * math.sin(player.angle) + y * math.cos(player.angle)
        table.insert(vertices, player.x + rotated_x)
        table.insert(vertices, player.y + rotated_y)
    end
    love.graphics.polygon("line", vertices)
end

function drawAsteroid(asteroid)
    love.graphics.setColor(1, 0.5, 0.5)  -- Rosa
    local vertices = {}
    for _, point in ipairs(asteroid.points) do
        local x = point[1]
        local y = point[2]
        local rotated_x = x * math.cos(asteroid.angle) - y * math.sin(asteroid.angle)
        local rotated_y = x * math.sin(asteroid.angle) + y * math.cos(asteroid.angle)
        table.insert(vertices, asteroid.x + rotated_x)
        table.insert(vertices, asteroid.y + rotated_y)
    end
    love.graphics.polygon("line", vertices)
end

function checkCollisions()
    -- Schüsse gegen Asteroiden
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        for j = #asteroids, 1, -1 do
            local asteroid = asteroids[j]
            local dx = bullet.x - asteroid.x
            local dy = bullet.y - asteroid.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist < asteroid.radius then
                createExplosion(asteroid.x, asteroid.y)
                table.remove(bullets, i)
                table.remove(asteroids, j)
                score = score + 100
                
                -- Kleinere Asteroiden erzeugen
                if asteroid.radius > 20 then
                    for _ = 1, 2 do
                        createAsteroid(asteroid.radius/2, asteroid.x, asteroid.y)
                    end
                end
                
                break
            end
        end
    end
    
    -- Spieler gegen Asteroiden
    for _, asteroid in ipairs(asteroids) do
        local dx = player.x - asteroid.x
        local dy = player.y - asteroid.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        if dist < asteroid.radius + player.radius then
            createExplosion(player.x, player.y)
            player.lives = player.lives - 1
            player.x = WIDTH/2
            player.y = HEIGHT/2
            player.dx = 0
            player.dy = 0
            
            if player.lives <= 0 then
                gameState = "gameover"
                if score > highscore then
                    highscore = score
                    saveHighscore(score)
                end
            end
            break
        end
    end
end

function resetGame()
    player.x = WIDTH/2
    player.y = HEIGHT/2
    player.dx = 0
    player.dy = 0
    player.angle = 0
    player.lives = 3
    
    bullets = {}
    asteroids = {}
    particles = {}
    score = 0
    
    -- Anfangsasteroiden erstellen
    for i = 1, MAX_ASTEROIDS do
        createAsteroid()
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