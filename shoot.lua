-- Firing and the short explosion burst.

function setBulletVelocity(bullet, force, angle)
    local tuned = force / 2
    bullet.vx = tuned * math.cos(math.rad(angle))
    bullet.vy = tuned * math.sin(math.rad(angle))
end

function spawnBullet(x, y, force, angle)
    local bullet = { x = x, y = y, vx = 0, vy = 0, dead = false }
    setBulletVelocity(bullet, force, angle)
    allBullets[#allBullets + 1] = bullet
end

function playerPressedShootButton()
    if state ~= "playing" or shotInProgress then return end
    if handoff > 0 then return end
    if matchMode == "ai" and turn == 2 and aiPhase ~= "show" and not smokeMode and not screenshotMode then
        return
    end

    local player = currentPlayer()
    player.lastAngle = player.angle
    player.lastForce = player.force
    player1.hitThisVolley = false
    player2.hitThisVolley = false
    allBullets = {}
    benign = 0
    endOfRound = false

    if turn == 1 then
        trailColor = { 0.98, 0.72, 0.38, 1 }
    else
        trailColor = { 0.45, 0.86, 0.92, 1 }
    end

    dimTrails()

    local offsets
    if bulType == 2 then
        offsets = { -8, -4, 0, 4, 8 }
    elseif bulType == 3 then
        offsets = { -18, 0, 18 }
    else
        offsets = { 0 }
    end
    for i = 1, #offsets do
        local forceJitter = 0
        if bulType == 2 then forceJitter = (i - 3) * 0.04 end
        spawnBullet(player.x, player.y, clamp(player.force + forceJitter, MIN_FORCE, MAX_FORCE), wrapAngle(player.angle + offsets[i]))
    end

    shotInProgress = true
    if love.system.vibrate then
        pcall(love.system.vibrate, 0.02)
    end
end

function explode(x, y)
    if not trailCanvas then return end
    love.graphics.setCanvas(trailCanvas)
    love.graphics.push()
    love.graphics.scale(viewScale, viewScale)
    for i = 1, 8 do
        local ox = math.random(-16, 16)
        local oy = math.random(-16, 16)
        local radius = math.random(4, 12)
        love.graphics.setColor(1, math.random() * 0.75, 0.15, 0.9)
        love.graphics.circle("fill", x + ox, y + oy, radius)
    end
    love.graphics.pop()
    love.graphics.setCanvas()

    for i = 1, 8 do
        local bullet = {
            x = x + math.random(-10, 10),
            y = y + math.random(-10, 10),
            dead = false,
        }
        setBulletVelocity(bullet, 1.1 + (i % 3) * 0.25, math.random(0, 359))
        allBullets[#allBullets + 1] = bullet
    end
end
