extends Node

const SAMPLE_RATE: int = 22050
const TRACK_SECONDS: float = 4.2

var music_player: AudioStreamPlayer = null
var world: GameWorld = null
var scan_timer: float = 0.0
var current_key: String = ""

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    music_player.volume_db = -25.0
    music_player.finished.connect(_on_track_finished)

func _process(delta: float) -> void:
    scan_timer -= delta
    if scan_timer > 0.0:
        if music_player != null and _sound_enabled() and not current_key.is_empty() and not music_player.playing:
            music_player.play()
        elif music_player != null and not _sound_enabled() and music_player.playing:
            music_player.stop()
        return

    scan_timer = 0.40
    if world == null or not is_instance_valid(world):
        world = _find_world(get_tree().current_scene)

    if world == null or not is_instance_valid(world):
        if not current_key.is_empty():
            current_key = ""
            if music_player != null:
                music_player.stop()
        return

    var phase_key: String = "night" if world.phase == "night" else "day"
    var wanted: String = "%d:%s" % [world.biome_index, phase_key]
    if wanted != current_key:
        current_key = wanted
        _switch_track(world.biome_index, world.phase == "night")

func _switch_track(biome_index: int, night: bool) -> void:
    if music_player == null:
        return
    music_player.stop()
    music_player.stream = _make_track(biome_index, night)
    if _sound_enabled():
        music_player.play()

func _on_track_finished() -> void:
    if music_player != null and not current_key.is_empty() and _sound_enabled():
        music_player.play()

func _sound_enabled() -> bool:
    if not is_instance_valid(GameState):
        return true
    var settings: Dictionary = GameState.data.get("settings", {})
    return bool(settings.get("sound", true))

func _find_world(node: Node) -> GameWorld:
    if node == null:
        return null
    if node is GameWorld:
        return node as GameWorld
    for child: Node in node.get_children():
        var found: GameWorld = _find_world(child)
        if found != null:
            return found
    return null

func _make_track(biome_index: int, night: bool) -> AudioStreamWAV:
    var chord: Array[float]
    var pulse_frequency: float
    var amplitude: float = 0.055 if night else 0.042

    match biome_index:
        1:
            chord = [146.83, 220.0, 293.66] if night else [174.61, 261.63, 349.23]
            pulse_frequency = 55.0
        2:
            chord = [110.0, 164.81, 220.0] if night else [130.81, 196.0, 261.63]
            pulse_frequency = 46.25
        _:
            chord = [130.81, 196.0, 261.63] if night else [164.81, 246.94, 329.63]
            pulse_frequency = 65.41

    var sample_count: int = maxi(1, int(TRACK_SECONDS * float(SAMPLE_RATE)))
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)

    for i: int in range(sample_count):
        var seconds: float = float(i) / float(SAMPLE_RATE)
        var edge: float = minf(1.0, minf(seconds * 5.0, (TRACK_SECONDS - seconds) * 5.0))
        edge = clampf(edge, 0.0, 1.0)
        var slow_breathe: float = 0.72 + sin(seconds * TAU / TRACK_SECONDS) * 0.16
        var value: float = 0.0
        for frequency: float in chord:
            value += sin(TAU * frequency * seconds)
            value += sin(TAU * frequency * 2.002 * seconds) * 0.18
        value /= float(maxi(1, chord.size()))
        value += sin(TAU * pulse_frequency * seconds) * (0.16 if night else 0.09)

        if biome_index == 1:
            value += sin(TAU * 987.77 * seconds + sin(seconds * 1.7) * 0.6) * 0.035
        elif biome_index == 2:
            value += sin(TAU * 73.42 * seconds) * sin(seconds * 6.0) * 0.07
        else:
            value += sin(TAU * 523.25 * seconds + sin(seconds * 2.3)) * 0.025

        var sample: int = int(value * amplitude * slow_breathe * edge * 32767.0)
        sample = clampi(sample, -32768, 32767)
        bytes[i * 2] = sample & 0xff
        bytes[i * 2 + 1] = (sample >> 8) & 0xff

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = bytes
    return stream
