extends Sprite2D

var rotation_speed_default = 20.0  # Degrees per second
var rotation_speed
@onready var arson_flamethrower: Node3D = $"../../.."

func _process(delta):
	# Rotate by adding speed * delta
	if arson_flamethrower.is_firing:
		rotation_speed = rotation_speed_default*2.5
	else:
		rotation_speed = rotation_speed_default
	rotation_degrees += rotation_speed * delta
