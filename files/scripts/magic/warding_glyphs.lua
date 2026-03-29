dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local gui = gui or GuiCreate()
local window = window or window_new(gui)

local FOG_THRESHOLD = 200
local EDGE_MARGIN = 4
local SCREEN_INSET = 2  -- buffer zone to avoid flicker at screen edges
local MAX_INDICATORS = 16
local RECALC_INTERVAL = 5  -- recalculate enemy positions every N frames
local SPRITE = "mods/thaumic_guidance/files/scripts/magic/warding_glyph.png"

local DEBUG = true

local cached_indicators = {}

local function recalculate(entity)
    local player_x, player_y = EntityGetTransform(entity)
    if player_x == nil then
        cached_indicators = {}
        return
    end

    local screen_w, screen_h = GuiGetScreenDimensions(gui)

    local enemies = EntityGetWithTag("enemy") or {}
    local indicators = {}

    for _, enemy in ipairs(enemies) do
        local ex, ey = EntityGetTransform(enemy)
        if ex ~= nil and enemy ~= entity and
            EntityGetHerdRelationSafe(entity, enemy) < 100 and
            GameGetFogOfWar(ex, ey) < FOG_THRESHOLD and
            not IsInvisible(enemy) then

            local sx, sy = get_pos_on_screen(ex, ey, gui)
            if sx < SCREEN_INSET or sx > screen_w - SCREEN_INSET or
               sy < SCREEN_INSET or sy > screen_h - SCREEN_INSET then
                local dist = get_distance(player_x, player_y, ex, ey)
                local has_los = not RaytraceSurfaces(player_x, player_y, ex, ey)

                local center_x, center_y = screen_w * 0.5, screen_h * 0.5
                local cx = clamp(sx, EDGE_MARGIN, screen_w - EDGE_MARGIN)
                local cy = clamp(sy, EDGE_MARGIN, screen_h - EDGE_MARGIN)
                local angle = math.atan2(sy - center_y, sx - center_x)

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

    if GameGetFrameNum() % RECALC_INTERVAL == 0 then
        recalculate(entity)
    end

    local widget_list = widget_list_begin(window, 100)

    if DEBUG then
        local screen_w, screen_h = GuiGetScreenDimensions(gui)
        local player_sx, player_sy = get_pos_on_screen(EntityGetTransform(entity))

        -- corners: top-left, top-right, bottom-left, bottom-right
        local corners = {
            {EDGE_MARGIN, EDGE_MARGIN},
            {screen_w - EDGE_MARGIN, EDGE_MARGIN},
            {EDGE_MARGIN, screen_h - EDGE_MARGIN},
            {screen_w - EDGE_MARGIN, screen_h - EDGE_MARGIN},
        }

        for _, corner in ipairs(corners) do
            -- "10" at each corner
            local id = widget_list_id(widget_list, source)
            widget_list_insert(widget_list, GuiText, corner[1], corner[2], "10")

            -- ascending numbers along line from player screen pos to corner
            local steps = 10
            for s = 1, steps - 1 do
                local t = s / steps
                local lx = player_sx + (corner[1] - player_sx) * t
                local ly = player_sy + (corner[2] - player_sy) * t
                local id2 = widget_list_id(widget_list, source)
                widget_list_insert(widget_list, GuiText, lx, ly, tostring(s))
            end
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
        widget_list_insert(widget_list, GuiImage, id, ind.cx, ind.cy, SPRITE, 1.0, 1.0, 0, ind.angle)
    end

    widget_list_end(widget_list)
end

source()
