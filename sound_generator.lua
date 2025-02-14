function love.load()
    -- Shoot Sound
    local sample_rate = 44100
    local duration = 0.1
    local samples = {}
    
    for i = 1, sample_rate * duration do
        local t = (i-1) / sample_rate
        local freq = 440 * math.exp(-t * 10)
        samples[i] = math.sin(2 * math.pi * freq * t) * math.exp(-t * 10)
    end
    
    love.sound.newSoundData("shoot.wav", samples, sample_rate, 16, 1)
    
    -- Explosion Sound
    samples = {}
    duration = 0.2
    
    for i = 1, sample_rate * duration do
        local t = (i-1) / sample_rate
        local noise = math.random() * 2 - 1
        local freq = 220 * math.exp(-t * 5)
        local tone = math.sin(2 * math.pi * freq * t)
        samples[i] = (noise * 0.3 + tone * 0.7) * math.exp(-t * 5)
    end
    
    love.sound.newSoundData("explosion.wav", samples, sample_rate, 16, 1)
    
    love.event.quit()
end 