-- Menu, playfield, and the touch HUD.

local COL_BG = { 0.035, 0.05, 0.09 }
local COL_TEAL = { 0.22, 0.78, 0.82 }
local COL_AMBER = { 0.96, 0.72, 0.32 }
local COL_INK = { 0.05, 0.07, 0.1 }
local COL_PANEL = { 0.08, 0.1, 0.16, 0.92 }

function drawRoundRect(mode, x, y, w, h, radius)
    love.graphics.rectangle(mode, x, y, w, h, radius, radius)
end

function layoutButtons()
    clearButtons()
    if not layoutReady then return end
    if state == "menu" then
        local w = math.min(320, logicalW - safeL - safeR - 40)
        local x = (logicalW - w) / 2
        local y = math.max(safeT + 168, logicalH * 0.40)
        local h = 52
        addButton("ai", x, y, w, h, "Play vs Pilot")
        addButton("hotseat", x, y + 64, w, h, "Hot-seat")
        addButton("credits", x, y + 128, w, h, "Licenses")
    elseif state == "credits" then
        addButton("back", safeL + 8, safeT + 4, 78, 34, "Back")
    elseif state == "playing" or state == "gameover" then
        addButton("menu", safeL + 4, safeT + 4, 76, 32, "Menu")
        if state == "gameover" then
            local w = math.min(280, logicalW - safeL - safeR - 48)
            local x = (logicalW - w) / 2
            local y = logicalH * 0.58
            addButton("rematch", x, y, w, 50, "Rematch")
            addButton("tomenu", x, y + 60, w, 50, "Main menu")
        else
            local y = logicalH - safeB - 62
            local h = 52
            local x = safeL
            addButton("anglem", x, y, 46, h, "-")
            x = x + 50
            angleReadoutX = x
            x = x + 74
            addButton("anglep", x, y, 46, h, "+")
            x = x + 54
            local fireW = 108
            local typeW = 92
            local right = logicalW - safeR
            addButton("fire", right - fireW, y, fireW, h, "FIRE")
            addButton("type", right - fireW - 8 - typeW, y, typeW, h, shotName())
            slider.x = x
            slider.w = math.max(36, (right - fireW - 8 - typeW - 10) - x)
            slider.y = y + 14
            slider.h = 24
        end
    end
end

function drawButton(button, fill, labelColor)
    love.graphics.setColor(fill)
    drawRoundRect("fill", button.x, button.y, button.w, button.h, 10)
    love.graphics.setColor(labelColor[1], labelColor[2], labelColor[3], 1)
    love.graphics.setFont(fontBody)
    love.graphics.printf(button.label, button.x, button.y + button.h / 2 - 11, button.w, "center")
end

function drawStars()
    for i = 1, #stars do
        local star = stars[i]
        love.graphics.setColor(0.85, 0.9, 1, star.a)
        love.graphics.circle("fill", star.x, star.y, star.r)
    end
end

function drawPlanets()
    for i = 1, #allPlanets do
        local planet = allPlanets[i]
        love.graphics.setColor(0.07, 0.09, 0.12, 1)
        love.graphics.circle("fill", planet.x, planet.y, planet.r)
        if i % 2 == 0 then
            love.graphics.setColor(COL_TEAL[1], COL_TEAL[2], COL_TEAL[3], 0.95)
        else
            love.graphics.setColor(COL_AMBER[1], COL_AMBER[2], COL_AMBER[3], 0.9)
        end
        love.graphics.setLineWidth(1.4)
        love.graphics.circle("line", planet.x, planet.y, planet.r)
    end
end

function drawShip(image, player, tint)
    if player.health <= 0 or player.x < -50 then return end
    local scale = 2.4
    love.graphics.setColor(tint[1], tint[2], tint[3], 1)
    love.graphics.draw(image, player.x, player.y, 0, scale, scale, image:getWidth() / 2, image:getHeight() / 2)
end

function drawAim(player)
    local radians = math.rad(player.angle)
    local reach = 28 + player.force * 16
    love.graphics.setColor(1, 1, 1, 0.18)
    love.graphics.circle("line", player.x, player.y, 78)
    love.graphics.setColor(1, 0.35, 0.28, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.line(player.x, player.y,
        player.x + math.cos(radians) * reach,
        player.y + math.sin(radians) * reach)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.circle("line", player.x, player.y, 8)
    if player.lastAngle then
        local old = math.rad(player.lastAngle)
        love.graphics.setColor(1, 1, 1, 0.28)
        love.graphics.setLineWidth(1.2)
        love.graphics.line(player.x, player.y,
            player.x + math.cos(old) * 78,
            player.y + math.sin(old) * 78)
    end
end

function drawLives(x, y, lives, alignRight)
    love.graphics.setColor(COL_AMBER[1], COL_AMBER[2], COL_AMBER[3], 1)
    for i = 1, math.max(0, lives) do
        local cx = alignRight and (x - (i - 1) * 16) or (x + (i - 1) * 16)
        love.graphics.circle("fill", cx, y, 5)
    end
end

function drawHealthBar(x, y, w, health, flip)
    love.graphics.setColor(0.25, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", x, y, w, 8, 3, 3)
    local fraction = clamp(health / 100, 0, 1)
    local fillW = w * fraction
    love.graphics.setColor(0.35 + (1 - fraction) * 0.6, 0.75 * fraction + 0.15, 0.28, 1)
    if flip then
        love.graphics.rectangle("fill", x + w - fillW, y, fillW, 8, 3, 3)
    else
        love.graphics.rectangle("fill", x, y, fillW, 8, 3, 3)
    end
end

function drawTopBar()
    local y = safeT + 6
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.9, 0.93, 0.96, 1)
    local label
    if shotInProgress then
        label = "In flight"
    elseif matchMode == "ai" and turn == 2 then
        label = "Pilot is aiming"
    else
        label = playerName(turn)
    end
    love.graphics.printf(label, 0, y + 6, logicalW, "center")

    local barW = math.min(140, logicalW * 0.18)
    drawHealthBar(safeL + 92, y + 22, barW, player1.health, false)
    drawHealthBar(logicalW - safeR - 92 - barW, y + 22, barW, player2.health, true)
    drawLives(safeL + 96, y + 10, player1.lives, false)
    drawLives(logicalW - safeR - 96, y + 10, player2.lives, true)

    love.graphics.setColor(COL_AMBER[1], COL_AMBER[2], COL_AMBER[3], 1)
    love.graphics.print("P1", safeL + 92, y + 2)
    love.graphics.setColor(COL_TEAL[1], COL_TEAL[2], COL_TEAL[3], 1)
    love.graphics.printf(matchMode == "ai" and "AI" or "P2", logicalW - safeR - 92 - 40, y + 2, 40, "right")
end

function drawSlider()
    local t = (currentPlayer().force - MIN_FORCE) / (MAX_FORCE - MIN_FORCE)
    love.graphics.setColor(0.15, 0.17, 0.22, 1)
    drawRoundRect("fill", slider.x, slider.y, slider.w, slider.h, 8)
    love.graphics.setColor(0.85, 0.32, 0.26, 1)
    drawRoundRect("fill", slider.x, slider.y, math.max(8, slider.w * t), slider.h, 8)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(fontSmall)
    love.graphics.printf(string.format("power %0.1f", currentPlayer().force), slider.x, slider.y + slider.h + 2, slider.w, "center")
end

function drawHUD()
    drawTopBar()
    if state ~= "playing" then return end
    local player = currentPlayer()
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1, 0.85)
    if angleReadoutX then
        love.graphics.printf(string.format("%d", math.floor(player.angle + 0.5) % 360), angleReadoutX, logicalH - safeB - 46, 70, "center")
    end
    drawSlider()
    for i = 1, #buttons do
        local button = buttons[i]
        if button.id == "fire" then
            if shotInProgress or handoff > 0 then
                drawButton(button, { 0.28, 0.16, 0.16, 1 }, { 0.7, 0.7, 0.7 })
            else
                drawButton(button, { 0.12, 0.62, 0.66, 1 }, { 0.03, 0.08, 0.1 })
            end
        elseif button.id == "menu" then
            drawButton(button, COL_PANEL, { 0.92, 0.94, 0.96 })
        elseif button.id == "anglem" or button.id == "anglep" or button.id == "type" then
            drawButton(button, { 0.12, 0.15, 0.22, 1 }, { 0.94, 0.95, 0.97 })
        end
    end
    if handoff > 0 and matchMode == "hotseat" then
        love.graphics.setColor(0.02, 0.03, 0.05, 0.55)
        love.graphics.rectangle("fill", 0, logicalH * 0.38, logicalW, 78)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBody)
        love.graphics.printf("Pass the phone  ·  " .. playerName(turn), 0, logicalH * 0.38 + 26, logicalW, "center")
    end
end

function drawPlayfield()
    drawPlanets()
    drawShip(ss1, player1, COL_AMBER)
    drawShip(ss2, player2, COL_TEAL)
    if turn == 1 then
        love.graphics.setColor(COL_AMBER[1], COL_AMBER[2], COL_AMBER[3], 0.35)
        love.graphics.circle("line", player1.x, player1.y, HIT_R + 6)
    elseif player2.x > -50 then
        love.graphics.setColor(COL_TEAL[1], COL_TEAL[2], COL_TEAL[3], 0.35)
        love.graphics.circle("line", player2.x, player2.y, HIT_R + 6)
    end
    if state == "playing" and not shotInProgress and handoff <= 0 then
        if not (matchMode == "ai" and turn == 2 and aiPhase == "think") then
            drawAim(currentPlayer())
        end
    end
end

function drawMenuScene()
    love.graphics.setColor(0.1, 0.16, 0.2, 1)
    love.graphics.circle("fill", logicalW * 0.28, logicalH * 0.72, 46)
    love.graphics.setColor(COL_AMBER[1], COL_AMBER[2], COL_AMBER[3], 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", logicalW * 0.28, logicalH * 0.72, 46)
    love.graphics.setColor(COL_TEAL[1], COL_TEAL[2], COL_TEAL[3], 0.85)
    love.graphics.circle("line", logicalW * 0.74, logicalH * 0.30, 28)
    love.graphics.setColor(0.93, 0.45, 0.28, 0.9)
    love.graphics.setLineWidth(2.5)
    love.graphics.arc("line", "open", logicalW * 0.28, logicalH * 0.72, 120, math.rad(300), math.rad(40))
end

function drawMenu()
    drawMenuScene()
    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0.96, 0.94, 0.88, 1)
    love.graphics.printf("CINDARC", safeL, safeT + 36, logicalW - safeL - safeR, "center")
    love.graphics.setFont(fontBody)
    love.graphics.setColor(COL_TEAL[1], COL_TEAL[2], COL_TEAL[3], 1)
    love.graphics.printf("gravity artillery", safeL, safeT + 108, logicalW - safeL - safeR, "center")

    for i = 1, #buttons do
        local button = buttons[i]
        if button.id == "ai" then
            drawButton(button, { 0.14, 0.62, 0.66, 1 }, COL_INK)
        else
            drawButton(button, { 0.11, 0.14, 0.2, 1 }, { 0.94, 0.95, 0.97 })
        end
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.7, 0.75, 0.8, 1)
    love.graphics.printf("Drag from your ship to aim. Distance sets power.", safeL, logicalH - safeB - 52, logicalW - safeL - safeR, "center")
    love.graphics.printf("Boris 2020 MIT   ·   LOVE zlib   ·   " .. APP_VERSION, safeL, logicalH - safeB - 28, logicalW - safeL - safeR, "center")
end

function winnerText()
    local p1 = player1.lives > 0
    local p2 = player2.lives > 0
    if p1 and not p2 then
        return matchMode == "ai" and "You win" or "Player 1 wins"
    end
    if p2 and not p1 then
        return matchMode == "ai" and "Pilot wins" or "Player 2 wins"
    end
    return "Draw"
end

function drawGameOver()
    local w = math.min(360, logicalW - 40)
    local h = 210
    local x = (logicalW - w) / 2
    local y = logicalH * 0.28
    love.graphics.setColor(0.04, 0.05, 0.08, 0.88)
    drawRoundRect("fill", x, y, w, h, 14)
    love.graphics.setColor(0.95, 0.93, 0.88, 1)
    love.graphics.setFont(fontTitle)
    love.graphics.printf(winnerText(), x, y + 28, w, "center")
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.75, 0.8, 0.84, 1)
    love.graphics.printf(string.format("lives  %d  –  %d", math.max(0, player1.lives), math.max(0, player2.lives)), x, y + 100, w, "center")
    for i = 1, #buttons do
        local button = buttons[i]
        if button.id == "rematch" then
            drawButton(button, { 0.14, 0.62, 0.66, 1 }, COL_INK)
        elseif button.id == "tomenu" or button.id == "menu" then
            drawButton(button, { 0.12, 0.15, 0.22, 1 }, { 0.94, 0.95, 0.97 })
        end
    end
end

function drawFrame()
    love.graphics.clear(COL_BG[1], COL_BG[2], COL_BG[3], 1)
    if not layoutReady then return end
    love.graphics.push()
    love.graphics.scale(viewScale, viewScale)
    drawStars()
    love.graphics.pop()

    if (state == "playing" or state == "gameover") and trailCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(trailCanvas, 0, 0)
    end

    love.graphics.push()
    love.graphics.scale(viewScale, viewScale)
    love.graphics.setLineWidth(1)
    if state == "menu" then
        drawMenu()
    elseif state == "credits" then
        drawCredits()
        for i = 1, #buttons do
            drawButton(buttons[i], COL_PANEL, { 0.95, 0.96, 0.97 })
        end
    else
        drawPlayfield()
        if state == "playing" then drawHUD() end
        if state == "gameover" then
            drawTopBar()
            for i = 1, #buttons do
                if buttons[i].id == "menu" then
                    drawButton(buttons[i], COL_PANEL, { 0.95, 0.96, 0.97 })
                end
            end
            drawGameOver()
        end
    end
    love.graphics.pop()
end
