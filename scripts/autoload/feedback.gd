extends Node

const SAMPLE_RATE: int = 22050

var tones: Dictionary = {}

func _ready() -> void:
    tones = {
        "harvest": _make_tone(520.0, 0.055, 0.14, 90.0),
        "ore": _make_tone(690.0, 0.070, 0.12, -120.0),
        "build": _make_chime([392.0, 523.25, 659.25], 0.075),
        "enemy_down": _make_tone(180.0, 0.080, 0.16, -80.0),
        "hit": _make_tone(115.0, 0.090, 0.18, -160.0),
        "shield": _make_tone(820.0, 0.085, 0.11, 160.0),
        "level": _make_chime([523.25, 659.25, 783.99], 0.065),
        "boss": _make_chime([146.83, 123.47, 98.0], 0.11),
        "victory": _make_chime([392.0, 523.25, 659.25, 783.99], 0.09),
        "stalker": _make_tone(310.0, 0.095, 0.12, 460.0),
        "guardian": _make_chime([110.0, 146.83], 0.070),
        "danger": _make_chime([220.0, 174.61, 146.83], 0.055)
    }

func play(kind: String, haptic_ms: int = 0) -> void:
    if _sound_enabled() and tones.has(kind):
        _spawn_player(tones[kind] as AudioStream)
    if haptic_ms > 0 and _haptics_enabled():
        Input.vibrate_handheld(haptic_ms)

func _spawn_player(stream: AudioStream) -> void:
    var player: AudioStreamPlayer = AudioStreamPlayer.new()
    add_child(player)
    player.stream = stream
    player.volume_db = -9.0
    player.finished.connect(player.queue_free)
    player.play()

func _sound_enabled() -> bool:
    if not is_instance_valid(GameState):
        return true
    var settings: Dictionary = GameState.data.get("settings", {})
    return bool(settings.get("sound", true))

func _haptics_enabled() -> bool:
    if not is_instance_valid(GameState):
        return true
    var settings: Dictionary = GameState.data.get("settings", {})
    return bool(settings.get("haptics", true))

func _make_tone(frequency: float, duration: float, amplitude: float, sweep_hz: float = 0.0) -> AudioStreamWAV:
    var sample_count: int = maxi(1, int(duration * float(SAMPLE_RATE)))
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(sample_count * 2)
    var phase: float = 0.0
    for i: int in range(sample_count):
        var t: float = float(i) / float(sample_count)
        var current_frequency: float = frequency + sweep_hz * t
        phase += TAU * current_frequency / float(SAMPLE_RATE)
        var envelope: float = pow(1.0 - t, 1.8)
        var sample: int = int(sin(phase) * envelope * amplitude * 32767.0)
        sample = clampi(sample, -32768, 32767)
        bytes[i * 2] = sample & 0xff
        bytes[i * 2 + 1] = (sample >> 8) & 0xff
    return _stream_from_bytes(bytes)

func _make_chime(frequencies: Array[float], note_duration: float) -> AudioStreamWAV:
    var note_samples: int = maxi(1, int(note_duration * float(SAMPLE_RATE)))
    var sample_count: int = note_samples * frequencies.size()
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(sample_count * 2)
    var cursor: int = 0
    for frequency: float in frequencies:
        var phase: float = 0.0
        for i: int in range(note_samples):
            var t: float = float(i) / float(note_samples)
            phase += TAU * frequency / float(SAMPLE_RATE)
            var envelope: float = pow(1.0 - t, 1.45)
            var sample: int = int(sin(phase) * envelope * 0.105 * 32767.0)
            sample = clampi(sample, -32768, 32767)
            bytes[cursor * 2] = sample & 0xff
            bytes[cursor * 2 + 1] = (sample >> 8) & 0xff
            cursor += 1
    return _stream_from_bytes(bytes)

func _stream_from_bytes(bytes: PackedByteArray) -> AudioStreamWAV:
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = bytes
    return stream
