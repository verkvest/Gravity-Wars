-- Map generation, gravity step, and collisions.

function killBullet(bullet)
    bullet.dead = true
    bullet.vx = 0
    bullet.vy = 0
end

function clearTrails()
    if not trailCanvas then return end
    love.graphics.setCanvas(trailCanvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setCanvas()
end

function dimTrails()
    if not trailCanvas then return end
    love.graphics.setCanvas(trailCanvas)
    love.graphics.setColor(0.03, 0.04, 0.08, 0.38)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    love.graphics.setCanvas()
end

function positionsOk()
    for i = 1, #allPlanets do
        local a = allPlanets[i]
        if a.x - a.r < fieldL or a.x + a.r > fieldR or a.y - a.r < fieldT or a.y + a.r > fieldB then
            return false
        end
        for j = 1, i - 1 do
            local b = allPlanets[j]
            if dist(a.x, a.y, b.x, b.y) < a.r + b.r + 28 then
                return false
            end
        end
        if dist(a.x, a.y, player1.x, player1.y) < a.r + 36 then return false end
        if dist(a.x, a.y, player2.x, player2.y) < a.r + 36 then return false end
    end
    if dist(player1.x, player1.y, player2.x, player2.y) < 90 then return false end
    return true
end

function irand(minValue, maxValue)
    minValue = math.floor(minValue)
    maxValue = math.floor(maxValue)
    if maxValue < minValue then maxValue = minValue end
    return math.random(minValue, maxValue)
end

function randomShip(minX, maxX)
    local minY = fieldT + 24
    local maxY = fieldB - 24
    return irand(minX, maxX), irand(minY, maxY)
end

function newMap()
    allBullets = {}
    shotInProgress = false
    endOfRound = false
    benign = 0
    player1.health = 100
    player2.health = 100
    player1.hitThisVolley = false
    player2.hitThisVolley = false
    player1.angle = 18
    player2.angle = 198
    player1.lastAngle = nil
    player1.lastForce = nil
    player2.lastAngle = nil
    player2.lastForce = nil

        local mid = (fieldL + fieldR) / 2
        local placed = false
        for _ = 1, 40 do
            allPlanets = {}
            player1.x, player1.y = randomShip(fieldL + 28, math.max(fieldL + 28, mid - 70))
            player2.x, player2.y = randomShip(math.min(fieldR - 28, mid + 70), fieldR - 28)
            for i = 1, numOfPlanets do
                local radius = math.random(16, 34)
                allPlanets[i] = {
                    x = irand(fieldL + radius, fieldR - radius),
                    y = irand(fieldT + radius, fieldB - radius),
                    r = radius,
                    mass = math.random(8, 32) * 10,
                }
            end
        if positionsOk() then
            placed = true
            break
        end
    end
    if not placed then
        -- Last attempt is still playable; overlap is rare after 40 tries.
    end
    clearTrails()
end

function startMatch(mode)
    matchMode = mode
    turn = 1
    bulType = 1
    player1.lives = 3
    player2.lives = 3
    handoff = 0
    aiPhase = "idle"
    aiPlan = nil
    state = "playing"
    newMap()
    beginTurn()
end

function beginTurn()
    aiPhase = "idle"
    aiTime = 0
    aiPlan = nil
    if state ~= "playing" then return end
    if matchMode == "ai" and turn == 2 then
        aiPhase = "think"
        aiTime = 0
    elseif matchMode == "hotseat" and not screenshotMode then
        handoff = 0.9
    end
end

function finishVolley()
    shotInProgress = false
    if player1.lives <= 0 or player2.lives <= 0 then
        state = "gameover"
        aiPhase = "idle"
        handoff = 0
        return
    end
    turn = 3 - turn
    if endOfRound then
        endOfRound = false
        newMap()
    end
    beginTurn()
end

function drawTrailSegment(x1, y1, x2, y2, r, g, b)
    if not trailCanvas then return end
    love.graphics.setCanvas(trailCanvas)
    love.graphics.push()
    love.graphics.scale(viewScale, viewScale)
    love.graphics.setColor(r, g, b, 0.95)
    love.graphics.setLineWidth(1.6)
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.pop()
    love.graphics.setCanvas()
end

function stepBullet(bullet, shouldDraw)
    if bullet.dead then return end
    if bullet.x < fieldL - 30 or bullet.x > fieldR + 30 or bullet.y < fieldT - 40 or bullet.y > fieldB + 40 then
        killBullet(bullet)
        return
    end

    local vfx, vfy = 0, 0
    for i = 1, #allPlanets do
        local planet = allPlanets[i]
        local xDiff = planet.x - bullet.x
        local yDiff = planet.y - bullet.y
        local dist2 = xDiff * xDiff + yDiff * yDiff
        local distance = math.sqrt(dist2)
        if distance < 0.001 then distance = 0.001 end
        local invCube = 1 / (distance * distance * distance)
        vfx = vfx + xDiff * invCube * planet.mass
        vfy = vfy + yDiff * invCube * planet.mass
    end

    vfx = vfx + bullet.vx
    vfy = vfy + bullet.vy
    bullet.vx = vfx
    bullet.vy = vfy

    local nx = bullet.x + vfx
    local ny = bullet.y + vfy
    if shouldDraw then
        drawTrailSegment(bullet.x, bullet.y, nx, ny, trailColor[1], trailColor[2], trailColor[3])
    end
    bullet.x = nx
    bullet.y = ny

    for i = 1, #allPlanets do
        local planet = allPlanets[i]
        if dist(planet.x, planet.y, bullet.x, bullet.y) < planet.r then
            killBullet(bullet)
            return
        end
    end
end

function damagePlayer(player, bullet)
    if bullet.dead or player.hitThisVolley then return end
    if player.x < -100 then return end
    local distance = dist(player.x, player.y, bullet.x, bullet.y)
    if benign > 50 and distance < player.health then
        player.health = distance
    end
    if benign > 50 and distance < HIT_R then
        player.hitThisVolley = true
        player.lives = player.lives - 1
        player.health = 0
        endOfRound = true
        local ex, ey = player.x, player.y
        player.x = -400
        player.y = -400
        explode(ex, ey)
    end
end

function stepVolley()
    if not shotInProgress then return end
    benign = benign + 1
    for i = 1, #allBullets do
        local bullet = allBullets[i]
        if not bullet.dead then
            stepBullet(bullet, true)
            damagePlayer(player1, bullet)
            damagePlayer(player2, bullet)
        end
    end
    local any = false
    for i = 1, #allBullets do
        if not allBullets[i].dead then
            any = true
            break
        end
    end
    if not any then
        finishVolley()
    end
end

-- Headless flight used by the pilot. Returns the closest approach to the target.
function simulateFlight(originX, originY, angle, force, target, shooter)
    local bullet = {
        x = originX,
        y = originY,
        vx = (force / 2) * math.cos(math.rad(angle)),
        vy = (force / 2) * math.sin(math.rad(angle)),
        dead = false,
    }
    local best = 1e9
    for step = 1, 260 do
        if bullet.x < fieldL - 30 or bullet.x > fieldR + 30 or bullet.y < fieldT - 40 or bullet.y > fieldB + 40 then
            break
        end
        local vfx, vfy = 0, 0
        local hitPlanet = false
        for i = 1, #allPlanets do
            local planet = allPlanets[i]
            local xDiff = planet.x - bullet.x
            local yDiff = planet.y - bullet.y
            local distance = math.sqrt(xDiff * xDiff + yDiff * yDiff)
            if distance < planet.r then
                hitPlanet = true
                break
            end
            if distance < 0.001 then distance = 0.001 end
            local invCube = 1 / (distance * distance * distance)
            vfx = vfx + xDiff * invCube * planet.mass
            vfy = vfy + yDiff * invCube * planet.mass
        end
        if hitPlanet then break end
        vfx = vfx + bullet.vx
        vfy = vfy + bullet.vy
        bullet.vx = vfx
        bullet.vy = vfy
        bullet.x = bullet.x + vfx
        bullet.y = bullet.y + vfy
        local approach = dist(bullet.x, bullet.y, target.x, target.y)
        if approach < best then best = approach end
        if approach < HIT_R then return best, true end
        if step > 50 and dist(bullet.x, bullet.y, shooter.x, shooter.y) < HIT_R then
            return 1e9, false
        end
    end
    return best, false
end
