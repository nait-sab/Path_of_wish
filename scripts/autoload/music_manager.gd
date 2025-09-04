extends Node

var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	player.bus = "Music"
	player.autoplay = false
	player.stream_paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_theme(stream: AudioStream, loop := true) -> void:
	if stream == null:
		return
	
	if player.is_connected("finished", Callable(self, "_on_finished")):
		player.disconnect("finished", Callable(self, "_on_finished"))
	
	player.stop()
	player.stream = stream
	
	if loop:
		if "loop" in stream:
			stream.loop = true
		else:
			player.connect("finished", Callable(self, "_on_finished"))
	
	player.play()

func _on_finished() -> void:
	player.play()

func stop() -> void:
	if player.playing:
		player.stop()
