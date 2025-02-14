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
    COLLISION_CHECK_INTERVAL = 0.1  -- Längeres Intervall
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
    
    -- Sound-Einstellungen
    sounds.shoot:setVolume(1.0)
    sounds.shoot:setPitch(0.7)
    sounds.explosion:setVolume(1.0)
    sounds.explosion:setPitch(0.5)
    
    -- Spiel starten
    resetGame()
    
    -- Neue Konstanten
    MIN_ASTEROID_SIZE = 20
    MAX_ASTEROIDS_TOTAL = 20  -- Weniger maximale Asteroiden
    MAX_PARTICLES = 30  -- Weniger Partikel
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
        if #asteroids < MAX_ASTEROIDS and #asteroids < MAX_ASTEROIDS_TOTAL then
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
            if particle.color then
                love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3])
            else
                love.graphics.setColor(1, 0.5, 0)
            end
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
    -- Rotation
    if love.keyboard.isDown("left") then
        player.angle = player.angle - ROTATION_SPEED * dt
    end
    if love.keyboard.isDown("right") then
        player.angle = player.angle + ROTATION_SPEED * dt
    end
    
    -- Schub
    if love.keyboard.isDown("up") then
        local thrust_x = math.cos(player.angle) * ACCELERATION * dt
        local thrust_y = math.sin(player.angle) * ACCELERATION * dt
        player.dx = player.dx + thrust_x
        player.dy = player.dy + thrust_y
        
        -- Thruster-Partikel erzeugen
        if math.random() < 0.3 then
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
        -- Einfachere Bewegung ohne Geschwindigkeitsbegrenzung
        asteroid.x = asteroid.x + asteroid.dx * dt
        asteroid.y = asteroid.y + asteroid.dy * dt
        asteroid.angle = asteroid.angle + asteroid.spin * dt
        
        -- Bildschirmgrenzen
        asteroid.x = (asteroid.x + WIDTH) % WIDTH
        asteroid.y = (asteroid.y + HEIGHT) % HEIGHT
    end
end

function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.lifetime = p.lifetime - dt
        
        -- Partikel werden kleiner und verblassen
        p.size = p.size * 0.95
        if p.color then
            p.color[1] = p.color[1] * 0.98  -- Rot langsamer verblassen
            p.color[2] = p.color[2] * 0.95  -- Grün schneller verblassen
        end
        
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
    elseif soundType == "explosion" then
        sounds.explosion:stop()
        sounds.explosion:play()
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
        dx = math.random(-150, 150),  -- Schnellere Bewegung
        dy = math.random(-150, 150),
        radius = size or 40,
        angle = math.random() * math.pi * 2,  -- Zufällige Startrotation
        spin = math.random(-5, 5),  -- Schnellere Rotation
        points = generateAsteroidPoints(size or 40),
        invulnerable = invulnerable or 0
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

function createExplosion(x, y, size)
    -- Mehr Partikel für größere Explosionen, aber mit Limit
    local particleCount = math.min(8, math.floor(size/10))
    
    -- Alte Partikel entfernen wenn zu viele
    while #particles >= MAX_PARTICLES do
        table.remove(particles, 1)
    end
    
    -- Explosions-Partikel in Kreisform
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = math.random(100, 200)
        local particle = {
            x = x,
            y = y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed,
            size = math.random(2, 4),
            lifetime = 0.3,
            -- Zufällig zwischen den beiden Farben wechseln
            color = math.random() > 0.5 
                and {0.851, 0.349, 0.624}  -- Rosa
                or {0.686, 0.875, 0.055}   -- Neon-Grün
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
    -- Unverwundbare Asteroiden in Neon-Grün
    if asteroid.invulnerable and asteroid.invulnerable > 0 then
        if math.floor(asteroid.invulnerable * 10) % 2 == 0 then
            -- Konvertiere Hex #afdf0e zu RGB (175/255, 223/255, 14/255)
            love.graphics.setColor(0.686, 0.875, 0.055)  -- Neon-Grün
        else
            -- Konvertiere Hex #d9599f zu RGB (217/255, 89/255, 159/255)
            love.graphics.setColor(0.851, 0.349, 0.624)  -- Rosa
        end
    else
        -- Normale Asteroiden in Rosa (#d9599f)
        love.graphics.setColor(0.851, 0.349, 0.624)
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
            local hitRadius = math.max(asteroid.radius, 15)
            local radiusSq = hitRadius * hitRadius
            
            if distSq < radiusSq then
                createExplosion(asteroid.x, asteroid.y, asteroid.radius)
                table.remove(bullets, i)
                table.remove(asteroids, j)
                score = score + 100
                
                -- Weniger neue Asteroiden
                if asteroid.radius >= MIN_ASTEROID_SIZE and #asteroids < MAX_ASTEROIDS_TOTAL - 1 then
                    local newSize = asteroid.radius * 0.7
                    createAsteroid(newSize, asteroid.x, asteroid.y)  -- Nur ein neuer Asteroid
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
            
            -- Sichere Unverwundbarkeits-Prüfung
            local a1_vulnerable = not a1.invulnerable or a1.invulnerable <= 0
            local a2_vulnerable = not a2.invulnerable or a2.invulnerable <= 0
            
            if distSq < minDistSq and a1_vulnerable and a2_vulnerable then
                local midX = (a1.x + a2.x) / 2
                local midY = (a1.y + a2.y) / 2
                createExplosion(midX, midY, math.max(a1.radius, a2.radius))
                
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
            createExplosion(player.x, player.y, player.radius)
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
    if #thrusterParticles > MAX_PARTICLES/4 then return end  -- Noch weniger Thruster-Partikel
    
    local backX = player.x - math.cos(player.angle) * 15
    local backY = player.y - math.sin(player.angle) * 15
    
    local particle = {
        x = backX,
        y = backY,
        dx = -math.cos(player.angle) * 50,  -- Vereinfachte Bewegung
        dy = -math.sin(player.angle) * 50,
        lifetime = 0.2,
        size = 1,  -- Feste Größe
        color = {1, 0.5, 0}
    }
    table.insert(thrusterParticles, particle)
end 