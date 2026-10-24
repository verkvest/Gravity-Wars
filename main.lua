require "globals"
require "logic"
require "shoot"
require "ai"
require "credits"
require "ui"
require "touch"
require "keyboard"

function love.load()
    love.graphics.setBackgroundColor(0.035, 0.05, 0.09)
    love.keyboard.setKeyRepeat(true)
    math.randomseed(os.time())
    loadExternalAssets()
    screenshotMode = os.getenv("CINDARC_SCREENSHOT") == "1"
    smokeMode = os.getenv("CINDARC_SMOKE") == "1"
    if screenshotMode then math.randomseed(7) end
    refreshLayout()
    print("SAVE_DIR=" .. tostring(love.filesystem.getSaveDirectory()))
    if smokeMode then
        startMatch("ai")
        local plan = aiChooseShot()
        print(string.format("SMOKE_AI angle=%.1f force=%.2f", plan.angle, plan.force))
        player1.angle = 16
        player1.force = 2.3
        playerPressedShootButton()
    end
end

function love.resize()
    refreshLayout()
end

function updateScreenshot(dt)
    screenshotSteps = screenshotSteps + 1
    if screenshotPhase == "menu" then
        if screenshotSteps == 3 then
            love.graphics.captureScreenshot("menu.png")
        elseif screenshotSteps == 6 then
            math.randomseed(7)
            startMatch("hotseat")
            player1.angle = 12
            player1.force = 2.5
            bulType = 2
            handoff = 0
            playerPressedShootButton()
            screenshotPhase = "play"
            screenshotSteps = 0
        end
    elseif screenshotPhase == "play" then
        if shotInProgress then stepVolley() end
        if screenshotSteps == 70 then
            love.graphics.captureScreenshot("gameplay.png")
        elseif screenshotSteps > 80 then
            print("SCREENSHOTS_DONE")
            love.event.quit(0)
        end
    end
end

function love.update(dt)
    if not layoutReady then
        if not refreshLayout() then return end
    end
    layoutButtons()
    if screenshotMode then
        updateScreenshot(dt)
        return
    end
    if smokeMode then
        smokeSteps = smokeSteps + 1
        if shotInProgress then stepVolley() end
        if smokeSteps == 5 then state = "credits" end
        if smokeSteps == 8 then state = "playing" end
        if smokeSteps == 30 and state == "playing" and not shotInProgress then
            playerPressedShootButton()
        end
        if smokeSteps > 180 then
            print("SMOKE_OK")
            love.event.quit(0)
        end
        return
    end

    if handoff > 0 then
        handoff = math.max(0, handoff - dt)
    end
    updatePilot(dt)

    if shotInProgress then
        stepAccum = stepAccum + dt
        local steps = 0
        while stepAccum >= 1 / 60 and steps < 3 do
            stepAccum = stepAccum - 1 / 60
            stepVolley()
            steps = steps + 1
            if not shotInProgress then break end
        end
    else
        stepAccum = 0
    end
end

function love.draw()
    drawFrame()
end
