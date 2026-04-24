extends "res://PlayerControllers/Abilities/MoneyBased/base_money_user.gd"

const GoldShaderPreload := preload("res://PlayerControllers/Mercs/YetAnotherMerc/gold.gdshader")
var GoldMaterial = ShaderMaterial.new()

func money_custom_ready() -> void:
	# Hopefully this makes the mesh only invisible to me
	$MeshInstance3D.visible = !is_multiplayer_authority()
	GoldMaterial.shader = GoldShaderPreload
	
	var to_visit: Array[Variant] = self.abilities.duplicate()
	while to_visit.size() > 0:
		var cur: Variant = to_visit.pop_back()
		to_visit += cur.get_children()
		if cur is MeshInstance3D: (cur as MeshInstance3D).set_surface_override_material(0, GoldMaterial)
		if cur is RayCast3D:
			(cur as RayCast3D).set_exclude_parent_body(true)
			(cur as RayCast3D).add_exception(self)
			#self.add_collision_exception_with(cur)
	
	return
