extends WeaponAbility
class_name DEBOMB

var max_time_to_plant : float = 2.5 # Store the max time so we can reset it!
var time_to_plant : float = 1.0

@onready var defuse_timer: Label3D = $bomb/palm/spinningpalm/DefuseTimer
@onready var plant_raycast: RayCast3D = $PlantRaycast
@onready var bomb: StaticBody3D = $bomb
@onready var bomb_collision_shape: CollisionShape3D = $bomb/BombCollisionShape
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hologram_mesh: Marker3D = $HologramMesh

var planted : bool = false
var defuse_gamemode : DE

func _ready() -> void:
	max_time_to_plant = animation_player.get_animation("plant").length
	time_to_plant = max_time_to_plant

func _process(delta: float) -> void:
	if !is_multiplayer_authority():return
	if !currently_active: return
	if !defuse_gamemode: return
	if planted: 
		if defuse_gamemode.current_state == defuse_gamemode.RoundState.BOMB_PLANTED:
			var time = max(defuse_gamemode.round_timer, 0.0)
			var minutes := int(time) / 60
			var seconds := int(time) % 60
			defuse_timer.text = "%d:%02d" % [minutes, seconds]
		return
	
	if merc and merc.camera:
		global_transform = merc.camera.global_transform
	var surface_point : Vector3 = Vector3.ZERO
	var surface_normal : Vector3 = Vector3.ZERO
	
	if plant_raycast.is_colliding():
		surface_point = plant_raycast.get_collision_point()
		surface_normal = plant_raycast.get_collision_normal()
		hologram_mesh.show()
		
		# Safely align the hologram's UP direction to match the ground's slope
		var align_quat = Quaternion(Vector3.UP, surface_normal)
		hologram_mesh.global_basis = Basis(align_quat)
		hologram_mesh.global_position = surface_point
	else: 
		hologram_mesh.hide()
	
	if Input.is_action_pressed("left_click") and surface_point != Vector3.ZERO:
		if surface_normal.dot(Vector3.UP) > 0.8:
			if animation_player.current_animation != 'plant':
				animation_player.play('plant')
				
			time_to_plant -= delta
			if time_to_plant <= 0.0:
				# FIX 3: Tell EVERYONE to plant the bomb, not just your local screen!
				_sync_plant_bomb.rpc(surface_point, surface_normal)
		else:
			reset_plant_state()
	else:
		reset_plant_state()

func reset_plant_state():
	animation_player.stop()
	if animation_player.current_animation != 'idle':
		animation_player.play("idle")
	time_to_plant = max_time_to_plant
	
func shoot(): 
	pass

func equip():
	if planted: return
	animation_player.play("equip")
	if merc:
		var merc_parent = merc.get_parent()
		if merc_parent is DE:
			defuse_gamemode = merc_parent

func dequip():
	if planted: return
	animation_player.play("dequip")

@rpc("any_peer", "call_local", "reliable")
func _sync_plant_bomb(plant_spot: Vector3, surface_normal: Vector3):
	if planted: return
	
	hologram_mesh.hide()
	reset_plant_state()
	planted = true
	
	# 1. Detach from the player's hand
	bomb.set_as_top_level(true) 
	
	# 2. Apply the exact same rotation the hologram had
	var align_quat = Quaternion(Vector3.UP, surface_normal)
	bomb.global_basis = Basis(align_quat)
	
	# 3. Offset the position so it doesn't sink into the floor.
	bomb.global_position = plant_spot
	
	bomb_collision_shape.set_deferred("disabled", false)
	
	# 4. Play the animation AFTER it is placed on the ground
	animation_player.play("planted")
	
	# Tell the gamemode to start the detonation countdown (Server Only)
	if multiplayer.is_server() and defuse_gamemode:
		var planter_id = multiplayer.get_remote_sender_id()
		if planter_id == 0: planter_id = 1 # Fallback for the host
		
		defuse_gamemode.on_bomb_planted(planter_id, self)

@rpc("authority", "call_local", "reliable")
func update_timer(time: float):
	# Convert pure seconds into MM:SS format
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	defuse_timer.text = "%d:%02d" % [minutes, seconds]

@rpc("authority", "call_local", "reliable")
func explode(): 
	# Add your particle emitters and explosion sounds here!
	print("BOOM!")
	
