-- Hyprland config. Hyprland >= 0.57 only reads Lua.
--
-- Managed by nix-home (desktop/hypr/hyprland.lua) and linked into
-- ~/.config/hypr, so edits on the machine are replaced on the next switch.
-- Reference: https://wiki.hypr.land/configuring/
--
-- Keys follow macOS: CMD is the main modifier and CMD+C/V/T/W/... are
-- translated to what Linux apps expect (CTRL+..., or CTRL+SHIFT+... in
-- terminals). Window management sits on CTRL+CMD, workspaces ("Spaces") on
-- CTRL, like macOS.

local terminal  = "uwsm app -- kitty"
local launcher  = "fuzzel"
local powermenu = "powermenu"
local shots     = "mkdir -p ~/Pictures/Screenshots && hyprshot -o ~/Pictures/Screenshots"

local terminals = { kitty = true, foot = true, Alacritty = true, ["com.mitchellh.ghostty"] = true }


------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 3,
        gaps_out    = 6,
        border_size = 2,
        col = {
            active_border   = "rgba(89b4faee)",
            inactive_border = "rgba(45475aaa)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        shadow = { enabled = false },
        blur   = { enabled = false }, -- saves battery and GPU on the old Air
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        background_color        = 0xff1e1e2e,
        -- wake the screen on key press / mouse move after it went dark
        key_press_enables_dpms   = true,
        mouse_move_enables_dpms  = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.animation({ leaf = "global",     enabled = true, speed = 6, bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout    = "us",
        repeat_rate  = 40,
        repeat_delay = 250,
        follow_mouse = 1,

        touchpad = {
            natural_scroll       = true, -- content follows the fingers, like macOS
            clickfinger_behavior = true, -- two-finger click = right click
            disable_while_typing = true,
            scroll_factor        = 0.5,
        },
    },
})

-- three-finger swipe switches workspaces, like Spaces on macOS
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


------------------------
---- WINDOW RULES -----
------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "float-small-tools",
    match = { class = "^(org.pulseaudio.pavucontrol|.blueman-manager-wrapped|nm-connection-editor)$" },
    float = true,
})


-----------------
---- HELPERS ----
-----------------

local function in_terminal()
    local w = hl.get_active_window()
    return w ~= nil and terminals[w.class] == true
end

local function send(mods, key)
    hl.dispatch(hl.dsp.send_shortcut({ mods = mods, key = key, window = "activewindow" }))
end

-- CMD+<combo>: send `app` to normal apps and `term` to terminals.
-- Each is { mods, key }; nil means "do nothing" there.
local function mac(combo, app, term)
    hl.bind("SUPER + " .. combo, function()
        local target = in_terminal() and term or app
        if target then send(target[1], target[2]) end
    end, { repeating = true })
end

local function alt(combo, app, term)
    hl.bind("ALT + " .. combo, function()
        local target = in_terminal() and term or app
        if target then send(target[1], target[2]) end
    end, { repeating = true })
end


-------------------------------------
---- macOS-STYLE APP SHORTCUTS -----
-------------------------------------
-- terminal column: kitty's defaults; nil where the CTRL key would do
-- something unwanted in a shell (CTRL+Z suspends, CTRL+S freezes, ...)

--   combo              apps                          terminals
mac("C",                { "CTRL", "C" },              { "CTRL SHIFT", "C" })     -- copy
mac("V",                { "CTRL", "V" },              { "CTRL SHIFT", "V" })     -- paste
mac("X",                { "CTRL", "X" },              nil)                       -- cut
mac("Z",                { "CTRL", "Z" },              nil)                       -- undo
mac("SHIFT + Z",        { "CTRL SHIFT", "Z" },        nil)                       -- redo
mac("A",                { "CTRL", "A" },              nil)                       -- select all
mac("S",                { "CTRL", "S" },              nil)                       -- save
mac("SHIFT + S",        { "CTRL SHIFT", "S" },        nil)                       -- save as
mac("O",                { "CTRL", "O" },              nil)                       -- open
mac("P",                { "CTRL", "P" },              nil)                       -- print
mac("F",                { "CTRL", "F" },              nil)                       -- find
mac("G",                { "CTRL", "G" },              nil)                       -- find next
mac("N",                { "CTRL", "N" },              { "CTRL SHIFT", "N" })     -- new window
mac("T",                { "CTRL", "T" },              { "CTRL SHIFT", "T" })     -- new tab
mac("SHIFT + T",        { "CTRL SHIFT", "T" },        nil)                       -- reopen closed tab
mac("W",                { "CTRL", "W" },              { "CTRL SHIFT", "W" })     -- close tab
mac("R",                { "CTRL", "R" },              nil)                       -- reload
mac("L",                { "CTRL", "L" },              nil)                       -- address bar
mac("K",                { "CTRL", "K" },              { "CTRL SHIFT", "Delete" }) -- search / clear terminal
mac("comma",            { "CTRL", "comma" },          nil)                       -- preferences
mac("equal",            { "CTRL", "equal" },          { "CTRL SHIFT", "equal" }) -- zoom in
mac("minus",            { "CTRL", "minus" },          { "CTRL SHIFT", "minus" }) -- zoom out
mac("0",                { "CTRL", "0" },              { "CTRL SHIFT", "BackSpace" }) -- reset zoom
mac("bracketleft",      { "ALT", "Left" },            nil)                       -- back
mac("bracketright",     { "ALT", "Right" },           nil)                       -- forward
mac("SHIFT + bracketleft",  { "CTRL SHIFT", "Tab" },  { "CTRL SHIFT", "Left" })  -- previous tab
mac("SHIFT + bracketright", { "CTRL", "Tab" },        { "CTRL SHIFT", "Right" }) -- next tab

for i = 1, 9 do
    mac(tostring(i), { "CTRL", tostring(i) }, nil)                               -- go to tab N
end

-- text navigation: CMD+arrows = line/document, ALT(option)+arrows = word
mac("left",             { "", "Home" },               { "", "Home" })
mac("right",            { "", "End" },                { "", "End" })
mac("up",               { "CTRL", "Home" },           nil)
mac("down",             { "CTRL", "End" },            nil)
mac("SHIFT + left",     { "SHIFT", "Home" },          nil)
mac("SHIFT + right",    { "SHIFT", "End" },           nil)
mac("SHIFT + up",       { "CTRL SHIFT", "Home" },     nil)
mac("SHIFT + down",     { "CTRL SHIFT", "End" },      nil)

alt("left",             { "CTRL", "Left" },           { "ALT", "b" })
alt("right",            { "CTRL", "Right" },          { "ALT", "f" })
alt("SHIFT + left",     { "CTRL SHIFT", "Left" },     nil)
alt("SHIFT + right",    { "CTRL SHIFT", "Right" },    nil)
alt("BackSpace",        { "CTRL", "BackSpace" },      { "ALT", "BackSpace" })


------------------------------
---- SYSTEM / WINDOW KEYS ----
------------------------------

hl.bind("SUPER + space",          hl.dsp.exec_cmd(launcher))                 -- Spotlight
hl.bind("SUPER + Return",         hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + Q",              hl.dsp.window.close())                     -- quit (closes the window)
hl.bind("SUPER + ALT + Escape",   hl.dsp.window.kill())                      -- force quit
hl.bind("SUPER + SHIFT + Q",      hl.dsp.exec_cmd(powermenu))                -- log out / restart / shut down
hl.bind("CTRL + SUPER + Q",       hl.dsp.exec_cmd("loginctl lock-session"))  -- lock screen

-- CMD+Tab cycles windows
hl.bind("SUPER + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = true }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind("SUPER + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- CMD+M minimizes into a hidden workspace, CMD+SHIFT+M shows it
hl.bind("SUPER + M",              hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
hl.bind("SUPER + SHIFT + M",      hl.dsp.workspace.toggle_special("minimized"))

-- CTRL+CMD = window management
hl.bind("CTRL + SUPER + F",       hl.dsp.window.fullscreen())
hl.bind("CTRL + SUPER + T",       hl.dsp.window.float({ action = "toggle" })) -- tile / float
hl.bind("CTRL + SUPER + J",       hl.dsp.layout("togglesplit"))
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("CTRL + SUPER + " .. dir,         hl.dsp.focus({ direction = dir }))
    hl.bind("CTRL + SUPER + SHIFT + " .. dir, hl.dsp.window.swap({ direction = dir }))
end

-- CTRL = workspaces ("Spaces")
hl.bind("CTRL + left",            hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + right",           hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SHIFT + left",    hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("CTRL + SHIFT + right",   hl.dsp.window.move({ workspace = "r+1" }))
for i = 1, 9 do
    hl.bind("CTRL + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind("CTRL + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- mouse: CMD+drag moves, CMD+right-drag resizes
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- screenshots like macOS: saved to ~/Pictures/Screenshots and copied;
-- add CTRL to only copy to the clipboard
hl.bind("SUPER + SHIFT + 3",        hl.dsp.exec_cmd(shots .. " -m output"))
hl.bind("SUPER + SHIFT + 4",        hl.dsp.exec_cmd(shots .. " -m region"))
hl.bind("SUPER + SHIFT + 5",        hl.dsp.exec_cmd(shots .. " -m window"))
hl.bind("CTRL + SUPER + SHIFT + 3", hl.dsp.exec_cmd("hyprshot --clipboard-only -m output"))
hl.bind("CTRL + SUPER + SHIFT + 4", hl.dsp.exec_cmd("hyprshot --clipboard-only -m region"))
hl.bind("CTRL + SUPER + SHIFT + 5", hl.dsp.exec_cmd("hyprshot --clipboard-only -m window"))


----------------------
---- HARDWARE KEYS ---
----------------------

local hw = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), hw)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), hw)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), hw)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), hw)
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight set 10%+"), hw)
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight set 10%-"), hw)
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"), { locked = true })
