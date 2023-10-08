class_name Ball
extends Node2D

var velocity: Vector2
var radius: float

var color: Color

func _ready() -> void:

	var color_mask = randi() % 6 + 1 # dissalow black and white
	color = Color(color_mask & 1, (color_mask >> 1) & 1, (color_mask >> 2) & 1)


func apply_gravity(dt: float, gravity: Vector2) -> void:
	velocity += gravity * dt


func move(dt: float) -> void:
	position += velocity * dt


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
