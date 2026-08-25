-- Hyprland config driving caelestia-shell, with omarchy-style keybinds.
-- Workspace/resize keys use `code:NN` like omarchy does, so they stay on the
-- same physical keys under the fr/azerty layout.

local terminal = "ghostty"
local browser = "helium"
local fileManager = "nautilus"
local cursorTheme = "Adwaita"
local cursorSize = 24

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("XCURSOR_THEME", cursorTheme)
hl.env("XCURSOR_SIZE", cursorSize)

hl.config({
    general = {
        layout = "dwindle",
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
    },
    dwindle = {
        preserve_split = true,
        smart_resizing = true,
    },
    decoration = {
        rounding = 10,
    },
    input = {
        kb_layout = "fr",
        kb_variant = "azerty",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
        },
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor " .. cursorTheme .. " " .. cursorSize)
    hl.exec_cmd("caelestia shell -d")
end)

local locked = { locked = true }
local mouse = { mouse = true }
local repeating = { repeating = true }
local locked_repeating = { locked = true, repeating = true }

-- Apps
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + F", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + N", hl.dsp.exec_cmd(terminal .. " -e nvim"))
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal .. " -e btop"))

-- Shell
hl.bind("SUPER + Space", hl.dsp.global("caelestia:launcher"))
hl.bind("SUPER + Escape", hl.dsp.global("caelestia:session"))
hl.bind("CTRL + SUPER + L", hl.dsp.global("caelestia:lock"))
hl.bind("SUPER + Comma", hl.dsp.global("caelestia:clearNotifs"), locked)
hl.bind("SUPER + V", hl.dsp.exec_cmd("caelestia clipboard"))
hl.bind("CTRL + SUPER + E", hl.dsp.exec_cmd("caelestia emoji -p"))

-- Windows
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + V", hl.dsp.window.float())
hl.bind("SHIFT + F11", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("ALT + F11", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), mouse)
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), mouse)

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
    hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), repeating)
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), repeating)
hl.bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), repeating)
hl.bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), repeating)

hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), repeating)
hl.bind("SHIFT + ALT + Tab", hl.dsp.window.cycle_next({ next = false }), repeating)

-- Workspaces
for i = 1, 10 do
    local key = "code:" .. (9 + i) -- code:10 is the `1` key, code:19 the `0` key
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "+1" }), repeating)
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "-1" }), repeating)
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "-1" }))

-- Captures
hl.bind("Print", hl.dsp.exec_cmd("caelestia screenshot"), locked)
hl.bind("SUPER + SHIFT + S", hl.dsp.global("caelestia:screenshot"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"))

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), locked)
hl.bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), locked)

-- Media
hl.bind("XF86AudioPlay", hl.dsp.global("caelestia:mediaToggle"), locked)
hl.bind("XF86AudioPause", hl.dsp.global("caelestia:mediaToggle"), locked)
hl.bind("XF86AudioNext", hl.dsp.global("caelestia:mediaNext"), locked)
hl.bind("XF86AudioPrev", hl.dsp.global("caelestia:mediaPrev"), locked)

-- Volume
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    locked_repeating
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    locked_repeating
)
