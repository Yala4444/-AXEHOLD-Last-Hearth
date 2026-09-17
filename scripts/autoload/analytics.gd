extends Node

func event(name: String, params: Dictionary = {}) -> void:
    # Production integration point for Firebase / GameAnalytics / custom telemetry.
    print("[Analytics] ", name, " ", params)
