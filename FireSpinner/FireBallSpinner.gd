extends Node2D

##
## A node that spins or swings fireballs
##
## @desc:
##    This node is based on the "Burny Whirler" from the game LevelHead
##

const fireball_scene = "res://FireSpinner/FireBall.tscn"	# Fireball scene	
const Once = preload("res://Utility/Once.gd")				# Utility for trigger once behaviour

# The maximum number of fireballs in a chain
const MAX_FIREBALLS = 5

enum RotationStyle { 
	SPIN = 0,		# Spins in a continous circle
	SWING = 1		# Swings through an arc of a specified angular range
}

# FireSpinner Configurable Properties
# ------------------------------------------------------------------------
# The style rotation (spin or swing)
export(RotationStyle) var rotation_style:int = 1 setget _set_rotation_style

# Start direction of flames in degrees
# 0 degrees is right
# Postive angles rotate clockwise
export(int, -180, 180, 45) var start_direction:int setget _set_start_direction

# The spin speed of rotation (degrees per second)
export(int, -180, 180, 45) var spin_speed:int = 90 setget _set_spin_speed

# The swing angle (in degrees) either side of start direction
export(int, 45, 135, 45) var swing_degrees:int = 90 setget _set_swing_degrees

# The swing speed in degrees per second
# Positive speed starts rotation in clockwise direction 
export(int, -100, 100, 10) var swing_speed:int = 90 setget _set_swing_speed

# The swing time offset in seconds to reach start direction
export(float, 0, 30, 0.1) var swing_time_offset:float = 0 setget _set_swing_time_offset

# Number of spinning fire balls in the same line 
export(int, 1, 5) var length:int = 3 setget _set_length

# Specifies whether there is a gap between the fireballs
export var gap:bool = false setget _set_gap

# The number of fireball chains that can spin
export(int, 1, 4) var chains:int = 1 setget _set_chains

# Sets whether the rotation is animated in the editor or not
export var animate_in_editor:bool = true setget _set_animate_in_editor

# Sets whether the guides drawn in editor or shown in the game
# The guides are normally shown in the editor and not in the game
# Set this to true if you want to see them in the game
export var show_editor_guides:bool = false setget _set_show_editor_guides
# ------------------------------------------------------------------------


# Additional Configuration
# ------------------------------------------------------------------------
# This is the spacing between the fireballs
# It is the distance in pixels from the centre of one fireball to the next
# Make this big enough to allow the player through a gap
var fireball_spacing = 18   

# This is the threshold distance (in degrees) that starts the fireballs rotating
# When the swing is within this threshold distance from the swing boundary,
# then the fireball starts rotating
var start_rotation_threshold = 30.0  
# ------------------------------------------------------------------------


# The rotation pivot node
# The fireballs are programatically added to this node
onready var pivot := $Pivot

# The tween for rotating the fireballs when rotate style is swing
onready var tween := $FireBallRotationTween

# Represents the actual rotation in degrees that the pivot is rotated
# Positive rotation results in clockwise rotation
var actual_rotation_degrees = 0

# Easing variables for Swing
# These are calculated to give a smooth easing as swing approaches the swing boundary
var swing_ease_offset: float = 0.0			# current ease offset time between start and end of easing
var swing_ease_start_angle: float = 0.0		# start value of the easing
var swing_ease_target_angle: float = 0.0	# end or targe value of the easing
var swing_ease_time: float = 0.1			# time in seconds for the swing ease (needs to be non-zero for code in editor to work)

#
# Variables relating to swing time offset
#
var swing_time_offset_degrees = 0		# The offset in degrees from the start direction as a result of the swing time offset
var swing_time_offset_sign = 0			# The sign(positive or negative) of the starting rotation as a result of the swing time offset

# Determines if it is the start of the swing cycle starting from start_direction
var is_swing_start = true

# Indicates whether the current direction of swing is clockwise
var is_swing_clockwise = true

# The time that has passed
var time_passed:float = 0.0

#
# Variables used for rotating the fireballs near the swing boundary
#
var is_clockwise_start = false			# Indicates if swing direction is clockwise at the start when swing enters threshold region
var threshold_reached = Once.new()		# A trigger when swing is inside the threshold region
var outside_threshold = Once.new()		# A trigger when sing is outside the threshold region
var skip_rotation = false

#
# Colors for drawing
# 
const COLOR_WHITE = Color("#FFFFFF")
const COLOR_ORANGE = Color("#FF7700")
const COLOR_BLUE = Color("#0000FF")


# ------------------------------------------------------------------------------
# Set the length or number of fireballs in a chain	
# ------------------------------------------------------------------------------
func _set_length(value) -> void:
	print("setting length = ", value)
	length = value
	update()


# ------------------------------------------------------------------------------
# Set the speed of the spin
# Only relevant when in SPIN mode
# ------------------------------------------------------------------------------
func _set_spin_speed(value) -> void:
	spin_speed = value
	_reset_spin()
	
	
# ------------------------------------------------------------------------------	
# Set the start direction of the fireballs
# ------------------------------------------------------------------------------
func _set_start_direction(value) -> void:
	start_direction = value
	if rotation_style == RotationStyle.SPIN:
		_reset_spin()
	else:
		_reset_swing()


# ------------------------------------------------------------------------------
# Set whether there is a gap or not
# ------------------------------------------------------------------------------
func _set_gap(value) -> void:
	gap = value
	update()
	

# ------------------------------------------------------------------------------
# Set the number of chains
# ------------------------------------------------------------------------------
func _set_chains(value) -> void:
	chains = value
	update()
	
	
# ------------------------------------------------------------------------------
# Set the rotation style
# ------------------------------------------------------------------------------
func _set_rotation_style(value) -> void:
	rotation_style = value
	if rotation_style == RotationStyle.SPIN:
		_reset_spin()
	else:
		_reset_swing()


# ------------------------------------------------------------------------------
# Set the swing degrees
# ------------------------------------------------------------------------------
func _set_swing_degrees(value) -> void:
	swing_degrees = value	
	_reset_swing()
	
	
# ------------------------------------------------------------------------------	
# Set the swing speed
# ------------------------------------------------------------------------------
func _set_swing_speed(value) -> void:
	swing_speed = value	
	_reset_swing()


# ------------------------------------------------------------------------------
# Set the swing time offset
# ------------------------------------------------------------------------------
func _set_swing_time_offset(value) -> void:
	swing_time_offset = value	
	_reset_swing()
		

# ------------------------------------------------------------------------------
# Set whether rotation is animated in editor or not
# ------------------------------------------------------------------------------
func _set_animate_in_editor(value) -> void:
	animate_in_editor = value
	if rotation_style == RotationStyle.SPIN:
		_reset_spin()
	else:
		_reset_swing()


# ------------------------------------------------------------------------------
# Set whether editor guides are shown in game or not
# ------------------------------------------------------------------------------
func _set_show_editor_guides(value) -> void:
	show_editor_guides = value
	
# ------------------------------------------------------------------------------
# Reset the spin so it starts with the newly configured values
# ------------------------------------------------------------------------------
func _reset_spin() -> void:
	actual_rotation_degrees = 0
	is_swing_clockwise = spin_speed > 0   # Positive speed starts swing in clockwise direction
	update()


# ------------------------------------------------------------------------------
# Reset the swing so it starts with the newly configured values
# ------------------------------------------------------------------------------
func _reset_swing() -> void:
	# Reset main swing variables
	is_swing_start = true
	actual_rotation_degrees = start_direction
	is_swing_clockwise = swing_speed > 0   # Positive speed starts swing in clockwise direction
	_set_ease_range()		
	swing_ease_offset = time_passed		# Start swing ease from the beginning
	
	# Reset fireball rotation variables
	is_clockwise_start = false
	threshold_reached = Once.new()
	outside_threshold = Once.new()
	skip_rotation = false
	
	if swing_speed == 0:
		# Speed is zero just make one call to show it in the start position
		if not Engine.editor_hint:
			if is_instance_valid(pivot):	
				pivot.rotation_degrees = actual_rotation_degrees	
	
	if swing_time_offset > 0:
		# Calculate the offset rotation and direction caused by the swing time offset
		calculate_adjustments_caused_by_swing_ease_time_offset()
		
		# Adjust the rotation direction based on the swing time offset
		# A negative swing time offset sign means swing starts in anti-clockwise direction
		# i.e The swing time offset sign overrides the default rotation direction
		is_swing_clockwise = false if swing_time_offset_sign < 0 else true
				
		# Based on a potential override of rotation direction recalculate the ease range
		_set_ease_range()
		
	update()
	

# ------------------------------------------------------------------------------	
# Reset firespinner so current settings can be freshly applied
# ------------------------------------------------------------------------------
func reset() -> void:
	if rotation_style == RotationStyle.SPIN:
		_reset_spin()
	else:
		_reset_swing()

	_init_fireballs()


# ------------------------------------------------------------------------------	
# Initialise the fireballs
# ------------------------------------------------------------------------------
func _init_fireballs() -> void:
	# Remove current fireballs
	for n in pivot.get_children():
		pivot.remove_child(n)
		n.queue_free()
		
	# Determine if the fireballs have a speed (i.e are moving)	
	var has_speed = true	
	if rotation_style == RotationStyle.SPIN:
		has_speed = abs(spin_speed) > 0
	else:
		has_speed = abs(swing_speed) > 0	
	
	# Add fireballs
	for c in range(0, chains):
		for i in range(0, length):
			var angle = c * (360 / chains)
			_add_fireball(i, angle, is_swing_clockwise, has_speed)
	
				
# ------------------------------------------------------------------------------	
# Set the swing ease variables
# ------------------------------------------------------------------------------
func _set_ease_range():
	if swing_speed == 0:
		return 
		
	# Calculate the time for a full swing from one boundary to the other 	
	var swing_ease_full_time = swing_degrees * 2.0 / abs(swing_speed)    # time = distance(in degrees) / speed(degrees per second)
	
	if is_swing_clockwise:
		# Swing starts in the clockwise direction
		# NB: In Godot positive angle is clockwise
		swing_ease_start_angle = start_direction - swing_degrees
		swing_ease_target_angle = start_direction + swing_degrees
	else:
		# Swing starts in the anti-clockwise direction
		# NB: In Godot egative angle is anti-clockwise
		swing_ease_start_angle = start_direction + swing_degrees
		swing_ease_target_angle = start_direction - swing_degrees
	
	# Now that the base ease settings for a full swing have been calculated above,
	# Calculate the adjustments necessary for the start of the swing.  
	# - When there is no swing time offset, the swing in the middle.   
	# - When there is a swing time offset, the swing may start anywhere and also
	#   start in the opposite direction	
	if is_swing_start:
		if swing_time_offset == 0:
			# The swing starts at the start direction (middle of total swing range)
			swing_ease_start_angle = start_direction
			swing_ease_time = swing_ease_full_time / 2.0		# swing time is halved because it starts in the middle 
		else:
			# Add necessary adjustments determined by swing_time_offset
			# Adjust the start direction by the rotation offset
			swing_ease_start_angle = start_direction + swing_time_offset_degrees
		
			if is_swing_clockwise:
				swing_ease_time = abs((swing_degrees - swing_time_offset_degrees) / swing_speed)
			else:
				swing_ease_time = abs((swing_degrees + swing_time_offset_degrees) / swing_speed) 
	else:
		swing_ease_time = swing_ease_full_time

# ------------------------------------------------------------------------------
# The ready function for initialisation
# ------------------------------------------------------------------------------
func _ready() -> void:
	print("Fireball Spinner Ready")
	if Engine.editor_hint:	
		return
	reset()


# ------------------------------------------------------------------------------
# Called every frame. 'delta' is the elapsed time since the previous frame.
# ------------------------------------------------------------------------------
func _process(delta: float) -> void: 
	time_passed += delta
	
	if rotation_style == RotationStyle.SPIN:
		_process_spin(delta)
	else:
		_process_swing(delta)

# ------------------------------------------------------------------------------
# Process spinning the fireballs
# ------------------------------------------------------------------------------
func _process_spin(delta: float) -> void:
	actual_rotation_degrees += spin_speed * delta
	if not Engine.editor_hint:
		# Rotate the actual flames in the game
		pivot.rotation_degrees = start_direction + actual_rotation_degrees
	
	update()
	

# ------------------------------------------------------------------------------
# Process swinging the fireballs
# ------------------------------------------------------------------------------
func _process_swing(delta: float) -> void:	
	# Draw the rotation and guides
	update()
	
	if swing_speed == 0:
		return
		
	# Swing back and forth
	var	ease_output = _easeInOutSine(time_passed, swing_ease_offset, swing_ease_time)
		
	# Calculate the actual rotation in degrees	
	actual_rotation_degrees = (swing_ease_start_angle + (ease_output * (swing_ease_target_angle - swing_ease_start_angle)))
	
	if not Engine.editor_hint:
		# Rotate the spinner in the actual game
		pivot.rotation_degrees = actual_rotation_degrees
		_rotate_fireballs()
		
	# Handle when a swing in one direction is finished
	# An easings output is from 0 (start) to 1 (end)
	if ease_output == 1:
		# mark that this is no longer the start of the swing
		is_swing_start = false
		
		# swing in the other direction
		is_swing_clockwise = not is_swing_clockwise
		
		# Reset the time offset to effectively start again  
		swing_ease_offset = time_passed
		
		# Recalculate the ease settings range
		_set_ease_range()		


# ------------------------------------------------------------------------------
# Rotate the fireballs as they approach the swing boundary
# ------------------------------------------------------------------------------
func _rotate_fireballs(): 
	# Calculate the distance (in degrees) how far the swing is from the swing boundary
	# This creates a positive range of values that descend to 0 when boundary is reached
	var distance_to_boundary = swing_degrees - abs(actual_rotation_degrees - start_direction)
	
	# Handle rotation of fireballs when near the boundary of the swing
	# NB: Need to check that the previous distance to boundary is set as well so we can determine
	# if swing is approaching or moving away from the boundary at the start
	if _is_near_clockwise_boundary() or _is_near_anticlockwise_boundary():
		# Determine if swing is approaching the boundary
		var is_approaching_boundary = _is_approaching_clockwise_boundary() or _is_approaching_anticlockwise_boundary()
		
		# For the fireball rotation equation to work make the distance values 
		# negative when approaching and keep them positive when moving away from the boundary
		var dist = -distance_to_boundary if is_approaching_boundary else distance_to_boundary
		
		if threshold_reached.run_once():
			# Run this code only once as the swing has reached the rotation threshold region
			outside_threshold.reset()
			is_clockwise_start = is_swing_clockwise		# remember the rotation direction at the start
			
			# Skip rotation of the fireball if swing starts in threshold region but is moving away from the boundary
			skip_rotation = not is_approaching_boundary	
			
		if not skip_rotation:
			# Using an easeInOutCirc gives the smoothest rotation as when the swing is at its slowest
			# near the boundary the ease curve changes the most rapidly
			var fireball_rotation = _easeInOutCirc(dist, -start_rotation_threshold, start_rotation_threshold*2) * 180
			
			# Flip the rotation direction depending on whether rotation starts clockwise or anti-clockwise
			if is_clockwise_start:
				fireball_rotation = -fireball_rotation
			
			# Call all fireballs to adjust their rotation
			get_tree().call_group(_get_fireball_group(), "adjust_rotation", fireball_rotation)
	else:
		# Swing position is no longer within the threshold distance from the boundary
		if outside_threshold.run_once():
			threshold_reached.reset() 	# Reset the threshold reached trigger
			skip_rotation = false 		# Reset the flag indicating whether rotation should be skipped
			
			# Call all fireballs to remember their current rotation
			get_tree().call_group(_get_fireball_group(), "remember_current_rotation")


# ------------------------------------------------------------------------------
# Determine if swing rotation is near the clockwise swing boundary
# This is used to determine when to rotate the fireballs
# ------------------------------------------------------------------------------
func _is_near_clockwise_boundary() -> bool:
	return actual_rotation_degrees <= start_direction + swing_degrees and actual_rotation_degrees > start_direction + swing_degrees - start_rotation_threshold


# ------------------------------------------------------------------------------
# Determine if swing rotation is near the anit-clockwise swing boundary
# This is used to determine when to rotate the fireballs
# ------------------------------------------------------------------------------
func _is_near_anticlockwise_boundary() -> bool:
	return actual_rotation_degrees >= start_direction - swing_degrees and actual_rotation_degrees < start_direction - swing_degrees + start_rotation_threshold


# ------------------------------------------------------------------------------
# Determine if swing is near the clockwise boundary and approaching it
# ------------------------------------------------------------------------------
func _is_approaching_clockwise_boundary() -> bool:
	return _is_near_clockwise_boundary() and is_swing_clockwise
	

# ------------------------------------------------------------------------------
# Determine if swing is near the anti-clockwise boundary and approaching it
# ------------------------------------------------------------------------------
func _is_approaching_anticlockwise_boundary() -> bool:
	return _is_near_anticlockwise_boundary() and not is_swing_clockwise	
	
	
# ------------------------------------------------------------------------------
# Calculate the adjustments caused by swing time offset
# Swing time offset represents the time by which the swing is delayed before it 
# would normally reach its normal start position in the middle
# 
# When swing_time_offset == 0 the swing starts in the middle
# When swing_time_offset > 0 an adjustments needs to be made to:
# 1. The angle at the which the swing starts
# 2. The initial direction of rotation of the swing 
# ------------------------------------------------------------------------------
func calculate_adjustments_caused_by_swing_ease_time_offset() -> void:
	# Determine the total number of degrees in rotation that the swing time offset result in at the given swing speed
	# This is the number of degrees we need to delay before the swing reaches its normal 'start direction' given no offset 
	var number_of_degrees = abs(swing_speed) * swing_time_offset
	
	var degrees_left = number_of_degrees
	
	var offset_degrees = 0		
	
	# if swing_speed > 0 (positive) then swing starts rotating clockwise
	# however the time offset results in a delay so we need to first rotate in 
	# the opposite direction so the offset swing is behind the normal swing 
	var offset_sign = -1 if swing_speed > 0 else 1
	
	# Loop through the number of degrees to determine the starting offset of the swing cycle as well as the starting direction of rotation
	while degrees_left > 0:  
		var exceeded_boundary_anticlockwise = offset_sign == -1 and offset_degrees - degrees_left < -swing_degrees
		var exceeded_boundary_clockwise = offset_sign == 1 and (offset_degrees + degrees_left > swing_degrees)
		
		if exceeded_boundary_anticlockwise or exceeded_boundary_clockwise:
			var delta = 0
			if offset_degrees == 0:
				# Offset has moved from the start point at the centre of the swing to the boundary
				# So offset has moved half a full swing cycle i.e swing_degrees
				delta = swing_degrees
			else:
				# Offset has moved from one boundary to the next
				# So offset has moved a full swing cycle i.e swing_degrees * 2
				delta = swing_degrees * 2
			
			offset_degrees += delta * offset_sign		# account for direction
			degrees_left -= abs(delta)
			offset_sign *= -1   	# change direction since boundary reached
		else:
			# angle offset is within the within swing boundary range
			offset_degrees += degrees_left * offset_sign  # -1 because time offset delays time to reach start so need to rotate offset in opposite direction
			degrees_left = 0
		
	swing_time_offset_degrees = offset_degrees
	
	# Since the swing time is delayed the offset sign must be negated so the swing traces back through all
	# the degrees it was offset
	swing_time_offset_sign = -offset_sign
	
	
# ------------------------------------------------------------------------------
# Get the name of the fireball group
# ------------------------------------------------------------------------------
func _get_fireball_group()-> String:
	return "fireball" + String(self.get_instance_id())
	

# ------------------------------------------------------------------------------
# Add a real fireball node to the pivot node

# @param index 			The index of the fireball on the chain
# @param start_angle	The starting angle of the chain
# @param clockwise		Indicates the starting direction of rotation
# @param has_speed      Indicates if the spinner has a rotational speed (i.e true if fireballs are moving)
# ------------------------------------------------------------------------------
func _add_fireball(index, start_angle, clockwise, has_speed) -> void:
	# Calculate the dist the centre of the fireball is away from the pivot 
	var dist = fireball_spacing + index * fireball_spacing
	var fire_ball:FireBall = load(fireball_scene).instance()
	fire_ball.add_to_group(_get_fireball_group())
	fire_ball.position = Vector2(dist, 0).rotated(deg2rad(start_angle))
	if has_speed:
		# Rotate the fireball to point in the direction of motion
		fire_ball.rotation_degrees = start_angle - 90 if clockwise else start_angle + 90		# Ensure the fireball points in the correct direction
	else:
		# The fireballs aren't moving so they should all be vertical
		fire_ball.rotation_degrees = -start_direction - 90
		
	# Remember the current rotation so it can be adjusted incrementally in order to rotate the fireball at the end of the swing
	fire_ball.remember_current_rotation()		
	
	# Show only the fireballs up to the specified length
	fire_ball.show_fireball(index < length)
	
	# Handle alternately showing fireballs when gap is set
	if fire_ball.get_showing() and gap:
		# When gap is true, then the 2nd, 4th fireball is not shown to leave a gap
		fire_ball.show_fireball(not index % 2 == 0)
	
	# Add the fireball to the pivot
	pivot.add_child(fire_ball)		


# ------------------------------------------------------------------------------
# Draw to the screen in the editor
# ------------------------------------------------------------------------------
func _draw():
	if not Engine.editor_hint:
		if not show_editor_guides:
			return
		
	# Draw the fireballs
	for c in range(0, chains):
		for i in range(0, length):
			var angle = c * (360 / chains)
			_draw_fireball(i, start_direction + angle)
		
	if rotation_style == RotationStyle.SPIN:
		# Draw the outer circle around the outmost fireball
		var outer_circle_fireball_spacing = (fireball_spacing/2) + fireball_spacing + ((length - 1)  * fireball_spacing)
		_draw_empty_circle(Vector2(), Vector2(0, outer_circle_fireball_spacing), COLOR_WHITE, 1)
		
		# Draw the circle indicating speed of rotation
		if animate_in_editor:
			draw_circle(Vector2(outer_circle_fireball_spacing, 0).rotated(deg2rad(start_direction + actual_rotation_degrees)), 3, COLOR_WHITE)
	
	elif rotation_style == RotationStyle.SWING:
		# Draw boundary lines for range of swing
		# NB: In Godot: Positive rotation is clockwise
		var dist = fireball_spacing + length * fireball_spacing
		var line_end = dist * Vector2.RIGHT.rotated(deg2rad(start_direction)).rotated(deg2rad(-swing_degrees))
		draw_line(Vector2(), line_end, COLOR_BLUE, 1, true)
		draw_circle(line_end, 3, COLOR_BLUE)

		line_end = dist * Vector2.RIGHT.rotated(deg2rad(start_direction)).rotated(deg2rad(swing_degrees))
		draw_line(Vector2(), line_end, COLOR_BLUE, 1, true)
		draw_circle(line_end, 3, COLOR_BLUE)

		# Draw the line that shows the swing motion
		if animate_in_editor:
			line_end = dist * Vector2.RIGHT.rotated(deg2rad(actual_rotation_degrees))
			draw_line(Vector2(), line_end, COLOR_WHITE, 1, true)
			draw_circle(line_end, 3, COLOR_WHITE)


# ------------------------------------------------------------------------------	
# Draw a fireball (represented by a circle) to the screen
# @param index			The current index of the fireball (0 is closest to centre)
# @param start_angle	The start angle (degrees) of the fireball chain
# ------------------------------------------------------------------------------
func _draw_fireball(index:int, start_angle:float) -> void:
	var dist = fireball_spacing + index * fireball_spacing
	var _draw_fireball = true
	
	# When gap is true, then the 2nd, 4th fireball is not shown to leave a gap
	if gap and index % 2 == 0:
		_draw_fireball = false
		
	if _draw_fireball:
		_draw_empty_circle(Vector2(dist, 0).rotated(deg2rad(start_angle)), Vector2(fireball_spacing/2,0), COLOR_ORANGE, 1)


# ------------------------------------------------------------------------------
# Draw an empty circle to the screen
# ------------------------------------------------------------------------------
func _draw_empty_circle(circle_center:Vector2, circle_fireball_spacing:Vector2, color:Color, resolution:int):
	var draw_counter = 1
	var line_origin = Vector2()
	var line_end = Vector2()
	line_origin = circle_fireball_spacing + circle_center

	while draw_counter <= 360:
		line_end = circle_fireball_spacing.rotated(deg2rad(draw_counter)) + circle_center
		draw_line(line_origin, line_end, color)
		draw_counter += 1 / resolution
		line_origin = line_end

	line_end = circle_fireball_spacing.rotated(deg2rad(360)) + circle_center
	draw_line(line_origin, line_end, color)


# ------------------------------------------------------------------------------
# Easing function: ease in out sine
# NB: The easing function need to be defined in this node for it to work in the editor
# ------------------------------------------------------------------------------
func _easeInOutSine(x: float, offset: float=0, ease_length: float=1) -> float:
   x -= offset
   x /= ease_length
   return (0.0 if x < 0 else (1.0 if x > 1.0 else -(cos(PI * x) - 1.0) / 2.0))


# ------------------------------------------------------------------------------
# Easing function: ease in out circ
# This easing is used to rotate the fireballs. This easing function is defined
# here instead of using an easing library because the above easing functions 
# needed to be included in this node to work in the editor, and so it felt overkill
# to use an easing library for just one function
# ------------------------------------------------------------------------------
func _easeInOutCirc(x: float, offset: float=0, length: float=1) -> float:
   x -= offset
   x /= length
   return (0.0 if x < 0 else (1.0 if x > 1.0 else ((1.0 - sqrt(1.0 - pow(2 * x, 2))) / 2.0 if x < 0.5 else (sqrt(1.0 - pow(-2.0 * x + 2, 2)) + 1.0) / 2.0)))
   
