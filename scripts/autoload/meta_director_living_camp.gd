extends "res://scripts/autoload/meta_director.gd"

func _show_arsenal_if_needed() -> void:
    arsenal_shown = true
    if world == null or world.hud == null or world.player == null:
        return
    var selected: String = str(GameState.data.get("selected_weapon", "axes"))
    world.player.apply_weapon_profile(selected)
