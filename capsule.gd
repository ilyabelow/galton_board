class_name Capsule
extends Node2D


var radius: float
var p1: Vector2
var p2: Vector2


func _draw() -> void:
	draw_line(p1, p2, Color(0,0,0), radius*2)
