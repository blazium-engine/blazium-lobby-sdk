extends Node

@onready var user_scene := preload("res://demo/user.tscn")
@onready var container := $VBoxContainer
@onready var result_test := $VBoxContainer/RichTextLabel

func _on_add_user_pressed() -> void:
	var new_user = user_scene.instantiate()
	new_user.result_text = result_test
	container.add_child(new_user)
