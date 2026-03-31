dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local gui = gui or GuiCreate()
local window = window or window_new(gui)

local FOG_THRESHOLD = 200
local EDGE_MARGIN = 20
local SCREEN_INSET = 2  -- buffer zone to avoid flicker at screen edges
local MAX_INDICATORS = 16
local RECALC_INTERVAL = 15  -- recalculate enemy positions every N frames
local SPRITE = "mods/thaumic_guidance/files/scripts/magic/warding_glyph.png"

local cached_indicators = {}
local sprite_w = nil
local sprite_h = nil
local last_debug_frame = -300
local last_recalc_frame = -RECALC_INTERVAL  -- force recalc on first run

local function recalculate(entity)
    local player_x, player_y = EntityGetTransform(entity)
    if player_x == nil then
        cached_indicators = {}
        return
    end

    if sprite_w == nil then
        sprite_w, sprite_h = GuiGetImageDimensions(gui, SPRITE)
    end

    -- GuiGetScreenDimensions returns 2x the actual GUI coordinate space,
    -- so divide by 2 to get the space that GuiImage/GuiText actually uses.
    local raw_w, raw_h = GuiGetScreenDimensions(gui)
    local gui_w, gui_h = raw_w * 0.5, raw_h * 0.5
    local half_w, half_h = sprite_w * 0.5, sprite_h * 0.5

    local enemies = EntityGetWithTag("enemy") or {}
    local indicators = {}

    for _, enemy in ipairs(enemies) do
        local ex, ey = EntityGetTransform(enemy)
        if ex ~= nil and enemy ~= entity and
            EntityGetHerdRelationSafe(entity, enemy) < 100 then
            -- DEBUG: fog of war and invisibility checks disabled
            -- GameGetFogOfWar(ex, ey) < FOG_THRESHOLD and
            -- not IsInvisible(enemy) then

            -- get_pos_on_screen returns in [0, raw_w] space; scale to GUI space
            local raw_sx, raw_sy = get_pos_on_screen(ex, ey, gui)
            local sx, sy = raw_sx * 0.5, raw_sy * 0.5
            local is_offscreen = sx < SCREEN_INSET or sx > gui_w - SCREEN_INSET or
               sy < SCREEN_INSET or sy > gui_h - SCREEN_INSET

            if is_offscreen then
                local dist = get_distance(player_x, player_y, ex, ey)
                local has_los = not RaytraceSurfaces(player_x, player_y, ex, ey)

                local raw_ox, raw_oy = get_pos_on_screen(player_x, player_y, gui)
                local origin_x, origin_y = raw_ox * 0.5, raw_oy * 0.5
                local angle = math.atan2(sy - origin_y, sx - origin_x)
                local dx = sx - origin_x
                local dy = sy - origin_y
                local max_x = math.max(origin_x, gui_w - origin_x) - EDGE_MARGIN - half_w
                local max_y = math.max(origin_y, gui_h - origin_y) - EDGE_MARGIN - half_h
                local scale_x = dx ~= 0 and max_x / math.abs(dx) or math.huge
                local scale_y = dy ~= 0 and max_y / math.abs(dy) or math.huge
                local scale = math.min(scale_x, scale_y)
                local cx = clamp(origin_x + dx * scale - half_w, EDGE_MARGIN, gui_w - EDGE_MARGIN - sprite_w)
                local cy = clamp(origin_y + dy * scale - half_h, EDGE_MARGIN, gui_h - EDGE_MARGIN - sprite_h)

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

    if frame - last_recalc_frame >= RECALC_INTERVAL then
        last_recalc_frame = frame
        recalculate(entity)
    end

    local widget_list = widget_list_begin(window, 100)

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
