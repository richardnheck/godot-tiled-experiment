extends Node2D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
onready var player_scene = preload("res://Player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = player_scene.instance()
	var spawn_position = $PlayerSpawnPosition
	player.global_position = Vector2(spawn_position.position.x, spawn_position.position.y)
	add_child(player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
