-- Pointer controls. LÖVE also synthesizes mouse events from the primary touch.

function humanMayAct()
    if state ~= "playing" or shotInProgress or handoff > 0 then return false end
    if matchMode == "ai" and turn == 2 then return false end
    return true
end

function applySlider(x)
    local t = clamp((x - slider.x) / math.max(1, slider.w), 0, 1)
    currentPlayer().force = MIN_FORCE + t * (MAX_FORCE - MIN_FORCE)
end

function applyAim(x, y)
    local player = currentPlayer()
    local angle = math.deg(math.atan2(y - player.y, x - player.x))
    player.angle = wrapAngle(angle)
    local reach = dist(player.x, player.y, x, y)
    player.force = clamp(reach / 70, MIN_FORCE, MAX_FORCE)
end

function activateButton(button)
    if button.id == "ai" then
        startMatch("ai")
    elseif button.id == "hotseat" then
        startMatch("hotseat")
    elseif button.id == "credits" then
        resetCredits()
    elseif button.id == "back" or button.id == "menu" or button.id == "tomenu" then
        state = "menu"
        shotInProgress = false
        handoff = 0
        aiPhase = "idle"
    elseif button.id == "rematch" then
        startMatch(matchMode)
    elseif button.id == "fire" then
        playerPressedShootButton()
    elseif button.id == "type" then
        if humanMayAct() then
            bulType = bulType % 3 + 1
        end
    elseif button.id == "anglem" then
        if humanMayAct() then
            currentPlayer().angle = wrapAngle(currentPlayer().angle - 6)
        end
    elseif button.id == "anglep" then
        if humanMayAct() then
            currentPlayer().angle = wrapAngle(currentPlayer().angle + 6)
        end
    end
end

function love.mousepressed(x, y, button)
    if not layoutReady or button ~= 1 then return end
    layoutButtons()
    local lx, ly = screenToLogical(x, y)
    pointer.down = true
    pointer.x, pointer.y = lx, ly
    pointer.mode = nil

    local hit = hitButton(lx, ly)
    if hit then
        pointer.mode = "button"
        pointer.button = hit.id
        if hit.id ~= "fire" then
            activateButton(hit)
        end
        return
    end

    if state == "playing" and pointInSlider(lx, ly) and humanMayAct() then
        pointer.mode = "slider"
        applySlider(lx)
        return
    end

    if state == "credits" then
        pointer.mode = "scroll"
        pointer.scroll = creditsScroll
        return
    end

    if state == "playing" and humanMayAct() then
        local player = currentPlayer()
        if lx > fieldL and lx < fieldR and ly > fieldT and ly < fieldB then
            pointer.mode = "aim"
            applyAim(lx, ly)
        elseif dist(lx, ly, player.x, player.y) < 120 then
            pointer.mode = "aim"
            applyAim(lx, ly)
        end
    end
end

function love.mousereleased(x, y, button)
    if button ~= 1 then return end
    if pointer.mode == "button" and pointer.button == "fire" then
        local lx, ly = screenToLogical(x, y)
        layoutButtons()
        local hit = hitButton(lx, ly)
        if hit and hit.id == "fire" then
            activateButton(hit)
        end
    end
    pointer.down = false
    pointer.mode = nil
end

function love.mousemoved(x, y)
    if not pointer.down or not layoutReady then return end
    local lx, ly = screenToLogical(x, y)
    if pointer.mode == "slider" then
        applySlider(lx)
    elseif pointer.mode == "aim" then
        applyAim(lx, ly)
    elseif pointer.mode == "scroll" then
        creditsScroll = clamp(pointer.scroll + (pointer.y - ly), 0, creditsMax)
    end
end

function love.wheelmoved(_, dy)
    if state == "credits" then
        creditsScroll = clamp(creditsScroll - dy * 28, 0, math.max(creditsMax, 0))
    end
end
