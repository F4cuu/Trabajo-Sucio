extends Node

func _ready() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		var m = cfg.get_value("audio", "music", 1.0)
		var s = cfg.get_value("audio", "sfx", 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(clampf(m, 0.001, 1.0)))
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), m <= 0.001)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(clampf(s, 0.001, 1.0)))
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), s <= 0.001)
