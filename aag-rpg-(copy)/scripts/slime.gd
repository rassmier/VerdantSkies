extends CharacterBody2D

signal died

const SPEED: float = 80.0
const KNOCKBACK_FORCE: float = 60.0

var is_alive: bool = true
var health: int = 100
var strength: int = 10
var target: Node2D = null
var target_in_range: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var attack_timer: Timer = $AttackTimer


func _ready() -> void:
	attack_timer.wait_time = 1.0
	attack_timer.one_shot = false


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if target != null and is_instance_valid(target):
		_attack(delta)


func _attack(_delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		return

	var direction: Vector2 = (
		target.global_position - global_position
	).normalized()

	velocity = direction * SPEED
	move_and_slide()
	animated_sprite_2d.play("attack")


func take_damage(damage: int, attacker_position: Vector2) -> void:
	if not is_alive:
		return

	health = max(health - damage, 0)
	print("Slime health: ", health)

	if health <= 0:
		_die()
	else:
		take_damage_sound.play()

		var knockback_direction: Vector2 = (
			global_position - attacker_position
		).normalized()

		var target_position: Vector2 = (
			global_position + knockback_direction * KNOCKBACK_FORCE
		)

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(
			self,
			"global_position",
			target_position,
			0.5
		)


func _die() -> void:
	if not is_alive:
		return

	is_alive = false
	target = null
	target_in_range = false
	attack_timer.stop()
	velocity = Vector2.ZERO

	died.emit()

	animated_sprite_2d.play("dying")

	take_damage_sound.pitch_scale = 0.5
	take_damage_sound.play()

	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)


func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target = body


func _on_sight_body_exited(body: Node2D) -> void:
	if body == target:
		target = null

	if body.name == "Player" and is_alive:
		animated_sprite_2d.play("idle")


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target = body
		target_in_range = true

		if attack_timer.is_stopped():
			body.take_damage(strength)
			attack_timer.start()


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = false
		attack_timer.stop()


func _on_attack_timer_timeout() -> void:
	if not is_alive:
		attack_timer.stop()
		return

	if is_instance_valid(target) and target_in_range and target.alive:
		target.take_damage(strength)
	else:
		attack_timer.stop()
