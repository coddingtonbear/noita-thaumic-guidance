dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local gui = gui or GuiCreate()
local window = window or window_new(gui)

local FOG_THRESHOLD = 200
local EDGE_MARGIN = 15
local SCREEN_INSET = 2  -- buffer zone to avoid flicker at screen edges
local MAX_INDICATORS = 16
local RECALC_INTERVAL = 15  -- recalculate enemy positions every N frames
local SPRITE = "mods/thaumic_guidance/files/scripts/magic/warding_glyph.png"

local cached_indicators = {}
local sprite_w = nil
local sprite_h = nil
local last_recalc_frame = -RECALC_INTERVAL  -- force recalc on first run

-- gui_w/gui_h are read inside source() after GuiStartFrame and cached here for recalculate()
local gui_w = 0
local gui_h = 0

local function recalculate(entity)
    local player_x, player_y = EntityGetTransform(entity)
    if player_x == nil or gui_w == 0 then
        cached_indicators = {}
        return
    end

    if sprite_w == nil then
        sprite_w, sprite_h = GuiGetImageDimensions(gui, SPRITE)
    end

    local half_w, half_h = sprite_w * 0.5, sprite_h * 0.5

    local enemies = EntityGetWithTag("enemy") or {}
    local indicators = {}

    for _, enemy in ipairs(enemies) do
        local ex, ey = EntityGetTransform(enemy)
        if ex ~= nil and enemy ~= entity and
            EntityGetHerdRelationSafe(entity, enemy) < 100 and
            GameGetFogOfWar(ex, ey) < FOG_THRESHOLD and
            not IsInvisible(enemy) then

            local sx, sy = get_pos_on_screen(ex, ey, gui)
            local is_offscreen = sx < SCREEN_INSET or sx > gui_w - SCREEN_INSET or
               sy < SCREEN_INSET or sy > gui_h - SCREEN_INSET

            if is_offscreen then
                local dist = get_distance(player_x, player_y, ex, ey)
                local has_los = not RaytraceSurfaces(player_x, player_y, ex, ey)

                local origin_x, origin_y = get_pos_on_screen(player_x, player_y, gui)
                local angle = math.atan2(sy - origin_y, sx - origin_x)
                local dx = sx - origin_x
                local dy = sy - origin_y
                -- Directional ray-edge intersection: find t such that
                -- origin + t*d hits the screen boundary in the direction of travel
                local bound_x = dx > 0 and (gui_w - EDGE_MARGIN - half_w) or (EDGE_MARGIN + half_w)
                local bound_y = dy > 0 and (gui_h - EDGE_MARGIN - half_h) or (EDGE_MARGIN + half_h)
                local t_x = dx ~= 0 and (bound_x - origin_x) / dx or math.huge
                local t_y = dy ~= 0 and (bound_y - origin_y) / dy or math.huge
                local t = math.min(t_x, t_y)
                local cx = origin_x + dx * t - half_w
                local cy = origin_y + dy * t - half_h

                indicators[#indicators + 1] = {
                    cx = cx, cy = cy,
                    angle = angle,
                    has_los = has_los,
                    distance = dist,
                }
            end
        end
    end

    table.sort(indicators, function(a, b) return a.distance < b.distance end)
    cached_indicators = indicators
end

function source()
    local entity = GetUpdatedEntityID()
    local frame = GameGetFrameNum() or 0

    local widget_list = widget_list_begin(window, 100)

    -- Read dimensions after GuiStartFrame (called by widget_list_begin) for consistent values
    gui_w, gui_h = GuiGetScreenDimensions(gui)

    if frame - last_recalc_frame >= RECALC_INTERVAL then
        last_recalc_frame = frame
        recalculate(entity)
    end

    for i = 1, math.min(#cached_indicators, MAX_INDICATORS) do
        local ind = cached_indicators[i]

        if ind.has_los then
            widget_list_insert(widget_list, GuiColorSetForNextWidget, 1.0, 0.3, 0.1, 1.0)
        else
            widget_list_insert(widget_list, GuiColorSetForNextWidget, 0.4, 0.4, 0.6, 0.6)
        end

        local id = widget_list_id(widget_list, source)
        widget_list_insert(widget_list, GuiImage, id, ind.cx, ind.cy, SPRITE, 1.0, 1.0, 1.0, ind.angle)
    end

    widget_list_end(widget_list)
end

source()
