-- Cindarc window and module configuration.
-- Logical gameplay is resolution-independent; this only sets the desktop window.
function love.conf(t)
    t.identity = "cindarc"
    t.appendidentity = false
    t.version = "11.0"
    t.externalstorage = true
    t.accelerometerjoystick = false
    t.gammacorrect = false

    t.window.title = "Cindarc"
    t.window.resizable = true
    t.window.minwidth = 480
    t.window.minheight = 320
    t.window.usedpiscale = false
    t.window.highdpi = true
    t.window.vsync = 1
    t.window.msaa = 0

    local shot = os.getenv("CINDARC_SCREENSHOT") == "1"
    local smoke = os.getenv("CINDARC_SMOKE") == "1"
    if shot then
        t.window.width = 2340
        t.window.height = 1080
        t.window.resizable = false
        t.window.vsync = 0
        t.window.highdpi = false
    elseif smoke then
        t.window.width = 960
        t.window.height = 540
        t.window.resizable = false
        t.window.vsync = 0
        t.window.highdpi = false
    else
        t.window.width = 1280
        t.window.height = 720
    end

    t.modules.audio = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.video = false
    t.modules.thread = false
end
