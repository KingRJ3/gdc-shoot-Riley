extends Merc

@onready var belly: MeshInstance3D = $Models/Belly
@onready var gascanister: MeshInstance3D = $Models/Gascan/Gascanister
@onready var canister1: MeshInstance3D = $Models/Gascanister/Canister
@onready var canister2: MeshInstance3D = $Models/Gascanister2/Canister
@onready var canister3: MeshInstance3D = $Models/Gascanister3/Canister
@onready var incendiary1: MeshInstance3D = $Models/Incendiary/Incendiary
@onready var incendiary2: MeshInstance3D = $Models/Incendiary2/Incendiary
@onready var incendiary3: MeshInstance3D = $Models/Incendiary3/Incendiary
#@onready var cube: MeshInstance3D = $Models/WeldingMask/Cube
@onready var cube: MeshInstance3D = $Camera3D/WeldingMask/Cube

@onready var models_for_select: Node3D = $ModelsForSelect
var ImReal = false
@export var velocitysync: Vector3 #I need to sync the velocity because the particles will be offset otherwise.

func custom_ready():
	#models_for_select.queue_free()
	ImReal = true
	if is_multiplayer_authority():
		belly.layers = 2
		gascanister.layers = 2
		canister1.layers = 2
		canister2.layers = 2
		canister3.layers = 2
		incendiary1.layers = 2
		incendiary2.layers = 2
		incendiary3.layers = 2
		cube.layers = 2

func custom_process(delta):
	if models_for_select:
		models_for_select.queue_free()
	
	if is_multiplayer_authority():
		velocitysync = self.velocity
		rpc("SyncVelocity", velocitysync)
	
	self.velocity = velocitysync

@rpc("any_peer", "reliable")
func SyncVelocity(vel):
	self.velocity = vel
