tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("AnimatedGridContainer", "Container", preload("animated_grid_container.gd"), preload("icon_animated_grid_container.svg"))

func _exit_tree():
	remove_custom_type("AnimatedGridContainer")
