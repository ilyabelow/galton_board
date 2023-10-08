class_name Peg
extends Node2D

var radius: float

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0, 0, 0))
