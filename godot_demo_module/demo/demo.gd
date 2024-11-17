extends Node

@onready var user_scene := preload("res://demo/user.tscn")
@onready var container := $VBoxContainer

func _on_add_user_pressed() -> void:
	var new_user = user_scene.instantiate()
	container.add_child(new_user)
