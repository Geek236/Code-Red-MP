extends Node


@onready var error_label: Label = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/errorLabel
@onready var table: VBoxContainer = $CanvasLayer/leaderBoard/MarginContainer/table
@onready var leader_board_panel: Control = $CanvasLayer/leaderBoard
@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var iplabel: Label = $CanvasLayer/HUD/IP
@onready var pause_menu: Control = $"CanvasLayer/Pause Menu"
@onready var game_time: Timer = $"game time"
@onready var respawn_timer_idle: Timer = $"respawn timer idle"
@onready var timeLabel: Label = $CanvasLayer/HUD/Time
@onready var map: Node3D = $Map


var spawnpoint_a
var spawnpoint_b
var spawnpoint_c
var spawnpoint_d
var spawnpoints: Array[Node3D] = []


const PlayerRowScene = preload("res://scenes/leaderboard.tscn")
const PlayerScene = preload("res://scenes/player.tscn")
const PORT = 9999
const freeForallmap1 = preload("res://scenes/ffa_map1.tscn")
const freeForallmap2 = preload("res://scenes/ffa_map2.tscn")
const TDMmap1 = preload("res://scenes/tdm_map_1.tscn")
const TDMmap2 = preload("res://scenes/tdm_map_2.tscn")


var enet_peer = ENetMultiplayerPeer.new()
var occupied_spawnpoints := {}
var last_spawnpoint := {}
var respawning := {}
var leaderboard := {}
var player_rows := {}
var optionsApplied = Global.optionsApplied


func _ready():
	pause_menu.visible = false
	hud.hide()
	leader_board_panel.visible = false


func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		toggle_pause()
	leader_board_panel.visible = Input.is_action_pressed("leaderboard")


func _on_host_button_pressed():
	if not optionsApplied:
		error_label.text = "Apply the options for the hosting game"
		return

	load_map(Global.gameOption.gameMode, Global.gameOption.map)
	game_time.wait_time = Global.gameOption.timeLimit * 60
	main_menu.hide()
	hud.show()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)


	add_player(multiplayer.get_unique_id())
	game_time.start()

	var lan_ip = get_lan_ip()
	iplabel.text = "LAN IP: %s:%s" % [lan_ip, PORT]
	print("LAN Server started. Connect using: %s:%s" % [lan_ip, PORT])

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer


func load_map(game_mode: String, map_name: String):
	var map_scene: PackedScene

	if game_mode == "Free for all":
		map_scene = freeForallmap1 if map_name == "Map 1" else freeForallmap2
	elif game_mode == "Team deathmatch":
		map_scene = TDMmap1 if map_name == "Map 1" else TDMmap2
	else:
		print("Unknown game mode:", game_mode)
		return

	var map_instance = map_scene.instantiate()
	map.add_child(map_instance)

	
	if map.get_child(0) != null:
		spawnpoint_a = map.get_child(0).get_node("spawnPoint")
		spawnpoint_b = map.get_child(0).get_node("spawnPoint2")
		spawnpoint_c = map.get_child(0).get_node("spawnPoint3")
		spawnpoint_d = map.get_child(0).get_node("spawnPoint4")
		spawnpoints = [spawnpoint_a, spawnpoint_b, spawnpoint_c, spawnpoint_d]

@rpc("any_peer")
func _sync_map(game_mode: String, map_name: String):
	load_map(game_mode, map_name)

func add_player(peer_id):
	if peer_id != multiplayer.get_unique_id():
		rpc_id(peer_id, "_sync_map", Global.gameOption.gameMode, Global.gameOption.map)

	if leaderboard.has(peer_id):
		return

	var new_player = PlayerScene.instantiate()
	new_player.name = str(peer_id)
	add_child(new_player)

	
	if Global.gameOption.gameMode == "Team deathmatch":
		var red_count = get_tree().get_nodes_in_group("TeamRed").size()
		var blue_count = get_tree().get_nodes_in_group("TeamBlue").size()
		
		if red_count <= blue_count:
			new_player.add_to_group("TeamRed")
		else:
			new_player.add_to_group("TeamBlue")

	_spawn_player(peer_id, new_player)

	if multiplayer.get_unique_id() == peer_id:
		new_player.health_changed.connect(update_health_bar)

	new_player.health_changed.connect(func(h):
		if h <= 0:
			_start_respawn(peer_id, new_player))

	var row = PlayerRowScene.instantiate()
	table.add_child(row)
	row.get_node("Name").text = "Player %s" % peer_id
	row.get_node("Kills").text = "0"
	row.get_node("Deaths").text = "0"
	player_rows[peer_id] = row

	leaderboard[peer_id] = {"kills": 0, "deaths": 0}
	rpc_id(0, "_sync_leaderboard", leaderboard)



func get_player_team(peer_id: int) -> String:
	var player = get_node_or_null(str(peer_id))
	if not player:
		return ""
	if player.is_in_group("TeamRed"):
		return "TeamRed"
	elif player.is_in_group("TeamBlue"):
		return "TeamBlue"
	return ""

func remove_player(peer_id):
	occupied_spawnpoints.erase(peer_id)
	last_spawnpoint.erase(peer_id)

	if respawning.has(peer_id):
		respawning[peer_id].stop()
		respawning.erase(peer_id)

	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

	if player_rows.has(peer_id):
		player_rows[peer_id].queue_free()
		player_rows.erase(peer_id)

	if leaderboard.has(peer_id):
		leaderboard.erase(peer_id)

	rpc_id(0, "_sync_leaderboard", leaderboard)

func _start_respawn(peer_id, player):
	player.hide()
	player.set_physics_process(false)
	occupied_spawnpoints.erase(peer_id)

	for child in player.get_children():
		if child is CollisionShape3D:
			child.disabled = true

	var t = Timer.new()
	t.wait_time = 2.0
	t.one_shot = true
	t.autostart = true
	add_child(t)

	t.timeout.connect(func():
		if is_instance_valid(player):
			player.show()
			player.set_physics_process(true)
			_spawn_player(peer_id, player)
			for child in player.get_children():
				if child is CollisionShape3D:
					child.disabled = false
		respawning.erase(peer_id)
		t.queue_free()
	)
	respawning[peer_id] = t

func _spawn_player(peer_id, player):
	var available = spawnpoints.duplicate()
	for sp in occupied_spawnpoints.values():
		available.erase(sp)
	if last_spawnpoint.has(peer_id):
		available.erase(last_spawnpoint[peer_id])
	if available.size() == 0:
		available = spawnpoints.duplicate()
		if last_spawnpoint.has(peer_id):
			available.erase(last_spawnpoint[peer_id])
	var spawn = available.pick_random()
	player.global_transform = spawn.global_transform
	occupied_spawnpoints[peer_id] = spawn
	last_spawnpoint[peer_id] = spawn


@rpc("any_peer")
func _sync_leaderboard(data: Dictionary):
	leaderboard = data.duplicate()

	for peer_id in leaderboard.keys():
		if not player_rows.has(peer_id):
			var row = PlayerRowScene.instantiate()
			table.add_child(row)
			row.get_node("Name").text = "Player %s" % peer_id
			player_rows[peer_id] = row
		var row = player_rows[peer_id]
		row.get_node("Kills").text = str(leaderboard[peer_id]["kills"])
		row.get_node("Deaths").text = str(leaderboard[peer_id]["deaths"])

	for peer_id in player_rows.keys().duplicate():
		if not leaderboard.has(peer_id):
			player_rows[peer_id].queue_free()
			player_rows.erase(peer_id)

func register_kill(attacker_id: int, victim_id: int):
	if leaderboard.has(attacker_id):
		leaderboard[attacker_id]["kills"] += 1
	if leaderboard.has(victim_id):
		leaderboard[victim_id]["deaths"] += 1
	rpc_id(0, "_sync_leaderboard", leaderboard)


func update_health_bar(h):
	health_bar.value = h


func get_lan_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"


func toggle_pause():
	var visible = not pause_menu.visible
	pause_menu.visible = visible
	if visible:
		hud.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		hud.show()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_main_menu_pressed() -> void:
	pause_menu.visible = false
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
	Global.targetScene = "res://scenes/homescreen.tscn"

func _on_game_time_timeout() -> void:
	get_tree().paused = true

	var t = Timer.new()
	t.wait_time = 10
	t.one_shot = true
	add_child(t)
	t.start()

	
	t.timeout.connect(_on_end_delay_timeout)

func _on_end_delay_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
	Global.targetScene='res://scenes/homescreen.tscn'

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")


func _process(delta: float) -> void:
	if multiplayer.is_server():
		rpc("_sync_timer", game_time.time_left)

@rpc("any_peer", "unreliable")
func _sync_timer(time_left: float):
	var total_seconds = int(time_left)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	timeLabel.text = "%02d:%02d" % [minutes, seconds]


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
	Global.targetScene='res://scenes/homescreen.tscn'
