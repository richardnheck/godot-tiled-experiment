extends Node2D

signal player_entered

onready var sprite = $Sprite

export var is_open = false

func _ready() -> void:
	if is_open:
		sprite.frame = 1
	else:
		sprite.frame = 0

func open() -> void:
	is_open = true
	_set_door_image()
	

func close() -> void:
	is_open = false
	_set_door_image()

func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# The player has come in contact with the door
		if is_open:
			emit_signal("player_entered")
			set_physics_process(false)

func _set_door_image():
	if is_open:
		sprite.frame = 1
	else:
		sprite.frame = 0
