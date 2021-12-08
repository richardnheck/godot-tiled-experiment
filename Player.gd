extends KinematicBody2D

var velocity = Vector2(0,0);

const VELOCITY = PlayerVariables.VELOCITY
const JUMP_FORCE = PlayerVariables.JUMP_FORCE
const GRAVITY = PlayerVariables.GRAVITY

#const FIREBALL = preload("res://Fireball.tscn")

var is_dead = false

signal player_died
signal coin_collected

func _ready():
	pass
	
func _physics_process(delta):
	if not is_dead:
		velocity.x = 0.1
		if Input.is_action_pressed("right"):
			velocity.x = VELOCITY
			$Sprite.play("walk")
			$Sprite.flip_h = false
			
			# Handle shoot position
			if sign($Position2D.position.x) == -1:
				$Position2D.position.x *= -1
		elif Input.is_action_pressed("left"):
			velocity.x = -VELOCITY
			$Sprite.play("walk")
			$Sprite.flip_h = true
			
			# Handle shoot position
			if sign($Position2D.position.x) == 1:
				$Position2D.position.x *= -1
		else: 
			$Sprite.play("idle")
			
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y += JUMP_FORCE
	
		# Jump higher if jump button is held down
		if not Input.is_action_pressed("jump"):
			velocity.y = lerp(velocity.y, GRAVITY, 0.1) + GRAVITY;
		
		
		
		if not is_on_floor():
			$Sprite.play("air")
		
		velocity.y += GRAVITY
		velocity = move_and_slide(velocity, Vector2.UP)
		velocity.x = lerp(velocity.x, 0.1, 0.4);
		
		# Handle coming in to contact with enemies
		# NB: This doesn't work when not moving so I added an Area2D to detect instead
		#if get_slide_count() > 0:
		#	for i in range(get_slide_count()):
		#		if "Enemy" in get_slide_collision(i).collider.name:
		#			_die()
		
		# Handle shooting fireballs
#		if Input.is_action_just_pressed("fire"):
#			var fireball = FIREBALL.instance()
#			fireball.set_direction(sign($Position2D.position.x))
#			get_parent().add_child(fireball);
#			fireball.position = $Position2D.global_position

func _on_FallZone_body_entered(body):
	_die()

func collect_coin():
	print("Player: coin collected")
	emit_signal("coin_collected")

func _die():
	is_dead = true
	hide()
	$CollisionShape2D.set_deferred('disabled',true)
	emit_signal("player_died")

