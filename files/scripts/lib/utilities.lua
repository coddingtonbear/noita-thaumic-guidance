dofile_once("mods/thaumic_guidance/files/scripts/lib/tactic.lua")

Player = Entity{
    controls = ComponentField("ControlsComponent"),
    shooter = ComponentField("PlatformShooterPlayerComponent"),
    listener = ComponentField("AudioListenerComponent"),
    gui = ComponentField("InventoryGuiComponent"),
    wallet = ComponentField("WalletComponent"),
    pickupper = ComponentField("ItemPickUpperComponent"),
    hitbox = ComponentField("HitboxComponent", EntityGetFirstComponent),
    damage_model = ComponentField("DamageModelComponent"),
    genome = ComponentField("GenomeDataComponent"),
    ingestion = ComponentField("IngestionComponent"),
    alive = ComponentField("StreamingKeepAliveComponent", EntityGetFirstComponent),
    log = ComponentField("GameLogComponent"),
    sprite = ComponentField("SpriteComponent", "character"),
    aiming_reticle = ComponentField("SpriteComponent", "aiming_reticle"),
    character_data = ComponentField("CharacterDataComponent"),
    collision = ComponentField("PlayerCollisionComponent"),
    inventory = ComponentField("Inventory2Component"),
    autoaim = ComponentField{"LuaComponent", "thaumic_guidance.autoaim", _tags = "thaumic_guidance.autoaim", _enabled = false, script_shot = "mods/thaumic_guidance/files/scripts/magic/autoaim_shot.lua"},
}
