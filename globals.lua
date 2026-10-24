-- Shared state, layout, and small helpers for Cindarc.

APP_NAME = "Cindarc"
APP_VERSION = "0.1.0"
BUNDLE_ID = "es.verkvest.cindarc"
LOGICAL_H = 500
HIT_R = 14
MIN_FORCE = 0.45
MAX_FORCE = 5

screenW, screenH = 0, 0
viewScale = 1
logicalW, logicalH = 1000, LOGICAL_H
safeL, safeT, safeR, safeB = 0, 0, 0, 0
fieldL, fieldT, fieldR, fieldB = 20, 50, 980, 420
layoutReady = false
trailCanvas = nil

state = "menu" -- menu | playing | credits | gameover
matchMode = "ai" -- ai | hotseat
turn = 1
bulType = 1
shotNames = { "Needle", "Spread", "Fan" }

shotInProgress = false
endOfRound = false
benign = 0
stepAccum = 0
handoff = 0
aiPhase = "idle" -- idle | think | show
aiTime = 0
aiPlan = nil

buttons = {}
pointer = { down = false, mode = nil, x = 0, y = 0 }
slider = { x = 0, y = 0, w = 10, h = 10 }
creditsScroll = 0
creditsMax = 0

screenshotMode = false
screenshotPhase = "menu"
screenshotSteps = 0
smokeMode = false
smokeSteps = 0

numOfPlanets = 5
allPlanets = {}
allBullets = {}
stars = {}

player1 = {
    x = 180, y = 250, angle = 20, force = 2.2,
    lives = 3, health = 100, lastAngle = nil, lastForce = nil,
    hitThisVolley = false,
}
player2 = {
    x = 820, y = 250, angle = 200, force = 2.2,
    lives = 3, health = 100, lastAngle = nil, lastForce = nil,
    hitThisVolley = false,
}

trailColor = { 0.96, 0.78, 0.42, 1 }

function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function wrapAngle(angle)
    angle = angle % 360
    if angle < 0 then angle = angle + 360 end
    return angle
end

function dist(ax, ay, bx, by)
    local dx = ax - bx
    local dy = ay - by
    return math.sqrt(dx * dx + dy * dy)
end

function currentPlayer()
    if turn == 1 then return player1 end
    return player2
end

function otherPlayer()
    if turn == 1 then return player2 end
    return player1
end

function playerName(index)
    if matchMode == "ai" then
        if index == 1 then return "You" end
        return "Pilot"
    end
    if index == 1 then return "Player 1" end
    return "Player 2"
end

function shotName()
    return shotNames[bulType] or "Needle"
end

function loadExternalAssets()
    ss1 = love.graphics.newImage("assets/ss1.png")
    ss2 = love.graphics.newImage("assets/ss2.png")
    ss1:setFilter("nearest", "nearest")
    ss2:setFilter("nearest", "nearest")

    fontSmall = love.graphics.newFont("assets/basis33.ttf", 16)
    fontBody = love.graphics.newFont("assets/basis33.ttf", 22)
    fontTitle = love.graphics.newFont("assets/basis33.ttf", 68)
    fontSmall:setFilter("nearest", "nearest")
    fontBody:setFilter("nearest", "nearest")
    fontTitle:setFilter("nearest", "nearest")

    creditsBody = love.filesystem.read("THIRD_PARTY_LICENSES.txt")
    if not creditsBody then
        creditsBody = "Cindarc\nLicenses file missing from the package."
    end
end

function readSafeInsets(w, h)
    local x, y, sw, sh = 0, 0, w, h
    if love.window.getSafeArea then
        local ok, ax, ay, aw, ah = pcall(love.window.getSafeArea)
        if ok and aw and aw > 0 and ah and ah > 0 then
            x, y, sw, sh = ax, ay, aw, ah
        end
    end
    local left = x / viewScale
    local top = y / viewScale
    local right = (w - (x + sw)) / viewScale
    local bottom = (h - (y + sh)) / viewScale
    local osname = love.system.getOS()
    if osname == "iOS" or osname == "Android" then
        -- Notch / home indicator fallback when the port reports a full-bleed window.
        if left + right < 1 then
            left = math.max(left, 20)
            right = math.max(right, 20)
        end
        if top < 1 then top = 10 end
        if bottom < 1 then bottom = 16 end
    end
    return left, top, right, bottom
end

function refreshLayout()
    local w, h = love.graphics.getDimensions()
    if w < 2 or h < 2 then return false end
    local sizeChanged = (w ~= screenW or h ~= screenH or trailCanvas == nil)
    screenW, screenH = w, h
    viewScale = screenH / LOGICAL_H
    if viewScale < 0.2 then viewScale = 0.2 end
    logicalW = screenW / viewScale
    logicalH = LOGICAL_H
    safeL, safeT, safeR, safeB = readSafeInsets(w, h)

    fieldL = safeL + 18
    fieldT = safeT + 46
    fieldR = logicalW - safeR - 18
    fieldB = logicalH - safeB - 84
    if fieldR - fieldL < 220 then
        fieldL = 12
        fieldR = logicalW - 12
    end
    if fieldB - fieldT < 140 then
        fieldT = 36
        fieldB = logicalH - 78
    end

    if sizeChanged then
        local ok, canvas = pcall(love.graphics.newCanvas, screenW, screenH)
        if ok then
            trailCanvas = canvas
            trailCanvas:setFilter("linear", "linear")
        else
            trailCanvas = nil
        end
        makeStars()
    end
    layoutReady = true
    return true
end

function makeStars()
    stars = {}
    local count = 70
    for i = 1, count do
        stars[i] = {
            x = math.random() * logicalW,
            y = math.random() * logicalH,
            r = (i % 5 == 0) and 1.6 or 1.0,
            a = 0.25 + (i % 7) * 0.08,
        }
    end
end

function screenToLogical(x, y)
    return x / viewScale, y / viewScale
end

function clearButtons()
    buttons = {}
end

function addButton(id, x, y, w, h, label)
    buttons[#buttons + 1] = { id = id, x = x, y = y, w = w, h = h, label = label }
end

function hitButton(x, y)
    for i = #buttons, 1, -1 do
        local b = buttons[i]
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            return b
        end
    end
    return nil
end

function pointInSlider(x, y)
    local s = slider
    return x >= s.x and x <= s.x + s.w and y >= s.y - 10 and y <= s.y + s.h + 10
end
