extends Node

@onready var user_scene := preload("res://demo_auth/user_auth.tscn")
@export var container : VBoxContainer
@export var result_test: RichTextLabel

func _on_add_user_pressed() -> void:
	var new_user = user_scene.instantiate()
	new_user.result_text = result_test
	container.add_child(new_user)

func _on_change_scene_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
