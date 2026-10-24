-- On-device pilot. Samples arcs around the line to the player and keeps the closest.

function aiChooseShot()
    local shooter = player2
    local target = player1
    local base = math.deg(math.atan2(target.y - shooter.y, target.x - shooter.x))
    local best = { angle = wrapAngle(base), force = 2.2, score = -1e9, hit = false }
    local angleOffsets = { -50, -30, -16, -8, 0, 8, 16, 30, 50, 80, -80 }
    local forces = { 1.1, 1.8, 2.6, 3.6 }
    for a = 1, #angleOffsets do
        local angle = wrapAngle(base + angleOffsets[a])
        for f = 1, #forces do
            local approach, hit = simulateFlight(shooter.x, shooter.y, angle, forces[f], target, shooter)
            local score = -approach
            if hit then score = score + 500 end
            if score > best.score then
                best.angle = angle
                best.force = forces[f]
                best.score = score
                best.hit = hit
            end
        end
    end
    return best
end

function updatePilot(dt)
    if state ~= "playing" or matchMode ~= "ai" or turn ~= 2 or shotInProgress then return end
    aiTime = aiTime + dt
    if aiPhase == "think" and aiTime > 0.25 then
        aiPlan = aiChooseShot()
        player2.angle = aiPlan.angle
        player2.force = aiPlan.force
        aiPhase = "show"
        aiTime = 0
    elseif aiPhase == "show" and aiTime > 0.45 then
        playerPressedShootButton()
        aiPhase = "idle"
    end
end
