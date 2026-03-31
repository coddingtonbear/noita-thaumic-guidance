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

    local screen_w, screen_h = GuiGetScreenDimensions(gui)
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

            local sx, sy = get_pos_on_screen(ex, ey, gui)
            local is_offscreen = sx < SCREEN_INSET or sx > screen_w - SCREEN_INSET or
               sy < SCREEN_INSET or sy > screen_h - SCREEN_INSET

            if is_offscreen then
                local dist = get_distance(player_x, player_y, ex, ey)
                local has_los = not RaytraceSurfaces(player_x, player_y, ex, ey)

                -- Use player's screen position as origin, not screen center,
                -- so the ray direction matches the actual player→enemy direction
                -- regardless of camera offset.
                local origin_x, origin_y = get_pos_on_screen(player_x, player_y, gui)
                local angle = math.atan2(sy - origin_y, sx - origin_x)
                local dx = sx - origin_x
                local dy = sy - origin_y
                local max_x = math.max(origin_x, screen_w - origin_x) - EDGE_MARGIN - half_w
                local max_y = math.max(origin_y, screen_h - origin_y) - EDGE_MARGIN - half_h
                local scale_x = dx ~= 0 and max_x / math.abs(dx) or math.huge
                local scale_y = dy ~= 0 and max_y / math.abs(dy) or math.huge
                local scale = math.min(scale_x, scale_y)
                local cx = clamp(origin_x + dx * scale - half_w, EDGE_MARGIN, screen_w - EDGE_MARGIN - sprite_w)
                local cy = clamp(origin_y + dy * scale - half_h, EDGE_MARGIN, screen_h - EDGE_MARGIN - sprite_h)

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

    local screen_w, screen_h = GuiGetScreenDimensions(gui)

    local widget_list = widget_list_begin(window, 100)

    -- DEBUG: log screen dimensions and first indicator position every ~5s
    if frame - last_debug_frame >= 300 then
        last_debug_frame = frame
        local vx, vy = get_resolution(gui)
        GamePrint("screen=" .. math.floor(screen_w) .. "x" .. math.floor(screen_h)
            .. " vres=" .. math.floor(vx) .. "x" .. math.floor(vy)
            .. " sprite=" .. tostring(sprite_w) .. "x" .. tostring(sprite_h))
        if #cached_indicators > 0 then
            local ind = cached_indicators[1]
            GamePrint("ind[1] cx=" .. math.floor(ind.cx) .. " cy=" .. math.floor(ind.cy))
        end
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
