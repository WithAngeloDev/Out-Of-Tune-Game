extends Area2D

@export var damage := 1
@export var hurt_box: Hurtbox

signal on_hit(area)

func _ready():
	add_to_group("hurtbox")
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area):
	if area.is_in_group("hurtbox") && area != hurt_box && owner.get_groups() != area.owner.get_groups():
		var dir = (area.global_position - global_position).normalized()
		area.apply_damage(damage, dir)
		emit_signal("on_hit", area)
