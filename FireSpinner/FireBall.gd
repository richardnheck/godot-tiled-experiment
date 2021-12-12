extends Node2D
class_name FireBall

var _showing:bool = false setget set_showing, get_showing
var _current_rotation_degrees = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = _showing


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Setter for showing
# Sets whether the fireball is showing (when showing fireball is visible)
func set_showing(value:bool) -> void:
	_showing = value
	visible = value	


# Getter for showing
func get_showing() -> bool:
	return _showing


# Show/hide the fireball
func show_fireball(value:bool) -> void:
	_showing = value
	visible = value	
	 

# Remember the current rotation so it can be adjusted incrementally
func remember_current_rotation() -> void:
	_current_rotation_degrees = rotation_degrees
	
	
# Adjust the rotation of the fireball by the specified number of degrees
func adjust_rotation(degrees:float) -> void:
	rotation_degrees = _current_rotation_degrees + degrees
		
	
# Handle when a body enters the object
func _on_body_entered(body: Node) -> void:
	# Add code here to handle player touching a fireball
	pass

