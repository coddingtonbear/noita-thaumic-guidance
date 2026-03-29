dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local gui = gui or GuiCreate()
local window = window or window_new(gui)

local FOG_THRESHOLD = 200
local EDGE_MARGIN = 4
local SCREEN_INSET = 2  -- buffer zone to avoid flicker at screen edges
local MAX_INDICATORS = 16
local SPRITE = "mods/thaumic_guidance/files/scripts/magic/warding_glyph.png"

function source()
    local entity = GetUpdatedEntityID()
    local player_x, player_y = EntityGetTransform(entity)
    if player_x == nil then return end

    local screen_w, screen_h = get_resolution(gui)

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
                indicators[#indicators + 1] = {
                    sx = sx, sy = sy,
                    has_los = has_los,
                    distance = dist,
                }
            end
        end
    end

    table.sort(indicators, function(a, b) return a.distance < b.distance end)

    local widget_list = widget_list_begin(window, 100)
    local center_x, center_y = screen_w * 0.5, screen_h * 0.5

    for i = 1, math.min(#indicators, MAX_INDICATORS) do
        local ind = indicators[i]

        local cx = clamp(ind.sx, EDGE_MARGIN, screen_w - EDGE_MARGIN)
        local cy = clamp(ind.sy, EDGE_MARGIN, screen_h - EDGE_MARGIN)

        local angle = math.atan2(ind.sy - center_y, ind.sx - center_x)

        if ind.has_los then
            widget_list_insert(widget_list, GuiColorSetForNextWidget, 1.0, 0.3, 0.1, 1.0)
        else
            widget_list_insert(widget_list, GuiColorSetForNextWidget, 0.4, 0.4, 0.6, 0.6)
        end

        local id = widget_list_id(widget_list, source)
        widget_list_insert(widget_list, GuiImage, id, cx, cy, SPRITE, 1.0, 1.0, 0, angle)
    end

    widget_list_end(widget_list)
end

source()
