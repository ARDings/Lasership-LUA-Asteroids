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
    
    -- Screen Shake als globale Variable
    screenShake = {
        duration = 0,
        intensity = 0
    }
    
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
        explosion = love.audio.newSource("explosion.wav", "static"),
        powerup = love.audio.newSource("powerup.wav", "static")  -- Neuer Sound
    }
    
    -- Sound-Einstellungen
    sounds.shoot:setVolume(1.0)
    sounds.shoot:setPitch(0.7)
    sounds.explosion:setVolume(1.0)
    sounds.explosion:setPitch(0.5)
    sounds.powerup:setVolume(1.0)  -- Volle Lautstärke
    sounds.powerup:setPitch(1.2)   -- Etwas höher gepitcht
    
    -- Spiel starten
    resetGame()
    
    -- Neue Konstanten
    MIN_ASTEROID_SIZE = 20
    MAX_ASTEROIDS_TOTAL = 20  -- Weniger maximale Asteroiden
    MAX_PARTICLES = 100  -- Von 30 auf 100 erhöht
    MAX_THRUSTER_PARTICLES = 40  -- Neue Konstante für Thruster
    
    -- Mauszeiger verstecken
    love.mouse.setVisible(false)
    
    -- In love.load() nach den anderen Variablen
    powerups = {}  -- Liste für Power-ups
    
    -- Am Anfang der Datei nach den anderen globalen Variablen
    oneUpTimer = 0  -- Global machen
    showOneUp = false
    screenFlashTimer = 0
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
            if math.random() < 0.20 then  -- Von 0.05 (5%) auf 0.20 (20%) erhöht für Tests
                createPowerup()
            else
                -- Normaler Asteroiden-Spawn Code...
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
        
        -- Screen Shake Effekt
        updateScreenShake(dt)
        
        -- Neue Update-Funktion für Power-ups
        updatePowerups(dt)
    end
end

function love.draw()
    if gameState == "menu" then
        local font = love.graphics.getFont()
        
        -- ASTEROIDS
        local text = "ASTEROIDS"
        local textWidth = font:getWidth(text) * 4.5
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/3, 0, 4.5, 4.5)
        
        -- made in Berlin
        text = "made in Berlin"
        textWidth = font:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/3+60, 0, 1.5, 1.5)
        
        -- Press SPACE
        love.graphics.setColor(1, 1, 1)
        text = "Press SPACE to start"
        textWidth = font:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+30, 0, 1.5, 1.5)
        
    elseif gameState == "game" then
        -- Screen Shake Effekt
        if screenShake.duration > 0 then
            local dx = love.math.random(-screenShake.intensity, screenShake.intensity)
            local dy = love.math.random(-screenShake.intensity, screenShake.intensity)
            love.graphics.translate(dx, dy)
        end
        
        -- Spieler zeichnen
        drawPlayer()
        
        -- Asteroiden zeichnen
        for _, asteroid in ipairs(asteroids) do
            drawAsteroid(asteroid)
        end
        
        -- Schüsse zeichnen
        drawBullets()
        
        -- Partikel zeichnen
        for _, particle in ipairs(particles) do
            love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3])
            
            -- Dreieck zeichnen
            local vertices = {}
            for _, point in ipairs(particle.points) do
                local x = point[1]
                local y = point[2]
                -- Rotation anwenden
                local rotated_x = x * math.cos(particle.rotation) - y * math.sin(particle.rotation)
                local rotated_y = x * math.sin(particle.rotation) + y * math.cos(particle.rotation)
                table.insert(vertices, particle.x + rotated_x)
                table.insert(vertices, particle.y + rotated_y)
            end
            love.graphics.polygon("fill", vertices)
        end
        
        -- Thruster-Partikel zeichnen (vor dem Schiff)
        for _, p in ipairs(thrusterParticles) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3])
            love.graphics.circle("fill", p.x, p.y, p.size)
        end
        
        -- Power-ups zeichnen
        for _, powerup in ipairs(powerups) do
            if powerup.visible then
                -- Hexagon zeichnen
                love.graphics.setColor(0, 0.7, 0, powerup.alpha)  -- Grün mit Alpha
                
                -- Hexagon-Punkte
                local vertices = {}
                for i = 1, 6 do
                    local angle = (i-1) * math.pi / 3  -- 6 gleichmäßige Punkte
                    local px = powerup.x + math.cos(angle + powerup.angle) * powerup.radius
                    local py = powerup.y + math.sin(angle + powerup.angle) * powerup.radius
                    table.insert(vertices, px)
                    table.insert(vertices, py)
                end
                love.graphics.polygon("line", vertices)
                
                -- Mini-Raumschiff in der Mitte
                love.graphics.setColor(0, 0.7, 0, powerup.alpha * 0.8)  -- Etwas transparenter
                local shipScale = 0.3  -- Noch kleiner (von 0.4 auf 0.3)
                local shipVertices = {}
                for _, point in ipairs(player.points) do
                    local x = point[1] * shipScale
                    local y = point[2] * shipScale
                    local rotated_x = x * math.cos(powerup.angle) - y * math.sin(powerup.angle)
                    local rotated_y = x * math.sin(powerup.angle) + y * math.cos(powerup.angle)
                    table.insert(shipVertices, powerup.x + rotated_x)
                    table.insert(shipVertices, powerup.y + rotated_y)
                end
                love.graphics.polygon("line", shipVertices)
            end
        end
        
        -- HUD
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, 10, 10)
        love.graphics.print("Lives: " .. player.lives, 10, 30)
        
        -- Neue Variable für 1UP-Anzeige
        local oneUpTimer = 0
        local showOneUp = false
        
        if showOneUp then
            oneUpTimer = oneUpTimer - dt
            if oneUpTimer <= 0 then
                showOneUp = false
            end
        end
        
        if showOneUp then
            love.graphics.setColor(0, 1, 0)  -- Grün
            local text = "1UP!"
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(text) * 4
            love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2 - 50, 0, 4, 4)
        end
        
        -- In der love.draw() Funktion vor dem HUD
        if screenFlashTimer > 0 then
            -- Grüner Screen-Flash
            love.graphics.setColor(0, 1, 0, screenFlashTimer * 0.5)  -- Von 0.3 auf 0.5 erhöht (kräftiger)
            love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
        end
        
    elseif gameState == "gameover" then
        local font = love.graphics.getFont()
        
        -- ASTEROIDS
        local text = "ASTEROIDS"
        local textWidth = font:getWidth(text) * 4.5
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/4, 0, 4.5, 4.5)
        
        -- made in Berlin
        text = "made in Berlin"
        textWidth = font:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/4+60, 0, 1.5, 1.5)
        
        -- GAME OVER (30% größer und mehr Abstand)
        text = "GAME OVER"
        textWidth = font:getWidth(text) * 5.85
        love.graphics.setColor(1, 0, 0)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2-30, 0, 5.85, 5.85)
        
        -- Score (mehr Abstand nach GAME OVER)
        love.graphics.setColor(1, 1, 1)
        text = "Score: " .. score
        textWidth = font:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+60, 0, 1.5, 1.5)
        
        -- Highscore
        text = "Highscore: " .. highscore
        textWidth = font:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+105, 0, 1.5, 1.5)
        
        -- Press SPACE
        text = "Press SPACE to restart"
        textWidth = font:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+150, 0, 1.5, 1.5)
    end
end

function love.keypressed(key)
    if key == 'escape' or (love.keyboard.isDown('lctrl') and key == 'c') then
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
        p.rotation = p.rotation + p.rotationSpeed * dt  -- Rotation updaten
        
        -- Nur die Farbe verblassen lassen
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
    elseif soundType == "powerup" then
        sounds.powerup:stop()
        sounds.powerup:play()
    end
end

function shoot()
    local bullet = {
        x = player.x + math.cos(player.angle) * player.radius,
        y = player.y + math.sin(player.angle) * player.radius,
        dx = math.cos(player.angle) * 500 * 1.2,  -- 20% schneller
        dy = math.sin(player.angle) * 500 * 1.2,  -- 20% schneller
        lifetime = 1.5,
        length = 8  -- Länge des Strichs
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
    -- Mehr Partikel für Explosionen
    local particleCount = math.min(30, math.floor(size/4))  -- Noch mehr Partikel
    
    -- Alte Partikel entfernen wenn zu viele
    while #particles >= MAX_PARTICLES do
        table.remove(particles, 1)
    end
    
    -- Explosions-Partikel als Dreiecke/Splitter
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = math.random(150, 300)
        
        -- Zufällige Dreieckspunkte für jeden Splitter
        local splitterSize = math.random(3, 8)
        local points = {
            {0, -splitterSize},  -- Spitze
            {-splitterSize/2, splitterSize/2},  -- Links unten
            {splitterSize/2, splitterSize/2}     -- Rechts unten
        }
        
        -- Zufällige Rotation für jeden Splitter
        local rotation = math.random() * math.pi * 2
        
        local particle = {
            x = x,
            y = y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed,
            rotation = rotation,
            rotationSpeed = math.random(-10, 10),  -- Drehgeschwindigkeit
            points = points,
            lifetime = math.random(0.3, 0.8),
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

function drawBullets()
    love.graphics.setColor(1, 1, 1)
    for _, bullet in ipairs(bullets) do
        -- Berechne Endpunkt des Strichs basierend auf Bewegungsrichtung
        local angle = math.atan2(bullet.dy, bullet.dx)
        local endX = bullet.x + math.cos(angle) * bullet.length
        local endY = bullet.y + math.sin(angle) * bullet.length
        
        -- Zeichne Strich
        love.graphics.line(bullet.x, bullet.y, endX, endY)
    end
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
            playerHit()
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
    
    -- Screen Shake SOFORT zurücksetzen beim Neustart
    screenShake = {
        duration = 0,
        intensity = 0
    }
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
    if #thrusterParticles > MAX_THRUSTER_PARTICLES then return end
    
    -- Mehrere Partikel pro Frame
    for i = 1, 3 do  -- 3 Partikel pro Frame
        -- Kein spread mehr - direkt in Schiffsrichtung
        local angle = player.angle
        local backX = player.x - math.cos(angle) * 20  -- Genau hinter dem Schiff
        local backY = player.y - math.sin(angle) * 20
        
        local particle = {
            x = backX,  -- Keine seitliche Streuung mehr
            y = backY,
            dx = -math.cos(angle) * math.random(40, 80),
            dy = -math.sin(angle) * math.random(40, 80),
            lifetime = math.random(0.3, 0.6),
            size = math.random(1, 2),
            color = {1, math.random(0.5, 0.8), 0}
        }
        table.insert(thrusterParticles, particle)
    end
end

-- Neue Funktion für Screen Shake
function startScreenShake(duration, intensity)
    screenShake.duration = duration
    screenShake.intensity = intensity
end

-- In love.update(dt) vor dem Ende
function updateScreenShake(dt)
    if screenShake.duration > 0 then
        screenShake.duration = screenShake.duration - dt
        if screenShake.duration < 0 then
            screenShake.duration = 0
            screenShake.intensity = 0
        end
    end
end

-- In der Kollisionserkennung wenn der Spieler getroffen wird
function playerHit()
    player.lives = player.lives - 1
    startScreenShake(0.3, 10)  -- Screen Shake bei JEDEM Tod
    createExplosion(player.x, player.y, 30)  -- Größere Explosion beim Tod
    
    if player.lives <= 0 then
        gameState = "gameover"
        startScreenShake(1.0, 5)  -- Sanfterer Shake für 1 Sekunde im Game Over
        if score > highscore then
            highscore = score
            saveHighscore(highscore)
        end
    else
        -- Nur wenn noch Leben übrig sind
        player.x = WIDTH/2
        player.y = HEIGHT/2
        player.dx = 0
        player.dy = 0
        player.angle = 0
        player.invulnerable = 2  -- 2 Sekunden unverwundbar
    end
end

-- Neue Funktion für Power-up Erstellung
function createPowerup()
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
    
    local angle = math.atan2(HEIGHT/2 - y, WIDTH/2 - x)
    angle = angle + math.random(-0.5, 0.5)
    local speed = math.random(50, 100)
    
    local powerup = {
        x = x,
        y = y,
        dx = math.cos(angle) * speed,
        dy = math.sin(angle) * speed,
        radius = 12,
        angle = 0,
        spin = 2,
        blinkTimer = 0,
        visible = true,
        alpha = 1.0  -- Für Transparenz-Animation
    }
    table.insert(powerups, powerup)
end

-- Neue Update-Funktion für Power-ups
function updatePowerups(dt)
    -- Screen Flash updaten
    if screenFlashTimer > 0 then
        screenFlashTimer = screenFlashTimer - dt * 2  -- Schneller verblassen
    end
    
    -- OneUp Timer updaten
    if showOneUp then
        oneUpTimer = oneUpTimer - dt
        if oneUpTimer <= 0 then
            showOneUp = false
        end
    end

    for i = #powerups, 1, -1 do
        local powerup = powerups[i]
        powerup.x = powerup.x + powerup.dx * dt
        powerup.y = powerup.y + powerup.dy * dt
        powerup.angle = powerup.angle + powerup.spin * dt
        
        -- Blinken
        powerup.blinkTimer = powerup.blinkTimer + dt
        if powerup.blinkTimer >= 0.1 then  -- Schnelleres Blinken (von 0.2 auf 0.1)
            powerup.visible = true  -- Immer sichtbar
            powerup.alpha = 0.5 + math.sin(powerup.blinkTimer * 5) * 0.3  -- Sanfte Pulsation
        end
        
        -- Bildschirmgrenzen
        powerup.x = (powerup.x + WIDTH) % WIDTH
        powerup.y = (powerup.y + HEIGHT) % HEIGHT
        
        -- Kollision mit Spieler
        local dx = player.x - powerup.x
        local dy = player.y - powerup.y
        local distSq = dx*dx + dy*dy
        if distSq < (powerup.radius + player.radius)^2 then
            player.lives = player.lives + 1
            screenFlashTimer = 0.3
            table.remove(powerups, i)
            show1Up()
            playSound("powerup")  -- Sound abspielen
        end
    end
end

function show1Up()
    oneUpTimer = 2  -- 2 Sekunden anzeigen
    showOneUp = true
end 