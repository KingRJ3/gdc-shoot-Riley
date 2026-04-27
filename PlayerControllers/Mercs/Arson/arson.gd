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

@onready var arson_flamethrower: Node3D = $Camera3D/Held/ArsonFlamethrower

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
		set_layer_recursively(arson_flamethrower, 16) #Client side rendering over other objects

func set_layer_recursively(node: Node, layer_number: int):
	if node is VisualInstance3D:
		node.layers = layer_number
	for child in node.get_children():
		set_layer_recursively(child, layer_number)

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
