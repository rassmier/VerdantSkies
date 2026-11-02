extends CharacterBody2D

signal health_changed(new_health: int)
signal died

const SPEED: float = 120.0

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var alive: bool = true
var max_health: int = 100
var health: int = 100
var strenght: int = 20

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var swing_sword_sound: AudioStreamPlayer2D = $SwingSword
@onready var hitbox: Area2D = $Hitbox
@onready var damage_cooldown: Timer = $DamageCooldown


func _ready() -> void:
	hitbox_offset = hitbox.position
	hitbox.monitoring = false
	health_changed.emit(health)


func _physics_process(_delta: float) -> void:
	if not alive:
		return

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	process_movement()
	process_animation()
	move_and_slide()


func process_movement() -> void:
	var direction: Vector2 = Input.get_vector(
		"left", "right", "up", "down"
	)

	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction.normalized()
		update_hitbox_offset()
	else:
		velocity = Vector2.ZERO


func process_animation() -> void:
	if is_attacking:
		return

	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)


func play_animation(prefix: String, dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")


func attack() -> void:
	is_attacking = true
	hitbox.monitoring = true
	swing_sword_sound.play()
	play_animation("attack", last_direction)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		hitbox.monitoring = false


func update_hitbox_offset() -> void:
	var x: float = hitbox_offset.x
	var y: float = hitbox_offset.y

	if abs(last_direction.x) > abs(last_direction.y):
		hitbox.position = Vector2(
			abs(x) * sign(last_direction.x), y
		)
	elif last_direction.y < 0:
		hitbox.position = Vector2(y, -abs(x))
	else:
		hitbox.position = Vector2(-y, abs(x))


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.name.begins_with("Slime"):
		if body.has_method("take_damage"):
			body.take_damage(strenght, global_position)


func take_damage(amount: int) -> void:
	if not alive:
		return

	if damage_cooldown.time_left > 0:
		return

	health = max(health - amount, 0)
	print("Player health: ", health)

	health_changed.emit(health)

	if health <= 0:
		die()
		return

	damage_cooldown.start()


func die() -> void:
	if not alive:
		return

	alive = false
	velocity = Vector2.ZERO
	hitbox.monitoring = false

	animated_sprite_2d.play("dying")
	await animated_sprite_2d.animation_finished

	await get_tree().create_timer(2.0).timeout
	died.emit()
