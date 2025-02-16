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
    COLLISION_CHECK_INTERVAL = 0.05  -- Von 0.1 auf 0.05 Sekunden
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
        powerup = love.audio.newSource("powerup.wav", "static"),  -- Neuer Sound
        photon_blast = love.audio.newSource("photon_blast.wav", "static")  -- Neuer Sound
    }
    
    -- Sound-Einstellungen
    sounds.shoot:setVolume(1.0)
    sounds.shoot:setPitch(0.7)
    sounds.explosion:setVolume(1.0)
    sounds.explosion:setPitch(0.5)
    sounds.powerup:setVolume(1.0)  -- Volle Lautstärke
    sounds.powerup:setPitch(1.2)   -- Etwas höher gepitcht
    sounds.photon_blast:setVolume(1.0)  -- Volle Lautstärke
    sounds.photon_blast:setPitch(1.2)   -- Etwas höher gepitcht
    
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
    
    -- In love.load() nach den anderen Variablen
    POWERUP_TYPES = {
        EXTRA_LIFE = "extra_life",
        TIME_WARP = "time_warp",
        PHOTON_BLAST = "photon_blast",
        TRIPLE_SHOT = "triple_shot"
    }
    
    -- Aktive Power-up Effekte
    activeEffects = {
        time_warp = 0,    -- Verbleibende Zeit
        triple_shot = 0,
        time_warp_cooldown = 0,
        triple_shot_cooldown = 0
    }
    
    -- Große Schriftart für Überschriften laden
    titleFont = love.graphics.newFont(72)
    subtitleFont = love.graphics.newFont(36)
    defaultFont = love.graphics.getFont()  -- Speichere Standard-Font
end

function love.update(dt)
    if gameState == "game" then
        -- Timer und Cooldowns aktualisieren
        if activeEffects.time_warp > 0 then
            activeEffects.time_warp = activeEffects.time_warp - dt
            if activeEffects.time_warp <= 0 then
                activeEffects.time_warp = 0
            end
        end
        
        -- Triple Shot Timer aktualisieren
        if activeEffects.triple_shot > 0 then
            activeEffects.triple_shot = activeEffects.triple_shot - dt
            if activeEffects.triple_shot <= 0 then
                activeEffects.triple_shot = 0
            end
        end
        
        -- Cooldowns aktualisieren
        activeEffects.time_warp_cooldown = math.max(0, activeEffects.time_warp_cooldown - dt)
        activeEffects.triple_shot_cooldown = math.max(0, activeEffects.triple_shot_cooldown - dt)
        
        -- Screen Shake aktualisieren
        updateScreenShake(dt)
        
        -- Time Warp Effekt auf dt anwenden
        local effectiveDt = dt
        if activeEffects.time_warp > 0 then
            effectiveDt = dt * 0.3  -- Asteroiden auf 30% Geschwindigkeit
            updatePlayer(dt)        -- Spieler mit normaler Geschwindigkeit
            updateBullets(dt)       -- Schüsse mit normaler Geschwindigkeit
            updateAsteroids(effectiveDt)  -- Asteroiden verlangsamt
            updateParticles(effectiveDt)  -- Partikel verlangsamt
            updateThrusterParticles(dt)   -- Thruster normal
            updatePowerups(effectiveDt)   -- Power-ups verlangsamt
            
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
                if math.random() < 0.05 then  -- Von 0.20 (20%) zurück auf 0.05 (5%)
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
        else
            -- Normale Updates...
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
                if math.random() < 0.05 then  -- Von 0.20 (20%) zurück auf 0.05 (5%)
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
        end
        
        -- Neue Update-Funktion für Power-ups
        updatePowerups(effectiveDt)
    end
end

function love.draw()
    if gameState == "menu" then
        -- ASTEROIDS mit großer Schriftart
        love.graphics.setFont(titleFont)
        text = "ASTEROIDS"
        textWidth = titleFont:getWidth(text)
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/3)
        
        -- made in Berlin mit mittlerer Schriftart
        love.graphics.setFont(subtitleFont)
        text = "made in Berlin"
        textWidth = subtitleFont:getWidth(text)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/3 + 80)
        
        -- Rest mit Standard-Font
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(1, 1, 1)
        text = "Press SPACE to start"
        textWidth = defaultFont:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+30, 0, 1.5, 1.5)
        
    elseif gameState == "game" then
        -- Screen Shake Effekt
        if screenShake.duration > 0 then
            local dx = love.math.random(-screenShake.intensity, screenShake.intensity)
            local dy = love.math.random(-screenShake.intensity, screenShake.intensity)
            love.graphics.translate(dx, dy)
        end
        
        -- Time Warp visueller Effekt
        if activeEffects.time_warp > 0 then
            -- Blauen Schimmer um das Schiff
            love.graphics.setColor(0, 0.5, 1, 0.3)
            love.graphics.circle("fill", player.x, player.y, player.radius * 2)
            
            -- Verzerrte Raum-Zeit-Wellen
            for i = 1, 3 do
                local radius = (player.radius * 3) * i
                local alpha = 0.2 - (i * 0.05)
                love.graphics.setColor(0, 0.5, 1, alpha)
                love.graphics.circle("line", player.x, player.y, radius + math.sin(love.timer.getTime() * 2) * 5)
            end
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
            if particle.isBlast then
                -- Energiewellen-Partikel als Kreise zeichnen
                love.graphics.circle("line", particle.x, particle.y, particle.radius)
            else
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
        end
        
        -- Thruster-Partikel zeichnen (vor dem Schiff)
        for _, p in ipairs(thrusterParticles) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3])
            love.graphics.circle("fill", p.x, p.y, p.size)
        end
        
        -- Power-ups zeichnen
        for _, powerup in ipairs(powerups) do
            if powerup.visible then
                -- Hexagon-Rahmen für alle Power-ups
                love.graphics.setColor(0, 0.7, 0, powerup.alpha)
                local vertices = {}
                for i = 1, 6 do
                    local angle = (i-1) * math.pi / 3
                    local px = powerup.x + math.cos(angle + powerup.angle) * powerup.radius
                    local py = powerup.y + math.sin(angle + powerup.angle) * powerup.radius
                    table.insert(vertices, px)
                    table.insert(vertices, py)
                end
                love.graphics.polygon("line", vertices)
                
                -- Verschiedene Icons je nach Typ
                if powerup.type == POWERUP_TYPES.EXTRA_LIFE then
                    -- Mini-Raumschiff für Extra Leben
                    love.graphics.setColor(0, 0.7, 0, powerup.alpha * 0.8)
                    local shipScale = 0.3
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
                    
                elseif powerup.type == POWERUP_TYPES.TIME_WARP then
                    -- Uhr-Symbol für Time Warp
                    love.graphics.setColor(0, 0.5, 1, powerup.alpha)  -- Blaue Farbe
                    love.graphics.circle("line", powerup.x, powerup.y, powerup.radius * 0.6)
                    -- Zeiger
                    local angle1 = powerup.angle
                    local angle2 = powerup.angle + math.pi / 2
                    love.graphics.line(powerup.x, powerup.y,
                        powerup.x + math.cos(angle1) * powerup.radius * 0.5,
                        powerup.y + math.sin(angle1) * powerup.radius * 0.5)
                    love.graphics.line(powerup.x, powerup.y,
                        powerup.x + math.cos(angle2) * powerup.radius * 0.3,
                        powerup.y + math.sin(angle2) * powerup.radius * 0.3)
                    
                elseif powerup.type == POWERUP_TYPES.PHOTON_BLAST then
                    -- Explosions-Symbol für Photon Blast
                    love.graphics.setColor(1, 1, 1, powerup.alpha)  -- Weiße Farbe
                    for i = 1, 8 do
                        local angle = (i-1) * math.pi / 4
                        local inner = powerup.radius * 0.3
                        local outer = powerup.radius * 0.7
                        love.graphics.line(
                            powerup.x + math.cos(angle + powerup.angle) * inner,
                            powerup.y + math.sin(angle + powerup.angle) * inner,
                            powerup.x + math.cos(angle + powerup.angle) * outer,
                            powerup.y + math.sin(angle + powerup.angle) * outer
                        )
                    end
                elseif powerup.type == POWERUP_TYPES.TRIPLE_SHOT then
                    -- Triple Shot Symbol (3 Punkte)
                    love.graphics.setColor(1, 0.7, 0, powerup.alpha)  -- Helleres Orange
                    local spacing = powerup.radius * 0.4  -- Größerer Abstand (von 0.3 auf 0.4)
                    local dotSize = 3.5  -- Etwas größere Punkte (von 3 auf 3.5)
                    
                    -- Drei Punkte zeichnen
                    for i = -1, 1 do
                        local xOffset = i * spacing
                        love.graphics.circle("fill", 
                            powerup.x + xOffset, 
                            powerup.y, 
                            dotSize)
                    end
                end
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
        
        -- Power-up Status
        local y = 60  -- Startposition unter Lives
        if activeEffects.time_warp > 0 then
            love.graphics.setColor(0, 0.5, 1)
            love.graphics.print("Time Warp: " .. string.format("%.1f", activeEffects.time_warp), 10, y)
            y = y + 20
        elseif activeEffects.time_warp_cooldown > 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("Time Warp CD: " .. string.format("%.1f", activeEffects.time_warp_cooldown), 10, y)
            y = y + 20
        end
        
        -- Triple Shot Status
        if activeEffects.triple_shot > 0 then
            love.graphics.setColor(1, 0.5, 0)  -- Orange
            love.graphics.print("Triple Shot: " .. string.format("%.1f", activeEffects.triple_shot), 10, y)
            y = y + 20
        elseif activeEffects.triple_shot_cooldown > 0 then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("Triple Shot CD: " .. string.format("%.1f", activeEffects.triple_shot_cooldown), 10, y)
            y = y + 20
        end
        
    elseif gameState == "gameover" then
        -- ASTEROIDS mit großer Schriftart
        love.graphics.setFont(titleFont)
        text = "ASTEROIDS"
        textWidth = titleFont:getWidth(text)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/5)
        
        -- made in Berlin mit mittlerer Schriftart
        love.graphics.setFont(subtitleFont)
        text = "made in Berlin"
        textWidth = subtitleFont:getWidth(text)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/5 + 80)
        
        -- GAME OVER mit großer Schriftart
        love.graphics.setFont(titleFont)
        text = "GAME OVER"
        textWidth = titleFont:getWidth(text)
        love.graphics.setColor(1, 0, 0)
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2 - 60)
        
        -- Score (angepasst)
        love.graphics.setFont(defaultFont)
        text = "Score: " .. score
        textWidth = defaultFont:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+30, 0, 1.5, 1.5)
        
        -- Highscore (angepasst)
        text = "Highscore: " .. highscore
        textWidth = defaultFont:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+75, 0, 1.5, 1.5)
        
        -- Press SPACE (angepasst)
        text = "Press SPACE to restart"
        textWidth = defaultFont:getWidth(text) * 1.5
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+120, 0, 1.5, 1.5)
        
        -- Item Info Header (höher)
        love.graphics.setColor(1, 1, 1)
        text = "Item Info:"
        textWidth = defaultFont:getWidth(text) * 1.2
        love.graphics.print(text, WIDTH/2 - textWidth/2, HEIGHT/2+180, 0, 1.2, 1.2)

        -- Item Icons und Beschreibungen (entsprechend angepasst)
        local iconY = HEIGHT/2+220  -- Von HEIGHT/2+290 auf HEIGHT/2+220
        local iconSize = 24
        local spacing = WIDTH/4     -- Von WIDTH/5 auf WIDTH/4 für bessere Zentrierung
        local startX = WIDTH/2 - spacing*1.5  -- Angepasst für 4 Items

        -- Extra Life (Original Icon, 50% größer)
        love.graphics.setColor(0, 0.7, 0, 1)  -- Volle Deckkraft
        local shipScale = 0.45  -- Von 0.3 auf 0.45 (50% größer)
        local shipVertices = {}
        for _, point in ipairs(player.points) do
            local x = point[1] * shipScale
            local y = point[2] * shipScale
            table.insert(shipVertices, startX + x)
            table.insert(shipVertices, iconY + y)
        end
        love.graphics.polygon("line", shipVertices)
        love.graphics.print("Extra Life", startX - 30, iconY + 25, 0, 1, 1)

        -- Time Warp (Original Icon)
        love.graphics.setColor(0, 0.5, 1, 1)
        love.graphics.circle("line", startX + spacing, iconY, iconSize/2)
        local angle1 = love.timer.getTime() % (2 * math.pi)
        local angle2 = angle1 + math.pi / 2
        love.graphics.line(
            startX + spacing,
            iconY,
            startX + spacing + math.cos(angle1) * iconSize/2,
            iconY + math.sin(angle1) * iconSize/2
        )
        love.graphics.line(
            startX + spacing,
            iconY,
            startX + spacing + math.cos(angle2) * iconSize/3,
            iconY + math.sin(angle2) * iconSize/3
        )
        love.graphics.print("Time Warp", startX + spacing - 30, iconY + 25, 0, 1, 1)

        -- Photon Blast (Original Icon)
        love.graphics.setColor(1, 1, 1, 1)
        for i = 1, 8 do
            local angle = (i-1) * math.pi / 4
            local inner = iconSize/3
            local outer = iconSize/2
            love.graphics.line(
                startX + spacing*2 + math.cos(angle) * inner,
                iconY + math.sin(angle) * inner,
                startX + spacing*2 + math.cos(angle) * outer,
                iconY + math.sin(angle) * outer
            )
        end
        love.graphics.print("Photon Blast", startX + spacing*2 - 35, iconY + 25, 0, 1, 1)

        -- Triple Shot (Original Icon)
        love.graphics.setColor(1, 0.7, 0, 1)
        local dotSpacing = iconSize/3
        for i = -1, 1 do
            love.graphics.circle("fill", 
                startX + spacing*3 + i * dotSpacing, 
                iconY, 
                3.5)  -- Gleiche Größe wie im Spiel
        end
        love.graphics.print("Triple Shot", startX + spacing*3 - 30, iconY + 25, 0, 1, 1)
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
        
        -- Spezielle Behandlung für Blast-Partikel
        if p.isBlast then
            -- Partikel werden größer während sie sich ausbreiten
            p.radius = p.radius + dt * 10
            -- Verblassen
            p.color[1] = p.color[1] * 0.95
            p.color[2] = p.color[2] * 0.95
            p.color[3] = p.color[3] * 0.95
        else
            -- Normale Partikel-Updates...
            if p.rotation then
                p.rotation = p.rotation + p.rotationSpeed * dt
            end
            if p.color then
                p.color[1] = p.color[1] * 0.98
                p.color[2] = p.color[2] * 0.95
            end
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
    elseif soundType == "photon_blast" then
        sounds.photon_blast:stop()
        sounds.photon_blast:play()
    end
end

function shoot()
    if activeEffects.triple_shot > 0 then
        -- Drei Schüsse mit Streuung
        local spread = math.pi / 12  -- 15 Grad Streuung
        
        -- Mittlerer Schuss
        local bullet1 = {
            x = player.x + math.cos(player.angle) * player.radius,
            y = player.y + math.sin(player.angle) * player.radius,
            dx = math.cos(player.angle) * 500,
            dy = math.sin(player.angle) * 500,
            lifetime = 0.75,  -- Kürzere Reichweite
            length = 8,
            damage = 0.8  -- 80% Schaden
        }
        
        -- Linker Schuss
        local bullet2 = {
            x = player.x + math.cos(player.angle - spread) * player.radius,
            y = player.y + math.sin(player.angle - spread) * player.radius,
            dx = math.cos(player.angle - spread) * 500,
            dy = math.sin(player.angle - spread) * 500,
            lifetime = 0.75,
            length = 8,
            damage = 0.8
        }
        
        -- Rechter Schuss
        local bullet3 = {
            x = player.x + math.cos(player.angle + spread) * player.radius,
            y = player.y + math.sin(player.angle + spread) * player.radius,
            dx = math.cos(player.angle + spread) * 500,
            dy = math.sin(player.angle + spread) * 500,
            lifetime = 0.75,
            length = 8,
            damage = 0.8
        }
        
        table.insert(bullets, bullet1)
        table.insert(bullets, bullet2)
        table.insert(bullets, bullet3)
    else
        -- Normaler einzelner Schuss
        local bullet = {
            x = player.x + math.cos(player.angle) * player.radius,
            y = player.y + math.sin(player.angle) * player.radius,
            dx = math.cos(player.angle) * 500 * 1.2,
            dy = math.sin(player.angle) * 500 * 1.2,
            lifetime = 1.5,
            length = 8,
            damage = 1.0  -- Voller Schaden
        }
        table.insert(bullets, bullet)
    end
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
    -- Schüsse gegen Asteroiden - häufigere Prüfung
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        for j = #asteroids, 1, -1 do
            local asteroid = asteroids[j]
            -- Verbesserte Hitbox-Berechnung
            local dx = bullet.x - asteroid.x
            local dy = bullet.y - asteroid.y
            local distSq = dx*dx + dy*dy
            local hitRadius = asteroid.radius * 1.2  -- 20% größere Hitbox
            local radiusSq = hitRadius * hitRadius
            
            if distSq < radiusSq then
                createExplosion(asteroid.x, asteroid.y, asteroid.radius)
                table.remove(bullets, i)
                table.remove(asteroids, j)
                score = score + 100
                
                if asteroid.radius >= MIN_ASTEROID_SIZE then
                    local newSize = asteroid.radius * 0.7
                    createAsteroid(newSize, asteroid.x, asteroid.y)
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
    
    -- Powerup-Typ direkt aus der Zufallszahl bestimmen
    local powerupType
    local rand = math.random()
    if rand < 0.25 then
        powerupType = POWERUP_TYPES.EXTRA_LIFE
    elseif rand < 0.50 then
        powerupType = POWERUP_TYPES.TIME_WARP
    elseif rand < 0.75 then
        powerupType = POWERUP_TYPES.PHOTON_BLAST
    else
        powerupType = POWERUP_TYPES.TRIPLE_SHOT
    end
    
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
        alpha = 1.0,
        type = powerupType
    }
    table.insert(powerups, powerup)
end

-- Power-up Effekte aktivieren
function activatePowerup(type)
    if type == POWERUP_TYPES.EXTRA_LIFE then
        player.lives = player.lives + 1
        show1Up()
    elseif type == POWERUP_TYPES.TIME_WARP and activeEffects.time_warp_cooldown <= 0 then
        activeEffects.time_warp = 7  -- 7 Sekunden Dauer
        activeEffects.time_warp_cooldown = 15
    elseif type == POWERUP_TYPES.PHOTON_BLAST then
        createPhotonBlast()
    elseif type == POWERUP_TYPES.TRIPLE_SHOT and activeEffects.triple_shot_cooldown <= 0 then
        activeEffects.triple_shot = 10  -- Von 8 auf 10 Sekunden erhöht
        activeEffects.triple_shot_cooldown = 20
    end
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
            activatePowerup(powerup.type)
            screenFlashTimer = 0.3
            table.remove(powerups, i)
            playSound("powerup")
        end
    end
end

function show1Up()
    oneUpTimer = 2  -- 2 Sekunden anzeigen
    showOneUp = true
end

-- Neue Funktion für die Photonenwelle
function createPhotonBlast()
    -- Visuelle Explosion
    local blastParticles = 60
    local blastRadius = 600
    
    -- Kreisförmige Energiewelle
    for i = 1, blastParticles do
        local angle = (i / blastParticles) * math.pi * 2
        local speed = 800
        
        -- Energiepartikel
        local particle = {
            x = player.x,
            y = player.y,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed,
            lifetime = 0.5,
            radius = 4,
            color = {1, 1, 1},
            isBlast = true
        }
        table.insert(particles, particle)
        
        -- Zusätzliche Schüsse in alle Richtungen
        local bullet = {
            x = player.x + math.cos(angle) * player.radius,
            y = player.y + math.sin(angle) * player.radius,
            dx = math.cos(angle) * 600,
            dy = math.sin(angle) * 600,
            lifetime = 0.5,
            length = 12,
            damage = 1.5  -- Extra Schaden
        }
        table.insert(bullets, bullet)
    end
    
    -- Schockwelle-Effekt
    startScreenShake(0.2, 5)
    
    -- Asteroiden im Radius mit mehr Schaden
    for i = #asteroids, 1, -1 do
        local asteroid = asteroids[i]
        local dx = asteroid.x - player.x
        local dy = asteroid.y - player.y
        local distSq = dx*dx + dy*dy
        
        if distSq < blastRadius * blastRadius then
            -- Explosion an Asteroid-Position
            createExplosion(asteroid.x, asteroid.y, asteroid.radius * 1.5)  -- Größere Explosion
            
            -- Alle Asteroiden werden zerstört, große werden geteilt
            if asteroid.radius >= MIN_ASTEROID_SIZE * 2 then
                local newSize = asteroid.radius * 0.4  -- Kleinere Teilstücke
                for _ = 1, 2 do
                    createAsteroid(newSize, asteroid.x, asteroid.y, 1.0)
                end
                score = score + 200  -- Mehr Punkte
            else
                score = score + 150
            end
            
            table.remove(asteroids, i)
        end
    end
    
    -- Spezieller Sound für Photon Blast
    playSound("photon_blast")
end 