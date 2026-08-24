extends CharacterBody2D

const QUEDA_LIMITE: float = 300.0
const SPEED = 100.0
const JUMP_VELOCITY = -300.0
@onready var anima: AnimatedSprite2D = $CollisionShape2D/AnimatedSprite2D

func morrer() -> void:
	# Reinicia a fase atual
	set_physics_process(false)
	get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if is_on_floor():
		if direction > 0:
			anima.flip_h = false
			anima.play("walk")
		elif direction < 0:
			anima.flip_h = true
			anima.play("walk")
		else:
			anima.play("idle")
	else:
		anima.play("jump")
		if direction > 0:
			anima.flip_h = false
		elif direction < 0:
			anima.flip_h = true
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if global_position.y > QUEDA_LIMITE:
		morrer()
