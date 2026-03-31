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
local last_debug_frame = -300  -- so first debug prints immediately

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

    local screen_w, screen_h = GuiGetScreenDimensions(gui)
    local half_w, half_h = sprite_w * 0.5, sprite_h * 0.5

    local enemies = EntityGetWithTag("enemy") or {}
    local indicators = {}

    -- Debug: print off-screen enemy info every 5 seconds (~300 frames)
    local frame = GameGetFrameNum()
    local should_debug = (frame - last_debug_frame) >= 300
    if should_debug then
        last_debug_frame = frame
        GamePrint("Warding debug: " .. #enemies .. " enemies, screen=" .. math.floor(screen_w) .. "x" .. math.floor(screen_h) .. ", sprite=" .. tostring(sprite_w) .. "x" .. tostring(sprite_h))
    end

    for _, enemy in ipairs(enemies) do
        local ex, ey = EntityGetTransform(enemy)
        if ex ~= nil and enemy ~= entity and
            EntityGetHerdRelationSafe(entity, enemy) < 100 then
            -- DEBUG: fog of war and invisibility checks disabled
            -- GameGetFogOfWar(ex, ey) < FOG_THRESHOLD and
            -- not IsInvisible(enemy) then

            local sx, sy = get_pos_on_screen(ex, ey, gui)
            local is_offscreen = sx < SCREEN_INSET or sx > screen_w - SCREEN_INSET or
               sy < SCREEN_INSET or sy > screen_h - SCREEN_INSET

            if should_debug then
                local name = GameTextGetTranslatedOrNot(EntityGetName(enemy))
                if name == "" then name = "Unknown" end
                -- Angle: 0 = top, clockwise
                local deg = (math.deg(math.atan2(sx - screen_w * 0.5, -(sy - screen_h * 0.5))) + 360) % 360
                GamePrint(name .. ": " .. math.floor(deg) .. "deg, screen=" .. math.floor(sx) .. "," .. math.floor(sy) .. (is_offscreen and " OFF" or " ON"))
            end

            if is_offscreen then
                local dist = get_distance(player_x, player_y, ex, ey)
                local has_los = not RaytraceSurfaces(player_x, player_y, ex, ey)

                local center_x, center_y = screen_w * 0.5, screen_h * 0.5
                local angle = math.atan2(sy - center_y, sx - center_x)
                -- Project ray from screen center toward enemy, find where it hits the screen edge
                local dx = sx - center_x
                local dy = sy - center_y
                local max_x = screen_w * 0.5 - EDGE_MARGIN - half_w
                local max_y = screen_h * 0.5 - EDGE_MARGIN - half_h
                local scale_x = dx ~= 0 and max_x / math.abs(dx) or math.huge
                local scale_y = dy ~= 0 and max_y / math.abs(dy) or math.huge
                local scale = math.min(scale_x, scale_y)
                local cx = center_x + dx * scale - half_w
                local cy = center_y + dy * scale - half_h

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
