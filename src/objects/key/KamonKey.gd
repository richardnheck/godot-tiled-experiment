extends AnimatedSprite

signal captured

onready var collisionShape = $Area2D/CollisionShape2D

func show_key(value:bool) -> void:
		visible = value
		collisionShape.set_deferred("disabled", not value)
		

func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# The player has captured the key
		emit_signal("captured")
		#Game_AudioManager.sfx_collectibles_key.play()
		show_key(false)
		queue_free()		
