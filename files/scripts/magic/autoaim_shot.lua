dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local function get_direction_difference_abs(a, b)
    return math.abs(get_direction_difference(a, b))
end

-- Returns the world-space probe points for an enemy (center, head, feet, sides).
local function get_enemy_probe_points(enemy)
    local tx, ty = EntityGetTransform(enemy)
    local hitbox = EntityGetFirstComponent(enemy, "HitboxComponent")
    if hitbox == nil then
        return {{tx, ty}}
    end
    local min_x = ComponentGetValue2(hitbox, "aabb_min_x")
    local max_x = ComponentGetValue2(hitbox, "aabb_max_x")
    local min_y = ComponentGetValue2(hitbox, "aabb_min_y")
    local max_y = ComponentGetValue2(hitbox, "aabb_max_y")
    local cx = tx + (min_x + max_x) * 0.5
    local cy = ty + (min_y + max_y) * 0.5
    local hw = (max_x - min_x) * 0.5
    local hh = (max_y - min_y) * 0.5
    return {
        {cx,      cy     },  -- center
        {cx,      ty + min_y},  -- head (top edge)
        {cx,      ty + max_y},  -- feet (bottom edge)
        {tx + min_x, cy  },  -- left side
        {tx + max_x, cy  },  -- right side
    }
end

-- Returns the first unoccluded aim point on the enemy, or nil if all are blocked.
local function get_los_point(from_x, from_y, enemy)
    for _, p in ipairs(get_enemy_probe_points(enemy)) do
        if not RaytraceSurfaces(from_x, from_y, p[1], p[2]) then
            return p[1], p[2]
        end
    end
    return nil
end

function shot(projectile)
    local autoaim = GetUpdatedComponentID()
    local physics_body = EntityGetFirstComponentIncludingDisabled(projectile, "PhysicsBodyComponent")
    local item = EntityGetFirstComponentIncludingDisabled(projectile, "ItemComponent")
    local projectile_component = EntityGetFirstComponent(projectile, "ProjectileComponent")
    if not ComponentGetIsEnabled(autoaim) or physics_body ~= nil and item ~= nil or projectile_component == nil then
        return
    end

    local shooter = ComponentGetValue2(projectile_component, "mWhoShot")
    local projectile_x, projectile_y = EntityGetFirstHitboxCenter(projectile)
    local velocity_x, velocity_y = GameGetVelocityCompVelocity(projectile)
    local velocity_direction = get_direction(0, 0, velocity_x, velocity_y)

    local shooter_object = Player(shooter)
    local x, y = shooter_object.controls.mAimingVectorNormalized()
    local length = x * x + y * y
    local angle = math.pi * 0.25 * length

    local enemies = table.filter(EntityGetWithTag("enemy"), function(enemy)
        local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy)
        local enemy_direction = get_direction(projectile_x, projectile_y, enemy_x, enemy_y)
        return enemy ~= shooter and
            EntityGetHerdRelationSafe(shooter, enemy) < 100 and
            get_direction_difference_abs(enemy_direction, velocity_direction) < angle and
            get_los_point(projectile_x, projectile_y, enemy) ~= nil
    end)

    local enemy = table.iterate(enemies, function(a, b)
        local a_x, a_y = EntityGetFirstHitboxCenter(a)
        local a_distance = get_distance(projectile_x, projectile_y, a_x, a_y)
        local a_direction = get_direction(projectile_x, projectile_y, a_x, a_y)
        local a_weight = a_distance * get_direction_difference_abs(a_direction, velocity_direction)
        local b_x, b_y = EntityGetFirstHitboxCenter(b)
        local b_distance = get_distance(projectile_x, projectile_y, b_x, b_y)
        local b_direction = get_direction(projectile_x, projectile_y, b_x, b_y)
        local b_weight = b_distance * get_direction_difference_abs(b_direction, velocity_direction)
        return a_weight < b_weight
    end)

    if enemy ~= nil then
        GamePrint("Thaumic Guidance Locked!")
        print("Thaumic Guidance target: " .. tostring(enemy))
    end

    if enemy == nil then return end

    ComponentSetValue2(projectile_component, "lob_min", math.max(ComponentGetValue2(projectile_component, "lob_min"), 1))
    ComponentSetValue2(projectile_component, "lob_max", math.max(ComponentGetValue2(projectile_component, "lob_max"), 1))
    local aim_x, aim_y = get_los_point(projectile_x, projectile_y, enemy)
    GameShootProjectile(0, projectile_x, projectile_y, aim_x, aim_y, projectile, false)
end
