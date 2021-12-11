extends Node2D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
onready var player_scene = preload("res://Player.tscn")
var player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = player_scene.instance()
	var spawn_position = $PlayerSpawnPosition
	player.global_position = Vector2(spawn_position.position.x, spawn_position.position.y)
	add_child(player)
	
	player.connect("collided", self, "_on_Player_collided")


func _on_Player_collided(collision: KinematicCollision2D) -> void:
	# Confirm the colliding body is a TileMap
	if collision.collider is TileMap:
		var tilemap = collision.collider
		if tilemap.is_in_group("trap"):
			# Player touched a trap so die
			player._die()
			get_tree().reload_current_scene()
