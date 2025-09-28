extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
@onready var muzzle_flash: GPUParticles3D = $character/Armature_006/Skeleton3D/BoneAttachment3D/Sketchfab_Scene/MuzzleFlash
@onready var gunshot: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var animation_player: AnimationPlayer = $character/AnimationPlayer

var health = 3

const SPEED = 10.0
const JUMP_VELOCITY = 10.0
const GRAVITY = 20.0
const ACCELERATION = 20.0
const DECELERATION = 10.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	add_to_group("players")
	raycast.add_exception(self)

	if not is_multiplayer_authority(): return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	animation_player.animation_finished.connect(_on_animation_finished)

func _unhandled_input(event):
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if Input.is_action_just_pressed("shoot") and animation_player.current_animation != "fire":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit = raycast.get_collider().get_parent().get_parent().get_parent().get_parent().get_parent()
		
			print(hit)
			if hit.is_in_group("players") and hit != self:
				hit.receive_damage.rpc_id(hit.get_multiplayer_authority(), get_multiplayer_authority())

func _physics_process(delta):
	if not is_multiplayer_authority(): return

	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animation_player.play("jump")


	var input_dir = Input.get_vector("left", "right", "up", "down")
	var target_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * SPEED

	velocity.x = move_toward(velocity.x, target_dir.x, (ACCELERATION if input_dir != Vector2.ZERO else DECELERATION) * delta)
	velocity.z = move_toward(velocity.z, target_dir.z, (ACCELERATION if input_dir != Vector2.ZERO else DECELERATION) * delta)


	if animation_player.current_animation == "fire":
		pass
	elif is_on_floor():
		var desired_anim = "rifle idle"

		if input_dir != Vector2.ZERO:
			var forward = -transform.basis.z.normalized()
			var right = transform.basis.x.normalized()
			var move_dir = Vector3(input_dir.x, 0, input_dir.y).normalized()

			var forward_dot = move_dir.dot(forward)
			var right_dot = move_dir.dot(right)

			if abs(forward_dot) >= abs(right_dot):
				if forward_dot > 0.5:
					desired_anim = "running forward"
				elif forward_dot < -0.5:
					desired_anim = "running backward"
			else:
				if right_dot > 0.5:
					desired_anim = "walk right"
				elif right_dot < -0.5:
					desired_anim = "walk left"

		if animation_player.current_animation != desired_anim:
			animation_player.play(desired_anim)


	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	animation_player.stop()
	animation_player.play("fire")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	gunshot.play()

@rpc("any_peer")
func receive_damage(attacker_id: int = -1):
	if attacker_id == -1 or attacker_id == get_multiplayer_authority():
		return
	
	var game_mode = Global.gameOption.gameMode  
	
	if game_mode == "Team deathmatch":
		var attacker_team = get_parent().get_player_team(attacker_id)
		var victim_team = get_parent().get_player_team(get_multiplayer_authority())
		
		if attacker_team == victim_team:
			return
	

	health -= 1
	
	if health <= 0:
		if is_instance_valid(get_parent()):
			get_parent().register_kill(attacker_id, get_multiplayer_authority())
			get_parent()._start_respawn(get_multiplayer_authority(), self)
		
		health = 3
	
	health_changed.emit(health)

func _on_animation_finished(anim_name: String):
	if anim_name == "fire":
		animation_player.play("rifle idle")
