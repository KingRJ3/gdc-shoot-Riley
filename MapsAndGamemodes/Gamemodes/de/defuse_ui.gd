extends Control
class_name DEUI

@export var timer_label: Label
@export var state_label: Label
@export var attackers_score_label: Label
@export var defenders_score_label: Label

# Called by DefuseGamemode.gd every frame
func update_timer(time_left: float, state: int) -> void:
	# Format time into MM:SS
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [minutes, seconds]
		
	if state_label:
		match state:
			0: # FREEZE
				state_label.text = "FREEZE TIME"
				state_label.modulate = Color.AQUA
			1: # ACTION
				state_label.text = "DEFEND / ATTACK"
				state_label.modulate = Color.WHITE
			2: # BOMB_PLANTED
				state_label.text = "BOMB PLANTED"
				state_label.modulate = Color.RED
			3: # ROUND_END
				state_label.text = "ROUND OVER"
				state_label.modulate = Color.YELLOW

# Called by DefuseGamemode.gd when a round is won
func update_scores(attackers: int, defenders: int) -> void:
	if attackers_score_label:
		attackers_score_label.text = "Attackers: " + str(attackers)
	if defenders_score_label:
		defenders_score_label.text = "Defenders: " + str(defenders)
