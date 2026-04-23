extends DestructibleProp

@export var damage = 10

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var dada : Merc
var targets := []

func hit_effect(damage):
	pass

func destory_effect():
	get_parent().bandages +=1

func _ready():
	health = 100
	dada = get_parent()

func _physics_process(delta):
	if targets.size() > 0:
		while targets[0] == null:
			#targets.pop_front()
			pass
		if !test_cast(targets[0]) and !$LockonTimer.is_stopped():
			return
		var rotation_speed = 5.0
		
		# Calculate target Y rotation
		var target_pos = targets[0].global_position
		var direction = (target_pos - global_position).normalized()
		var target_angle = atan2(direction.x, direction.z)
		# Smoothly interpolate rotation_y
		$turret.rotation.y = rotate_toward($turret.rotation.y, target_angle, rotation_speed * delta)
		
		if $ShootTimer.is_stopped():
			print("shoot")
			shoot()

func shoot():
	
	$ShootTimer.start()
	$turret/turrethead/AudioStreamPlayer3D.play()
	$turret/turrethead/AudioStreamPlayer3D/OmniLight3D.visible = true
	await get_tree().create_timer(0.1).timeout
	$turret/turrethead/AudioStreamPlayer3D/OmniLight3D.visible = false
	$turret/turrethead/AudioStreamPlayer3D.pitch_scale = randf_range(0.9,1.1)
	var hit_target = $turret/turrethead/BulletCast.get_collider()
	if hit_target is Merc:
		hit_target.take_damage.rpc_id(hit_target.name.to_int(), damage)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Merc and body.team != dada.team and body != dada:
		$LockonTimer.start()
		targets.append(body)

func test_cast(body):
	$TestCast.target_position = to_local(body.global_position)
	if $TestCast.is_colliding():
		return true
	else:
		return false
