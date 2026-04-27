extends Control
@onready var ammo_count: RichTextLabel = $AmmoCount
@onready var max_ammo: RichTextLabel = $MaxAmmo
@onready var arson_flamethrower: Node3D = $"../../../Camera3D/Held/ArsonFlamethrower"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ammo_count.text = str(arson_flamethrower.ammo)
	max_ammo.text = str(arson_flamethrower.max_ammo)
