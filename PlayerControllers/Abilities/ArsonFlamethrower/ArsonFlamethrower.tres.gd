extends WeaponAbility

@onready var animation_tree: AnimationTree = $AnimationTree
var is_shooting: bool = false
var is_reloading: bool = false
var new_equipped: bool = false

@onready var fire_rate: Timer = $ScriptStuff/FireRate
@onready var ui_control: Control = $ScriptStuff/UI_Control

@export_category("Weapon Stats")
@export var max_ammo: int = 200
@export var damage: float = 2.0
@export var fire_speed: float = 0.05 # Time in seconds between fire bursts

@export_category("Weapon Movement Juice")
@export var weapon_mesh: Node3D # ASSIGN YOUR VISUAL GUN MODEL HERE!
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.02
@export var tilt_amount: float = 0.2

var _bob_time: float = 0.0
var _initial_mesh_position: Vector3
var _initial_mesh_rotation: Vector3

@export_category("Weapon Nodes")
# Add ONE RayCast3D here for a Pistol/Rifle, or add MULTIPLE for a Shotgun
@export var raycasts: Array[RayCast3D] = [] 

var ammo: int

func _ready() -> void:
	ammo = max_ammo
	fire_rate.wait_time = fire_speed
	fire_rate.one_shot = true
	hide()
	
	if weapon_mesh:
		_initial_mesh_position = weapon_mesh.position
		_initial_mesh_rotation = weapon_mesh.rotation
	
	if !is_multiplayer_authority():
		ui_control.hide()

func _process(delta: float) -> void:
	if weapon_mesh:
		_apply_weapon_bob_and_tilt(delta)
	
	if !is_multiplayer_authority(): return
	if !currently_active: return
	
	## Don't allow shooting or reloading while already reloading
	#if animation_player.is_playing() and animation_player.current_animation == "reload": 
		#return
	## 2. Handle Single vs Auto fire inputs
	var trigger_pulled: bool = false
	trigger_pulled = Input.is_action_pressed("left_click") # Hold to shoot
	#if is_auto:
		#trigger_pulled = Input.is_action_pressed("left_click") # Hold to shoot
	#else:
		#trigger_pulled = Input.is_action_just_pressed("left_click") # Click to shoot
	#
	# 3. Check if the gun is ready to fire based on the timer
	if trigger_pulled and fire_rate.is_stopped() and !new_equipped and !is_reloading:
		shoot()
	
	if Input.is_action_just_pressed("reload") and !is_reloading and !new_equipped and ammo < max_ammo and !trigger_pulled: #Not letting them reload while shooting, to avoid fat fingers
		reload()

func reload():
	is_reloading = true
	animation_tree.set("parameters/conditions/is_reloading", is_reloading)
	animation_tree.set("parameters/conditions/not_reloading", !is_reloading)

func reload_ammo():
	ammo = max_ammo

func finish_reload_anim():
	is_reloading = false
	animation_tree.set("parameters/conditions/is_reloading", is_reloading)
	animation_tree.set("parameters/conditions/not_reloading", !is_reloading)

func shoot():
	pass

func equip():
	show()
	new_equipped = true
	animation_tree.set("parameters/conditions/new_equipped", new_equipped)
	#animation_tree.start("ft_equip")
	show_self.rpc(true) #tell all clients to update

func finish_equip():
	new_equipped = false
	ui_control.show()
	animation_tree.set("parameters/conditions/new_equipped", new_equipped)

@rpc("any_peer","call_remote","reliable")
func show_self(vis : bool):
	if vis:
		show()
		new_equipped = true
		animation_tree.set("parameters/conditions/new_equipped", new_equipped)
	else:
		hide()

func dequip():
	#animation_player.play("dequip")
	#await animation_player.animation_finished
	hide()
	new_equipped = false
	animation_tree.set("parameters/conditions/new_equipped", new_equipped)
	ui_control.hide()
	show_self.rpc(false)
	#show_visual_hand.rpc(false)

# ==========================================
# SOURCE-ENGINE WEAPON SWAY & BOB
# ==========================================
func _apply_weapon_bob_and_tilt(delta: float) -> void:
	# We only want 2D horizontal velocity (ignoring jumping/falling for the bob cycle)
	var horizontal_velocity = Vector3(merc.velocity.x, 0, merc.velocity.z)
	var speed = horizontal_velocity.length()
	
	# 1. BOBBING (Figure-8 pattern based on movement speed)
	if speed > 0.1 and merc.is_on_floor():
		# Advance the timer based on how fast we are moving
		_bob_time += delta * speed * bob_frequency
	else:
		# Smoothly reset the timer to 0 when we stop walking
		_bob_time = lerp(_bob_time, 0.0, delta * 5.0) 
		
	var target_pos = _initial_mesh_position
	# Up/Down motion
	target_pos.y += sin(_bob_time) * bob_amplitude 
	# Left/Right motion (Half the speed of Up/Down creates a figure-8)
	target_pos.x += cos(_bob_time * 0.5) * (bob_amplitude * 1.5) 
	
	# 2. ACCELERATION TILT (Tilts gun slightly opposite to movement direction)
	# Convert the global velocity into the camera's local point of view
	var local_vel = merc.camera.global_transform.basis.inverse() * horizontal_velocity
	var target_rot = _initial_mesh_rotation
	
	# Tilt left/right when strafing (A/D keys)
	target_rot.z += local_vel.x * tilt_amount * 0.01 
	# Tilt up/down slightly when moving forward/back (W/S keys)
	target_rot.x -= local_vel.z * tilt_amount * 0.01 
	
	# 3. LERP THE VISUALS (Smooths everything out)
	weapon_mesh.position = weapon_mesh.position.lerp(target_pos, delta * 10.0)
	weapon_mesh.rotation = weapon_mesh.rotation.lerp(target_rot, delta * 10.0)
