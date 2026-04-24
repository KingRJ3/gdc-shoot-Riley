extends WeaponAbility
class_name DEBOMB


@export var max_time_to_plant : float = 1.0 # Store the max time so we can reset it!
var time_to_plant : float = 1.0

@onready var defuse_timer: Label3D = $bomb/palm/spinningpalm/DefuseTimer
@onready var plant_raycast: RayCast3D = $PlantRaycast
@onready var bomb: StaticBody3D = $bomb
@onready var bomb_collision_shape: CollisionShape3D = $bomb/BombCollisionShape
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var planted : bool = false
var defuse_gamemode : DE

func _ready() -> void:
	time_to_plant = max_time_to_plant

func _process(delta: float) -> void:
	if !is_multiplayer_authority():return
	if !currently_active: return
	if !defuse_gamemode: return
	if planted: return
	
	if merc and merc.camera:
		global_transform = merc.camera.global_transform
		
	if Input.is_action_pressed("left_click") and plant_raycast.is_colliding():
		var surface_normal = plant_raycast.get_collision_normal()
		
		# Check if the surface is mostly pointing up (allows slight slopes, rejects walls)
		if surface_normal.dot(Vector3.UP) > 0.8:
			time_to_plant -= delta
			
			if time_to_plant <= 0.0:
				plant(plant_raycast.get_collision_point())
		else:
			time_to_plant = max_time_to_plant 
	else:
		time_to_plant = max_time_to_plant
	
func shoot(): 
	pass

func equip():
	animation_player.play("equip")

func dequip():
	animation_player.play("dequip")

func plant(plant_spot : Vector3): #multiplayer syncrhonizer sets the position on this for everyone else 
	if planted: return
	
	planted = true
	bomb.global_position = plant_spot
	bomb.global_rotation = Vector3.ZERO # Reset rotation so it sits flat
	animation_player.play("plant")
	bomb_collision_shape.set_deferred("disabled", false)
	defuse_gamemode.on_bomb_planted.rpc_id(1)

@rpc("authority", "call_local", "reliable")
func update_timer(time: float):
	# Convert pure seconds into MM:SS format
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	defuse_timer.text = "%d:%02d" % [minutes, seconds]

@rpc("authority", "call_local", "reliable")
func explode(): 
	pass
