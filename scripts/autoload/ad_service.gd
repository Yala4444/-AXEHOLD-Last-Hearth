extends Node

signal rewarded_completed(placement: String)

var busy := false

func show_rewarded(placement: String) -> void:
    if busy:
        return
    busy = true
    # Production integration point for AdMob / LevelPlay / AppLovin MAX.
    # The prototype simulates a completed rewarded ad after a short delay.
    await get_tree().create_timer(0.55).timeout
    busy = false
    rewarded_completed.emit(placement)
