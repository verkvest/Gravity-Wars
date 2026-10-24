-- Scrollable licenses. The full text lives in THIRD_PARTY_LICENSES.txt.

function resetCredits()
    creditsScroll = 0
    state = "credits"
end

function creditsContentHeight()
    local width = math.max(200, logicalW - safeL - safeR - 48)
    local font = fontSmall
    local wrapped = font:getWrap(creditsBody, width)
    local count = 1
    if type(wrapped) == "table" then count = math.max(1, #wrapped) end
    return count * font:getHeight() + 24
end

function drawCredits()
    love.graphics.setColor(0.93, 0.95, 0.98, 1)
    love.graphics.setFont(fontBody)
    love.graphics.print("Licenses", safeL + 96, safeT + 8)

    local x = safeL + 16
    local y = safeT + 48
    local width = logicalW - safeL - safeR - 32
    local viewH = math.max(40, logicalH - y - safeB - 12)
    love.graphics.setScissor(x * viewScale, y * viewScale, math.max(1, width * viewScale), viewH * viewScale)
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.82, 0.86, 0.9, 1)
    love.graphics.printf(creditsBody, x, y - creditsScroll, width, "left")
    love.graphics.setScissor()

    creditsMax = math.max(0, creditsContentHeight() - viewH)
    creditsScroll = clamp(creditsScroll, 0, creditsMax)
end
