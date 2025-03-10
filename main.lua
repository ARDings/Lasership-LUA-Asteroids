function love.load()
    -- FPS-Begrenzung
    TARGET_FPS = 30
    MIN_DT = 1/TARGET_FPS
    
    -- Für stabile Performance auf Raspberry Pi
    if love.system.getOS() == "Linux" then
        love.window.setVSync(0)  -- VSync ausschalten für manuelle Begrenzung
    end
    
    -- Konstanten
    WIDTH = 800
    HEIGHT = 600
    ACCELERATION = 300
    ROTATION_SPEED = 5
    FRICTION = 0.99
    MAX_ASTEROIDS = 3
    DIFFICULTY_INCREASE_TIME = 15
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
    
    -- Sounds laden und optimieren mit verbesserter Performance
    sounds = {
        shoot = love.audio.newSource("shoot.wav", "static"),
        explosion = love.audio.newSource("explosion.wav", "static"),
        powerup = love.audio.newSource("powerup.wav", "static"),
        photon_blast = love.audio.newSource("photon_blast.wav", "static")
    }
    
    -- Sound-Einstellungen & Performance-Optimierung
    for _, sound in pairs(sounds) do
        sound:setVolume(1.0)
        -- Wichtige Performance-Optimierung für Sounds
        sound:setFilter({type = "lowpass", volume = 1.0})
    end
    
    -- Spezifische Sound-Einstellungen
    sounds.shoot:setPitch(0.7)
    sounds.explosion:setPitch(0.5)
    sounds.powerup:setPitch(1.2)
    sounds.photon_blast:setPitch(1.2)
    
    -- Vorladen von Sound-Instanzen für häufig wiederkehrende Sounds
    soundInstances = {
        shoot = {},
        explosion = {}
    }
    
    -- Mehrere Instanzen vorladen für häufige Sounds
    for i = 1, 8 do
        soundInstances.shoot[i] = sounds.shoot:clone()
        soundInstances.explosion[i] = sounds.explosion:clone()
    end
    
    -- Sound-Zähler für Instance-Rotation
    soundCounter = {
        shoot = 1,
        explosion = 1
    }
    
    -- Spiel starten
    resetGame()
    
    -- Neue Konstanten
    MIN_ASTEROID_SIZE = 20
    MAX_ASTEROIDS_TOTAL = 14  -- Weniger maximale Asteroiden
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
    
    -- CRT Effekt Variablen
    crtEffect = {
        scanlineHeight = 2,
        scanlineAlpha = 0.2,    -- Von 0.1 auf 0.2 erhöht
        glitchTimer = 0,
        glitchDuration = 0,
        glitchOffset = 0,
        glitchInterval = math.random(2, 5),
        screenShakeAmount = 0.5  -- Neuer Wert für konstantes Zittern
    }
    
    -- Gamepad Konfiguration
    gamepad = {
        deadzone = 0.2,  -- Ignoriert kleine Stick-Bewegungen
        connected = false
    }
    
    -- Prüfe ob ein Gamepad verbunden ist
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        gamepad.device = joysticks[1]  -- Nimm das erste verbundene Gamepad
        gamepad.connected = true
    end
    
    -- LED Setup (vereinfacht)
    if love.system.getOS() == "Linux" then
        -- Aktuelles Verzeichnis ermitteln
        local current_dir = love.filesystem.getSource()
        -- LED-Visualizer mit vollem Pfad starten
        os.execute(string.format("cd %s && ./start_led.sh &", current_dir))
        -- Warte kurz, damit der Visualizer starten kann
        os.execute("sleep 0.5")
        -- Pipe öffnen
        apmPipe = io.open("/tmp/game_apm_pipe", "w")
        lastLedUpdate = 0
        lastLedState = ""  -- Speichert letzten LED-Zustand
        -- Initial LED-Status senden
        if apmPipe then
            apmPipe:write("state=menu,lives=3,timewarp=0,tripleshot=0\n")
            apmPipe:flush()
        end
    end
    
    -- Sound-Konfiguration für bessere Performance
    love.audio.setVolume(0.8)  -- Gesamtlautstärke etwas reduzieren
    love.audio.setDistanceModel("none")  -- Einfacheres Audiomodell
    
    -- Audio-Puffergrößen für Bluetooth-Kompatibilität anpassen
    if love.system.getOS() == "Linux" then
        love.audio.setMixWithSystem(false)  -- Wichtig für Raspberry Pi
    end
    
    -- Schuss-Konfiguration
    SHOT_COOLDOWN = 0.15  -- Minimale Zeit zwischen Schüssen (150ms)
    lastShotTime = 0      -- Timer für den letzten Schuss
    
    -- Beste Performance für Schüsse
    MAX_BULLETS = 10      -- Maximal 10 Schüsse gleichzeitig
    
    -- Erweiterte Sound-Steuerung mit Kategorien und Prioritäts-Timern
    soundSystem = {
        currentlyPlaying = {
            shoot = false,
            explosion = false,
            powerup = false,
            other = false
        },
        playingSource = {
            shoot = nil,
            explosion = nil,
            powerup = nil,
            other = nil
        },
        volume = 0.8,
        cooldown = {
            shoot = 0,
            explosion = 0,
            powerup = 0,
            other = 0
        },
        priorityTimer = {     -- NEU: Timer für Prioritäts-Dauer
            shoot = 0,
            explosion = 0,
            powerup = 0,
            other = 0
        }
    }
    
    -- Sound-Kategorien definieren
    soundCategories = {
        shoot = "shoot",
        explosion = "explosion",
        powerup = "powerup",
        photon_blast = "explosion"  -- Photon Blast ist auch eine Art Explosion
    }
end

function love.update(dt)
    -- FPS-Begrenzung auf 30
    if dt < MIN_DT then
        love.timer.sleep(MIN_DT - dt)
    end
    
    -- LED-Update vereinfachen
    if love.system.getOS() == "Linux" and apmPipe then
        lastLedUpdate = (lastLedUpdate or 0) + dt
        if lastLedUpdate >= 0.2 then  -- Reduziere auf 5 Updates pro Sekunde
            lastLedUpdate = 0
            
            -- Kurze, robuste Statusnachricht
            local lives = player.lives or 0
            if gameState ~= "game" then lives = 0 end  -- Im Menu und GameOver
            
            local currentState = string.format(
                "state=%s,lives=%d,timewarp=%d,tripleshot=%d\n",
                gameState,
                lives,
                (gameState == "game" and activeEffects.time_warp > 0) and 1 or 0,
                (gameState == "game" and activeEffects.triple_shot > 0) and 1 or 0
            )
            
            apmPipe:write(currentState)
            apmPipe:flush()
        end
    end
    
    -- Häufigere Garbage Collection bei niedrigerem Timer, weniger intensiv
    gcTimer = (gcTimer or 0) + dt
    if gcTimer > 2 then  -- Alle 2 Sekunden statt 5
        collectgarbage("step", 10)  -- Inkrementelle GC statt vollständiger Collection
        gcTimer = 0
    end
    
    if gameState == "game" then
        -- Aktualisiere Unverwundbarkeit
        updateInvulnerability(dt)
        
        -- Gamepad Steuerung
        if gamepad.connected then
            -- Rotation mit linkem Stick
            local leftX = gamepad.device:getAxis(1)
            if math.abs(leftX) > gamepad.deadzone then
                player.angle = player.angle + ROTATION_SPEED * dt * leftX
            end
            
            -- Schub mit rechtem Trigger (2)
            local trigger = gamepad.device:getAxis(6)
            if trigger > -0.5 then  -- Trigger gedrückt
                local thrust_x = math.cos(player.angle) * ACCELERATION * dt
                local thrust_y = math.sin(player.angle) * ACCELERATION * dt
                player.dx = player.dx + thrust_x
                player.dy = player.dy + thrust_y
                
                if math.random() < 0.3 then
                    createThrusterParticle()
                end
            end
        end
        
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
            spawnNewAsteroids(dt)
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
            spawnNewAsteroids(dt)
        end
        
        -- Neue Update-Funktion für Power-ups
        updatePowerups(effectiveDt)
    end
    
    -- Glitch Timer aktualisieren
    if gameState == "menu" or gameState == "gameover" then
        crtEffect.glitchTimer = crtEffect.glitchTimer + dt
        
        if crtEffect.glitchTimer >= crtEffect.glitchInterval then
            crtEffect.glitchTimer = 0
            crtEffect.glitchDuration = 0.2
            crtEffect.glitchOffset = math.random(-10, 10)
            crtEffect.glitchInterval = math.random(2, 5)  -- Neues zufälliges Intervall
        end
        
        if crtEffect.glitchDuration > 0 then
            crtEffect.glitchDuration = crtEffect.glitchDuration - dt
        end
    end
    
    -- Sound-System aktualisieren
    updateSoundSystem(dt)
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
        
        drawCRTEffect()
    elseif gameState == "game" then
        -- Sicherstellen, dass Glitch-Effekt deaktiviert ist
        crtEffect.glitchDuration = 0
        crtEffect.glitchTimer = 0
        
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
        
        drawCRTEffect()
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
        
        drawCRTEffect()
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        if gameState == "game" then
            shoot()  -- Die optimierte Funktion mit Cooldown
        elseif gameState == "menu" or gameState == "gameover" then
            resetGame()
            gameState = "game"
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
    -- Verarbeite Bullets in Batches für bessere Performance
    local batch_size = math.min(10, #bullets)  -- Maximal 10 auf einmal
    
    for i = #bullets, math.max(1, #bullets - batch_size), -1 do
        local bullet = bullets[i]
        
        -- Bewegung
        bullet.x = bullet.x + bullet.dx * dt
        bullet.y = bullet.y + bullet.dy * dt
        
        -- Lebensdauer reduzieren
        bullet.lifetime = bullet.lifetime - dt
        
        -- Schuss außerhalb des Bildschirms oder abgelaufen
        if bullet.lifetime <= 0 or
           bullet.x < -50 or bullet.x > WIDTH + 50 or
           bullet.y < -50 or bullet.y > HEIGHT + 50 then
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
    -- Begrenze die Anzahl der aktiven Partikel
    while #particles > MAX_PARTICLES do
        table.remove(particles, 1)  -- Entferne älteste Partikel
    end
    
    -- Schnelleres Rendering durch Vorberechnungen
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.lifetime = p.lifetime - dt
        
        if p.lifetime <= 0 then
            table.remove(particles, i)
        end
    end
end

function updateThrusterParticles(dt)
    -- Begrenze die Anzahl der aktiven Thruster-Partikel
    while #thrusterParticles > MAX_THRUSTER_PARTICLES do
        table.remove(thrusterParticles, 1)
    end
    
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

-- Verbesserte Sound-Funktion mit zeitlich begrenzten Prioritäten
function playSound(name, priority)
    -- Wenn kein passender Sound gefunden wird, abbrechen
    if not sounds[name] then return end
    
    -- Bestimme Kategorie des Sounds
    local category = soundCategories[name] or "other"
    priority = priority or 1
    
    -- Modifizierte Prioritätsregeln:
    -- 1. Explosionen haben Vorrang vor Schüssen für 1 Sekunde
    -- 2. Sounds der gleichen Kategorie ersetzen sich
    -- 3. Power-ups haben hohe Priorität
    
    -- Prüfe, ob eine höherrangige Kategorie mit aktivem Prioritäts-Timer läuft
    if category == "shoot" and 
       soundSystem.currentlyPlaying.explosion and 
       soundSystem.priorityTimer.explosion > 0 then
        -- Ignoriere Schüsse während Explosionen mit aktiver Priorität laufen
        return
    end
    
    -- Stoppe Sound der gleichen Kategorie, falls vorhanden
    if soundSystem.playingSource[category] then
        soundSystem.playingSource[category]:stop()
        soundSystem.currentlyPlaying[category] = false
    end
    
    -- Spiele den Sound
    pcall(function()
        -- Quelle auf aktuell abspielende Quelle setzen
        soundSystem.playingSource[category] = sounds[name]
        soundSystem.playingSource[category]:stop()  -- Zurücksetzen
        soundSystem.playingSource[category]:play()
        soundSystem.currentlyPlaying[category] = true
        
        -- Timer für die Dauer des Sounds setzen
        soundSystem.cooldown[category] = 0.2  -- Angepasste Dauer
        
        -- Setze Prioritäts-Timer für bestimmte Kategorien
        if category == "explosion" then
            soundSystem.priorityTimer[category] = 1.0  -- 1 Sekunde Priorität
        elseif category == "powerup" then
            soundSystem.priorityTimer[category] = 0.5  -- 0.5 Sekunden Priorität
        end
    end)
end

-- Aktualisierte Sound-System-Update-Funktion mit Prioritäts-Timer
function updateSoundSystem(dt)
    -- Kategorien durchgehen
    for category, _ in pairs(soundSystem.currentlyPlaying) do
        -- Cooldown für jede Kategorie aktualisieren
        if soundSystem.cooldown[category] > 0 then
            soundSystem.cooldown[category] = soundSystem.cooldown[category] - dt
        else
            soundSystem.cooldown[category] = 0
        end
        
        -- Prioritäts-Timer reduzieren
        if soundSystem.priorityTimer[category] > 0 then
            soundSystem.priorityTimer[category] = soundSystem.priorityTimer[category] - dt
        else
            soundSystem.priorityTimer[category] = 0
        end
        
        -- Prüfe, ob der Sound fertig ist
        if soundSystem.playingSource[category] and 
           not soundSystem.playingSource[category]:isPlaying() then
            soundSystem.currentlyPlaying[category] = false
            soundSystem.playingSource[category] = nil
            soundSystem.priorityTimer[category] = 0  -- Timer zurücksetzen
        end
    end
end

-- Optimierte Schuss-Funktion mit Rate-Limiting
function shoot()
    -- Zeit-basiertes Cooldown für Schüsse
    local currentTime = love.timer.getTime()
    if currentTime - lastShotTime < SHOT_COOLDOWN then
        return  -- Zu schnelles Feuern verhindern
    end
    lastShotTime = currentTime
    
    -- Begrenze die maximale Anzahl von Schüssen
    if #bullets >= MAX_BULLETS then
        -- Ältesten Schuss entfernen
        table.remove(bullets, 1)
    end
    
    -- Erhöhte Schussgeschwindigkeit (+40%)
    local speed = 700  -- Statt 500
    
    -- Standard-Schuss
    local bullet = {
        x = player.x + math.cos(player.angle) * player.radius,
        y = player.y + math.sin(player.angle) * player.radius,
        dx = math.cos(player.angle) * speed,
        dy = math.sin(player.angle) * speed,
        lifetime = 1.0,
        length = 12  -- Länger für bessere Sichtbarkeit
    }
    table.insert(bullets, bullet)
    
    -- Triple-Shot wenn aktiv (begrenze auch hier die Anzahl)
    if activeEffects.triple_shot > 0 then
        -- Wenn wir das Limit überschreiten würden, entferne alte Schüsse
        while #bullets >= MAX_BULLETS - 2 do
            table.remove(bullets, 1)
        end
        
        local spread = 0.3  -- 0.3 Radianten Streuung
        
        -- Linker Schuss
        local leftBullet = {
            x = player.x + math.cos(player.angle - spread) * player.radius,
            y = player.y + math.sin(player.angle - spread) * player.radius,
            dx = math.cos(player.angle - spread) * speed,
            dy = math.sin(player.angle - spread) * speed,
            lifetime = 1.0,
            length = 12
        }
        table.insert(bullets, leftBullet)
        
        -- Rechter Schuss
        local rightBullet = {
            x = player.x + math.cos(player.angle + spread) * player.radius,
            y = player.y + math.sin(player.angle + spread) * player.radius,
            dx = math.cos(player.angle + spread) * speed,
            dy = math.sin(player.angle + spread) * speed,
            lifetime = 1.0,
            length = 12
        }
        table.insert(bullets, rightBullet)
    end
    
    -- Optimiertes Sound-Handling für Schüsse
    pcall(function()
        -- Schuss-Sound (niedrige Priorität)
        playSound("shoot", 1)  -- Priorität 1 (niedrig)
    end)
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

function createExplosion(x, y, size, count)
    -- Falls zu viele Partikel, reduziere neue Explosion
    if #particles > MAX_PARTICLES * 0.8 then
        count = count or 5  -- Standardwert reduzieren
    else
        count = count or 15  -- Standardwert
    end
    
    -- Alte Partikel entfernen wenn zu viele
    while #particles >= MAX_PARTICLES do
        table.remove(particles, 1)
    end
    
    -- Explosions-Partikel als Dreiecke/Splitter
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
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
    playSound("explosion", 2)  -- Priorität 2 (mittel)
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
    -- Nur zeichnen, wenn nicht blinkend oder Spiel pausiert
    if not player.blinkState or gameState ~= "game" then
        love.graphics.setColor(1, 1, 1)
        
        -- Zeichne Spielerschiff als Polygon
        local vertices = {}
        for i, point in ipairs(player.points) do
            -- Verwende das korrekte Format für die Punkte (Array statt x/y-Objekt)
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
end

function drawAsteroid(asteroid)
    -- Alle Asteroiden in Rosa (#d9599f)
    love.graphics.setColor(0.851, 0.349, 0.624)
    
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

function drawBullets()
    love.graphics.setColor(1, 1, 0)  -- Gelb statt Weiß
    for _, bullet in ipairs(bullets) do
        local angle = math.atan2(bullet.dy, bullet.dx)
        local endX = bullet.x + math.cos(angle) * bullet.length
        local endY = bullet.y + math.sin(angle) * bullet.length
        love.graphics.line(bullet.x, bullet.y, endX, endY)
    end
end

function checkCollisions()
    -- Prüfe alle Kollisionen auf einmal für Stabilität
    
    -- Kollision: Spieler-Asteroid (verbessert)
    if player and not (player.invulnerable and player.invulnerable > 0) then
        for _, asteroid in ipairs(asteroids) do
            -- Größere Hitbox für sicherere Erkennung
            local hitDistance = (asteroid.radius + player.radius) * 1.2
            
            -- Direkter Distanz-Check ohne Quadratwurzel-Vermeidung für Stabilität
            local dx = player.x - asteroid.x
            local dy = player.y - asteroid.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance < hitDistance then
                playerHit()
                break
            end
        end
    end
    
    -- Kollision: Schuss-Asteroid (verbessert)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        local bulletX, bulletY = bullet.x, bullet.y
        local bulletRemoved = false
        
        for j = #asteroids, 1, -1 do
            if bulletRemoved then break end  -- Dieser Schuss wurde schon entfernt
            
            local asteroid = asteroids[j]
            local dx = bulletX - asteroid.x
            local dy = bulletY - asteroid.y
            local distSq = dx*dx + dy*dy
            local hitRadius = asteroid.radius * 1.2  -- Größere Hitbox für bessere Spielbarkeit
            
            if distSq < hitRadius * hitRadius then
                -- Explosion mit angepasster Partikelzahl
                local particleCount = math.min(15, math.max(5, 15 - math.floor(#particles / 20)))
                createExplosion(asteroid.x, asteroid.y, asteroid.radius, particleCount)
                
                -- Punkte und Asteroid aufteilen oder entfernen
                score = score + 100
                if asteroid.radius >= MIN_ASTEROID_SIZE * 2 then
                    splitAsteroid(j)
                else
                    table.remove(asteroids, j)
                end
                
                -- Schuss entfernen (nur einmal pro Schuss)
                table.remove(bullets, i)
                bulletRemoved = true
                
                -- Kurzen Screen Shake hinzufügen
                startScreenShake(0.1, 2)
                
                -- Sound
                playSound("explosion", 2)  -- Priorität 2 (mittel)
                break
            end
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
    thrusterParticles = {}
    powerups = {}
    
    score = 0
    difficulty_timer = 0  -- Hier auch zurücksetzen!
    MAX_ASTEROIDS = 3    -- Zurück zum Startwert
    
    -- Anfangsasteroiden erstellen
    for i = 1, MAX_ASTEROIDS do
        createAsteroid()
    end
    
    -- Screen Shake SOFORT zurücksetzen beim Neustart
    screenShake = {
        duration = 0,
        intensity = 0
    }
    
    -- LED-Status nach Reset aktualisieren
    if love.system.getOS() == "Linux" and apmPipe then
        apmPipe:write("state=game,lives=3,timewarp=0,tripleshot=0\n")
        apmPipe:flush()
        lastLedState = "state=game,lives=3,timewarp=0,tripleshot=0\n"
    end
    
    -- Speicher explizit freigeben
    collectgarbage("collect")
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
    -- Limitiere Thruster-Partikel bei vielen Objekten im Spiel
    local maxParticles = MAX_THRUSTER_PARTICLES
    if #particles > MAX_PARTICLES * 0.5 then
        maxParticles = MAX_THRUSTER_PARTICLES * 0.5
    end
    
    if #thrusterParticles > maxParticles then return end
    
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
    -- Nur fortfahren, wenn der Spieler nicht unverwundbar ist
    if player.invulnerable and player.invulnerable > 0 then
        return  -- Früher beenden, wenn der Spieler unverwundbar ist
    end
    
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
        
        -- WICHTIG: Setze die Unverwundbarkeit für 2 Sekunden
        player.invulnerable = 2.0
        
        -- Asteroiden verschieben, die zu nah sind
        for _, asteroid in ipairs(asteroids) do
            local dx = player.x - asteroid.x
            local dy = player.y - asteroid.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < 100 then
                -- Verschiebe Asteroiden an eine sichere Position
                local angle = math.random() * math.pi * 2
                asteroid.x = player.x + math.cos(angle) * 150
                asteroid.y = player.y + math.sin(angle) * 150
            end
        end
    end
    
    -- Update LEDs nach Treffer
    if love.system.getOS() == "Linux" and apmPipe then
        local livesLeft = math.max(0, player.lives)
        apmPipe:write(string.format("state=%s,lives=%d,timewarp=0,tripleshot=0\n", 
                                   gameState, livesLeft))
        apmPipe:flush()
    end
    
    -- Spieler-Treffer-Sound (höchste Priorität)
    playSound("explosion", 5)  -- Priorität 5 (sehr hoch)
end

-- Füge eine Funktion zum Aktualisieren der Unverwundbarkeit hinzu
function updateInvulnerability(dt)
    if player.invulnerable and player.invulnerable > 0 then
        player.invulnerable = player.invulnerable - dt
        
        -- Blinken während Unverwundbarkeit
        player.blinkState = not player.blinkState
    else
        player.invulnerable = 0  -- Stelle sicher, dass es nicht negativ wird
        player.blinkState = false
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
    
    -- Power-up-Sound (höhere Priorität)
    playSound("powerup", 3)  -- Priorität 3 (hoch)
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
            playSound("powerup", 3)  -- Priorität 3 (hoch)
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

-- Neue Funktion für CRT-Effekte
function drawCRTEffect()
    -- Konstantes Bildschirmzittern
    local shakeX = math.random(-1, 1) * crtEffect.screenShakeAmount
    local shakeY = math.random(-1, 1) * crtEffect.screenShakeAmount
    love.graphics.translate(shakeX, shakeY)
    
    -- Scanlines mit Bewegung
    love.graphics.setColor(0, 0, 0, crtEffect.scanlineAlpha)
    local timeOffset = love.timer.getTime() * 30  -- Bewegungsgeschwindigkeit
    for y = 0, HEIGHT + crtEffect.scanlineHeight * 2 do
        if (y + math.floor(timeOffset)) % (crtEffect.scanlineHeight * 2) == 0 then
            love.graphics.rectangle("fill", 0, y, WIDTH, crtEffect.scanlineHeight)
        end
    end
    
    -- Dunklere vertikale Linien
    love.graphics.setColor(0, 0, 0, 0.1)
    for x = 0, WIDTH, 4 do
        love.graphics.line(x, 0, x, HEIGHT)
    end
    
    -- Glitch Effekt
    if crtEffect.glitchDuration > 0 then
        -- Horizontale Verschiebung
        love.graphics.setColor(1, 1, 1, 0.1)
        local glitchY = math.random(0, HEIGHT)
        local glitchHeight = math.random(10, 30)
        love.graphics.rectangle("fill", 
            crtEffect.glitchOffset, 
            glitchY, 
            WIDTH, 
            glitchHeight
        )
        
        -- RGB Split mit stärkerem Effekt
        if math.random() < 0.3 then
            love.graphics.setColor(1, 0, 0, 0.3)  -- Stärkeres Rot
            love.graphics.rectangle("fill", 
                crtEffect.glitchOffset + 8,  -- Größerer Offset
                glitchY + 8, 
                WIDTH, 
                glitchHeight
            )
            love.graphics.setColor(0, 1, 0, 0.3)  -- Stärkeres Grün
            love.graphics.rectangle("fill", 
                crtEffect.glitchOffset - 8, 
                glitchY - 8, 
                WIDTH, 
                glitchHeight
            )
        end
    end
end

function love.gamepadpressed(joystick, button)
    if button == "a" then  -- A-Button zum Schießen
        if gameState == "game" then
            shoot()
        end
    elseif button == "start" then  -- Start/Menü-Button
        if gameState == "menu" then
            gameState = "game"
            resetGame()
        elseif gameState == "gameover" then
            gameState = "game"
            resetGame()
        end
    end
end

-- Gamepad Verbindungs-Events
function love.joystickadded(joystick)
    gamepad.device = joystick
    gamepad.connected = true
end

function love.joystickremoved(joystick)
    if gamepad.device == joystick then
        gamepad.connected = false
    end
end

function love.quit()
    if apmPipe then
        apmPipe:close()
    end
end

-- Füge diese Garbage Collection Funktion hinzu
function manualGarbageCollection()
    -- Collect garbage periodically to prevent memory buildup
    collectgarbage("collect")
end

function spawnNewAsteroids(dt)
    if #asteroids < MAX_ASTEROIDS and #asteroids < MAX_ASTEROIDS_TOTAL then
        if math.random() < 0.05 then
            createPowerup()
        else
            -- Normaler Asteroiden-Spawn Code
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

function splitAsteroid(index)
    local asteroid = asteroids[index]
    
    -- Neue kleinere Asteroiden erstellen
    local newSize = asteroid.radius * 0.6
    if newSize >= MIN_ASTEROID_SIZE then
        -- Erstelle 2 kleinere Asteroiden mit unterschiedlichen Winkeln
        for i = 1, 2 do
            local angle = math.random() * 2 * math.pi  -- Zufälliger Winkel
            local speed = math.random(50, 150)
            
            local newAsteroid = {
                x = asteroid.x + math.random(-5, 5),  -- Leichte Verschiebung
                y = asteroid.y + math.random(-5, 5),
                dx = math.cos(angle) * speed,
                dy = math.sin(angle) * speed,
                radius = newSize,
                angle = math.random() * math.pi * 2,
                spin = math.random(-4, 4),
                points = generateAsteroidPoints(newSize)
            }
            table.insert(asteroids, newAsteroid)
        end
    end
    
    -- Ursprünglichen Asteroiden entfernen
    table.remove(asteroids, index)
end 