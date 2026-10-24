-- Desktop keys. Phones use the on-screen controls.

function love.keypressed(key)
    if key == "escape" or key == "acback" then
        if state == "menu" then
            local osname = love.system.getOS()
            if osname ~= "iOS" and osname ~= "Android" then
                love.event.quit()
            end
        else
            state = "menu"
            shotInProgress = false
            handoff = 0
            aiPhase = "idle"
        end
        return
    end

    if state == "credits" then
        if key == "up" then creditsScroll = clamp(creditsScroll - 24, 0, creditsMax) end
        if key == "down" then creditsScroll = clamp(creditsScroll + 24, 0, creditsMax) end
        return
    end

    if state == "menu" then
        if key == "return" or key == "space" then startMatch("ai") end
        if key == "h" then startMatch("hotseat") end
        if key == "l" then resetCredits() end
        return
    end

    if state == "gameover" then
        if key == "return" then startMatch(matchMode) end
        return
    end

    if state ~= "playing" or not humanMayAct() then return end
    local player = currentPlayer()
    if key == "left" then
        player.angle = wrapAngle(player.angle - 4)
    elseif key == "right" then
        player.angle = wrapAngle(player.angle + 4)
    elseif key == "up" then
        player.force = clamp(player.force + 0.12, MIN_FORCE, MAX_FORCE)
    elseif key == "down" then
        player.force = clamp(player.force - 0.12, MIN_FORCE, MAX_FORCE)
    elseif key == "space" or key == "return" then
        playerPressedShootButton()
    elseif key == "1" then
        bulType = 1
    elseif key == "2" then
        bulType = 2
    elseif key == "3" then
        bulType = 3
    elseif key == "n" then
        newMap()
        beginTurn()
    end
end
