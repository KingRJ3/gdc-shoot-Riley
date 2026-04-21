extends Control

@onready var money_size: Vector2 = $"Remaining Money".size

func _ready() -> void:
	visible = is_multiplayer_authority()
	$"Remaining Money".minimum_size_changed.connect(
		func() -> void:
			$"Remaining Money".position += money_size - $"Remaining Money".size
			money_size = $"Remaining Money".size
	)
	return
	
func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	return
