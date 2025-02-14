function love.load()
    -- Konstanten
    WIDTH = 800
    HEIGHT = 600
    ACCELERATION = 300
    ROTATION_SPEED = 5
    FRICTION = 0.99
    MAX_ASTEROIDS = 5
    DIFFICULTY_INCREASE_TIME = 10  -- Sekunden
    difficulty_timer = 0  -- Hier initialisieren!
    COLLISION_CHECK_INTERVAL = 0.05  -- Alle 50ms statt jeden Frame
    collision_timer = 0
    
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
    thrusterParticles = {}  -- Neue Liste für Thruster-Partikel
    
    -- Score
    score = 0
    highscore = loadHighscore()
    
    -- Sounds laden und optimieren
    sounds = {
        shoot = love.audio.newSource("shoot.wav", "static"),
        explosion = love.audio.newSource("explosion.wav", "static")
    }
    
    -- Ein Schuss-Sound, lauter
    sounds.shoot:setVolume(1.0)
    
    -- Explosions-Pool mit besseren Einstellungen
    soundPool = {
        explosion = {}
    }
    
    -- Explosionen im Pool
    for i = 1, 3 do
        local explosion = sounds.explosion:clone()
        explosion:setVolume(0.9)  -- Lauter
        explosion:setPitch(0.8 + i * 0.1)  -- Tiefere Basis-Frequenz
        soundPool.explosion[i] = explosion
    end
    
    -- Spiel starten
    resetGame()
end

function love.update(dt)
    if gameState == "game" then
        updatePlayer(dt)
        updateBullets(dt)
        updateAsteroids(dt)
        updateParticles(dt)
        updateThrusterParticles(dt)
        
        -- Kollisionen nur alle 50ms prüfen
        collision_timer = collision_timer + dt
        if collision_timer >= COLLISION_CHECK_INTERVAL then
            checkCollisions()
            collision_timer = 0
        end
        
        -- Schwierigkeit erhöhen
        difficulty_timer = difficulty_timer + dt
        if difficulty_timer >= DIFFICULTY_INCREASE_TIME then
            difficulty_timer = 0
            MAX_ASTEROIDS = MAX_ASTEROIDS + 1
        end
        
        -- Asteroiden nachspawnen
        if #asteroids < MAX_ASTEROIDS then
            -- Spawn an Bildschirmrand
            local side = math.random(1, 4)
            local x, y
            if side == 1 then     -- oben
                x = math.random(0, WIDTH)
                y = -50
            elseif side == 2 then -- rechts
                x = WIDTH + 50
                y = math.random(0, HEIGHT)
            elseif side == 3 then -- unten
                x = math.random(0, WIDTH)
                y = HEIGHT + 50
            else                  -- links
                x = -50
                y = math.random(0, HEIGHT)
            end
            
            -- Richtung zur Mitte mit Zufallsabweichung
            local angle = math.atan2(HEIGHT/2 - y, WIDTH/2 - x)
            angle = angle + math.random(-0.5, 0.5)
            local speed = math.random(50, 150)
            
            local asteroid = {
                x = x,
                y = y,
                dx = math.cos(angle) * speed,
                dy = math.sin(angle) * speed,
                radius = 40,
                angle = 0,
                spin = math.random(-3, 3),
                points = generateAsteroidPoints(40)
            }
            
            -- Stelle sicher, dass neue Asteroiden nicht direkt auf dem Spieler spawnen
            if x == nil and y == nil then
                local dx = asteroid.x - player.x
                local dy = asteroid.y - player.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist < 100 then  -- Zu nah am Spieler
                    asteroid.x = (asteroid.x + WIDTH/2) % WIDTH
                    asteroid.y = (asteroid.y + HEIGHT/2) % HEIGHT
                end
            end
            
            table.insert(asteroids, asteroid)
        end
    end
end

function love.draw()
    if gameState == "menu" then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("ASTEROIDS", WIDTH/2-100, HEIGHT/3, 0, 3, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Press SPACE to start", WIDTH/2-80, HEIGHT/2)
        
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
        
        -- Thruster-Partikel zeichnen (vor dem Schiff)
        for _, p in ipairs(thrusterParticles) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3])
            love.graphics.circle("fill", p.x, p.y, p.size)
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
        love.graphics.print("Press SPACE to restart", WIDTH/2-80, HEIGHT/2+60)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    if key == "space" then
        if gameState == "menu" then
            -- Space startet das Spiel
            gameState = "game"
            resetGame()
        elseif gameState == "game" then
            -- Space schießt während des Spiels
            shoot()
        elseif gameState == "gameover" then
            -- Space startet neue Runde
            gameState = "game"
            resetGame()
        end
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
        
        -- Thruster-Partikel erzeugen
        if math.random() < 0.3 then  -- 30% Chance pro Frame
            createThrusterParticle()
        end
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
        -- Bewegung
        asteroid.x = asteroid.x + asteroid.dx * dt
        asteroid.y = asteroid.y + asteroid.dy * dt
        asteroid.angle = asteroid.angle + asteroid.spin * dt
        
        -- Unverwundbarkeit reduzieren
        if asteroid.invulnerable and asteroid.invulnerable > 0 then
            asteroid.invulnerable = asteroid.invulnerable - dt
        end
        
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

function updateThrusterParticles(dt)
    for i = #thrusterParticles, 1, -1 do
        local p = thrusterParticles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.lifetime = p.lifetime - dt
        p.size = p.size * 0.95
        
        -- Verblassen
        p.color[1] = p.color[1] * 0.95  -- Rot
        p.color[2] = p.color[2] * 0.95  -- Grün
        
        if p.lifetime <= 0 then
            table.remove(thrusterParticles, i)
        end
    end
end

function playSound(soundType)
    if soundType == "shoot" then
        sounds.shoot:stop()
        sounds.shoot:play()
    else
        -- Finde freien Explosions-Sound
        for _, sound in ipairs(soundPool.explosion) do
            if not sound:isPlaying() then
                sound:play()
                return
            end
        end
        -- Wenn alle belegt, nutze den ersten
        soundPool.explosion[1]:play()
    end
end

function shoot()
    local bullet = {
        x = player.x + math.cos(player.angle) * 20,
        y = player.y + math.sin(player.angle) * 20,
        dx = math.cos(player.angle) * 500,
        dy = math.sin(player.angle) * 500,
        lifetime = 1.5
    }
    table.insert(bullets, bullet)
    playSound("shoot")
end

function createAsteroid(size, x, y, invulnerable)
    local asteroid = {
        x = x or math.random(0, WIDTH),
        y = y or math.random(0, HEIGHT),
        dx = math.random(-100, 100),
        dy = math.random(-100, 100),
        radius = size or 40,
        angle = 0,
        spin = math.random(-3, 3),
        points = generateAsteroidPoints(size or 40),
        invulnerable = invulnerable or 0  -- Zeit in Sekunden
    }
    
    -- Stelle sicher, dass neue Asteroiden nicht direkt auf dem Spieler spawnen
    if x == nil and y == nil then
        local dx = asteroid.x - player.x
        local dy = asteroid.y - player.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < 100 then
            asteroid.x = (asteroid.x + WIDTH/2) % WIDTH
            asteroid.y = (asteroid.y + HEIGHT/2) % HEIGHT
        end
    end
    
    table.insert(asteroids, asteroid)
end

function createExplosion(x, y)
    for i = 1, 5 do  -- Von 10 auf 5 reduziert
        local particle = {
            x = x,
            y = y,
            dx = math.random(-150, 150),  -- Etwas langsamer
            dy = math.random(-150, 150),
            size = math.random(2, 3),     -- Kleinere Partikel
            lifetime = math.random(0.3, 0.6)  -- Kürzere Lebensdauer
        }
        table.insert(particles, particle)
    end
    playSound("explosion")
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
    -- Unverwundbare Asteroiden blinken
    if asteroid.invulnerable and asteroid.invulnerable > 0 then
        if math.floor(asteroid.invulnerable * 10) % 2 == 0 then
            love.graphics.setColor(0.5, 0.5, 1.0)  -- Bläulich wenn unverwundbar
        else
            love.graphics.setColor(1, 0.5, 0.5)  -- Normal
        end
    else
        love.graphics.setColor(1, 0.5, 0.5)  -- Normal
    end
    
    local vertices = {}
    for _, point in ipairs(asteroid.points) do
        local x = point[1]
        local y = point[2]
        
        -- Nur Rotation, keine Verformung mehr
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
            local distSq = dx*dx + dy*dy
            local radiusSq = asteroid.radius * asteroid.radius
            
            if distSq < radiusSq then  -- Keine Unverwundbarkeits-Prüfung hier
                createExplosion(asteroid.x, asteroid.y)
                table.remove(bullets, i)
                table.remove(asteroids, j)
                score = score + 100
                
                -- Neue Asteroiden sind NICHT unverwundbar bei Schuss-Teilung
                if asteroid.radius > 20 then
                    for _ = 1, 2 do
                        createAsteroid(asteroid.radius/2, asteroid.x, asteroid.y)  -- Kein invulnerable Parameter
                    end
                end
                break
            end
        end
    end

    -- Asteroiden gegen Asteroiden (mit Unverwundbarkeit)
    local i = 1
    while i <= #asteroids do
        local a1 = asteroids[i]
        local j = i + 1
        local collision = false
        
        while j <= #asteroids do
            local a2 = asteroids[j]
            local dx = a1.x - a2.x
            local dy = a1.y - a2.y
            local distSq = dx*dx + dy*dy
            local minDistSq = (a1.radius + a2.radius) * (a1.radius + a2.radius)
            
            -- Unverwundbarkeits-Prüfung nur bei Asteroid-Asteroid Kollision
            if distSq < minDistSq and 
               a1.invulnerable <= 0 and a2.invulnerable <= 0 then
                local midX = (a1.x + a2.x) / 2
                local midY = (a1.y + a2.y) / 2
                createExplosion(midX, midY)
                
                -- Neue Asteroiden sind unverwundbar bei Kollisions-Teilung
                local newSize = math.max(a1.radius * 0.5, 10)
                for _ = 1, 2 do
                    createAsteroid(newSize, midX, midY, 1.0)  -- 1 Sekunde unverwundbar
                end
                
                score = score + 50
                table.remove(asteroids, j)
                table.remove(asteroids, i)
                collision = true
                break
            end
            j = j + 1
        end
        
        if not collision then
            i = i + 1
        end
    end
    
    -- Spieler gegen Asteroiden (optimiert)
    for _, asteroid in ipairs(asteroids) do
        local dx = player.x - asteroid.x
        local dy = player.y - asteroid.y
        local distSq = dx*dx + dy*dy
        local minDistSq = (asteroid.radius + player.radius) * (asteroid.radius + player.radius)
        
        if distSq < minDistSq then
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
    thrusterParticles = {}  -- Neue Liste leeren
    score = 0
    difficulty_timer = 0  -- Hier auch zurücksetzen!
    MAX_ASTEROIDS = 5    -- Zurück zum Startwert
    
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

function createThrusterParticle()
    -- Position am Heck des Schiffs
    local backX = player.x - math.cos(player.angle) * 15
    local backY = player.y - math.sin(player.angle) * 15
    
    -- Zufällige Abweichung
    local spread = 0.5
    local angle = player.angle + math.pi + math.random(-spread, spread)
    local speed = math.random(50, 150)
    
    local particle = {
        x = backX,
        y = backY,
        dx = math.cos(angle) * speed,
        dy = math.sin(angle) * speed,
        lifetime = 0.5,
        size = math.random(1, 3),
        color = {1, 0.5, 0}  -- Orange
    }
    table.insert(thrusterParticles, particle)
end 