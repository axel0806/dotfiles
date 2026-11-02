-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 1,

        col = {
            -- active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            active_border   = { colors = {"rgba(6ea8d9ff)", "rgba(cdd6e0ff)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
            
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 0.9,

        shadow = {
            enabled      = true,
            range        = 10,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 20,
            passes    = 3,
            vibrancy  = 0.1696,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Quick, no-bounce animations (about 25% slower than the snappiest preset).
-- Curves from ML4W "fast" / end-4 (Material 3 emphasized easing). All control
-- points stay within 0..1, so nothing overshoots. The old spring "easy" was
-- underdamped (damping ratio ~0.78), which is what made windows wobble.
-- speed = duration in deciseconds (3 = 300 ms); lower is faster.
hl.curve("md3_decel",   { type = "bezier", points = { {0.05, 0.7}, {0.1, 1}    } })  -- fast start, soft landing
hl.curve("md3_accel",   { type = "bezier", points = { {0.3, 0},    {0.8, 0.15} } })  -- for things leaving
hl.curve("easeOutExpo", { type = "bezier", points = { {0.16, 1},   {0.3, 1}    } })
hl.curve("menu_decel",  { type = "bezier", points = { {0.1, 1},    {0, 1}      } })
hl.curve("menu_accel",  { type = "bezier", points = { {0.38, 0.04},{1, 0.07}   } })
hl.curve("linear",      { type = "bezier", points = { {0, 0},      {1, 1}      } })

hl.animation({ leaf = "global",           enabled = true, speed = 8,   bezier = "default" })
hl.animation({ leaf = "border",           enabled = true, speed = 5,   bezier = "md3_decel" })
hl.animation({ leaf = "windows",          enabled = true, speed = 3.5, bezier = "md3_decel",   style = "popin 80%" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3.5, bezier = "md3_decel",   style = "popin 80%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.3, bezier = "md3_accel",   style = "popin 90%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 3.2, bezier = "md3_decel",   style = "slide" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 2.2, bezier = "md3_accel" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3, bezier = "menu_decel",  style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2, bezier = "menu_accel",  style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2.5,   bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 2, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.8,   bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "md3_decel",   style = "slidevert" })
hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 3,   bezier = "md3_decel" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })


hl.config({
    decoration = {
        blur = {
            enabled = true,
            size = 14,
            passes = 4,
            -- blur GTK context menus and other popups too
            popups = true,
            popups_ignorealpha = 0.2,
        }
    }
})

hl.layer_rule({
    match = { namespace = "waybar" },
    name = "waybar-blur",
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    match = { namespace = "rofi" },
    name = "rofi-blur",
    blur = true,
    ignore_alpha = 0,
})

-- Border colors generated from the wallpaper by matugen
-- (~/.config/hypr/colors.lua, written by scripts/wallpaper.sh).
-- If it's missing, the borders above stay as they are.
pcall(require, "colors")
