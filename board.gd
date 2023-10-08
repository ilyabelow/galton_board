extends Node2D

const gravity := Vector2.DOWN * 500.0


@export var amout_of_balls := 300
@export var ball_spawn_period := 0.1
var last_spawned_at := 0.0

@export var ball_to_ball_elasticity := 0.7
@export var ball_to_peg_elasticity := 0.3
@export var ball_to_wall_elasticity := 0.1

@export var peg_rad := 10.
@export var ball_rad := 5.
@export var wall_rad := 3.
var balls: Array[Ball]
var pegs: Array[Peg]
var capsules: Array[Capsule]

@export var grid_resolution := 15.
var grid = []


func _ready() -> void:
	var screen_size := get_viewport_rect().size
	for i in range(ceil(screen_size.x / grid_resolution)):
		var y_array = []
		for j in range(ceil(screen_size.y / grid_resolution)):
			y_array.push_back([])
		grid.append(y_array)
	
	const peg_dist := 40.
	const vert_pegs = 9
	var hor_pegs: int = screen_size.x / peg_dist
	for i in range(vert_pegs):
		for j in range(hor_pegs + (i+1)%2):
			var peg := Peg.new()
			peg.position = (Vector2.DOWN * (i+3) + Vector2.RIGHT * (j + (i%2)/2.)) * peg_dist
			peg.radius = peg_rad
			add_child(peg)
			pegs.append(peg)

	for i in range(hor_pegs + vert_pegs%2):
		var capsule := Capsule.new()
		var peg := pegs[len(pegs) - i - 1]
		capsule.p2 = peg.position
		capsule.p2.y = get_viewport_rect().end.y
		capsule.p1 = peg.position
		capsule.radius = wall_rad
		add_child(capsule)
		capsules.append(capsule)


func _process(delta: float) -> void:
	var cur_time := Time.get_ticks_msec() / 1000.
	if amout_of_balls > 0 and cur_time > last_spawned_at + ball_spawn_period:
		last_spawned_at = cur_time
		var new_ball := Ball.new() as Ball
		new_ball.position = Vector2.DOWN * 50. +  Vector2.RIGHT * ((randf()-0.5)*10. + get_viewport_rect().size.x/2.)
		new_ball.radius = ball_rad
		add_child(new_ball)
		balls.append(new_ball)
		amout_of_balls -= 1


func check_collision_round(r1, r2) -> bool:
	var rad_sum = (r1.radius + r2.radius)
	return (r1.position - r2.position).length_squared() < rad_sum*rad_sum


func collide_balls(b1: Ball, b2: Ball) -> void:
	var diff := b1.position - b2.position
	var dist := diff.length()
	var normal := diff / dist
	var tangent := normal.orthogonal()

	var tangent_vel1 := b1.velocity.project(tangent)
	var tangent_vel2 := b2.velocity.project(tangent)
	var normal_vel1 := b1.velocity.project(normal)
	var normal_vel2 := b2.velocity.project(normal)

	b1.velocity = tangent_vel1 + normal_vel2 * ball_to_ball_elasticity;
	b2.velocity = tangent_vel2 + normal_vel1 * ball_to_ball_elasticity;
	
	var intersection_length = b1.radius + b2.radius - dist
	b1.position += intersection_length * 0.5 * normal
	b2.position -= intersection_length * 0.5 * normal


func collide_ball_and_floor(b: Ball) -> void:
	var screen_dr := get_viewport_rect().end
	if b.position.y > screen_dr.y - b.radius:
		b.position.y = screen_dr.y - b.radius
		b.velocity.y = -b.velocity.y * ball_to_wall_elasticity


func collide_ball_and_peg(b: Ball, p: Peg) -> void:
	var diff := b.position - p.position
	var dist := diff.length()
	var normal := diff / dist
	var tangent := normal.orthogonal()

	var tangent_vel := b.velocity.project(tangent)
	var normal_vel := b.velocity.project(normal)

	b.velocity = tangent_vel - normal_vel * ball_to_peg_elasticity;

	var intersection_length = b.radius + p.radius - dist
	b.position += intersection_length * normal 


func get_nearest_point_capsule(c: Capsule, p: Vector2) -> Vector2:
	if (c.p2 - c.p1).dot(p - c.p1) < 0.0:
		return c.p1
	if (c.p1 - c.p2).dot(p - c.p2) < 0.0:
		return c.p2
	return c.p1 + (p - c.p1).project(c.p2 - c.p1)


func check_collision_capsule(b: Ball, c: Capsule) -> bool:
	var cap_p := get_nearest_point_capsule(c, b.position)
	var rad_sum = (c.radius + b.radius)
	return (cap_p - b.position).length_squared() < rad_sum*rad_sum


func collide_ball_and_capsule(b: Ball, c: Capsule) -> void:
	var cap_p := get_nearest_point_capsule(c, b.position)
	var diff := b.position - cap_p
	var dist := diff.length()
	var normal := diff / dist
	var tangent := normal.orthogonal()

	var tangent_vel := b.velocity.project(tangent)
	var normal_vel := b.velocity.project(normal)

	b.velocity = tangent_vel - normal_vel * ball_to_wall_elasticity;

	var intersection_length = b.radius + c.radius - dist
	b.position += intersection_length * normal 


func clear_grid() -> void:
	for i in range(len(grid)):
		for j in range(len(grid[i])):
			grid[i][j].clear()


func get_grid_coord(node: Node2D) -> Vector2i:
	var i: int = clampi(node.position.x / grid_resolution, 0, len(grid)-1)
	var j: int = clampi(node.position.y / grid_resolution, 0, len(grid[i])-1)
	return Vector2i(i, j)

func add_to_grid(node: Node2D):
	var coord := get_grid_coord(node)
	grid[coord.x][coord.y].append(node)


func collide_two_cells(c1, c2):
	for node1 in c1:
		for node2 in c2:
			if node1 == node2:
				continue
			if check_collision_round(node1, node2):
				collide_balls(node1, node2)


func _physics_process(delta: float) -> void:
	clear_grid()
	
	for b in balls:
		add_to_grid(b)

	for p in pegs:
		var coord := get_grid_coord(p)
		for di in range(max(coord.x-1, 0), min(coord.x+2, len(grid))):
			for dj in range(max(coord.y-1, 0), min(coord.y+2, len(grid[coord.x]))):
				for b in grid[di][dj]:
					if check_collision_round(b, p):
						collide_ball_and_peg(b, p)

	for c in capsules:
		for b in balls:
			if check_collision_capsule(b, c):
				collide_ball_and_capsule(b, c)

	for i in range(len(grid)):
		for j in range(len(grid[i])):
			for di in range(max(i-1, 0), min(i+2, len(grid))):
				for dj in range(max(j-1, 0), min(j+2, len(grid[i]))):
					collide_two_cells(grid[di][dj], grid[i][j])
	

	for i in range(len(grid)):
		for node in grid[i][len(grid[i])-1]:
			collide_ball_and_floor(node)

	for ball in balls:
		ball.apply_gravity(delta, gravity)
		ball.move(delta)
