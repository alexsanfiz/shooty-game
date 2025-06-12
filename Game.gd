extends Node

@onready var main_Menu = $CanvasLayer/mainMenu
@onready var address_entry = $CanvasLayer/mainMenu/MarginContainer/VBoxContainer/addressEntry
@onready var name_entry = $CanvasLayer/mainMenu/MarginContainer/VBoxContainer/nameEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/health
@onready var ammocounter = $CanvasLayer/HUD/ammocount/counter

const Player = preload("res://world.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var playerList = Global.players


func _on_host_button_pressed():
	main_Menu.hide()
	hud.show()
	
	
	Global.game_active = true
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_on_player_connected)
	#ADD WHEN USING ONLINE upnp_setup()

func _on_join_button_pressed():
	main_Menu.hide()
	hud.show()
	
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
		Global._on_player_spawned(peer_id, player)
		rpc_id(peer_id, "update_match_time", Global.match_time)
	else:
		Global.playerStats[peer_id] = {"kills": 0, "deaths": 0}
		Global.playerList.append(peer_id)
		
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player: 
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value 

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
	
func _process(delta):
	# Only the host updates the timer
	if multiplayer.is_server() and Global.game_active:
		Global.match_time -= delta
		var t = int(Global.match_time)
		var mins = t / 60
		var secs = t % 60
		rpc("update_match_time", Global.match_time)
		if secs < 10:
			$CanvasLayer/HUD/timer.text = "%d:0%d" % [mins, secs] 
		else:
			$CanvasLayer/HUD/timer.text = "%d:%d" % [mins, secs]
			
		if Global.match_time <= 0:
			Global.match_time = 0
			Global.game_active = false
			end_match()
		
func _on_player_connected(id: int):
	rpc_id(id, "update_match_time", Global.match_time)
	print("does this even work")
	
#@rpc("call_local")
#func update_match_time(new_time: int):
	#Global.match_time = new_time
	
func end_match():
	if not multiplayer.is_server():
		return
	print("Match over. Finding winner...")
	print(Global.playerList)
	print(Global.playerStats)
	var top_player_id = null
	var top_kills = -1
	
	for id in Global.playerList:
		if Global.playerStats.has(id):
			print(Global.playerStats[id].kills)
			var kills = Global.playerStats[id].kills
			if kills > top_kills:
				top_kills = kills
				top_player_id = id
			print("updated. kills = ", kills, " by player ", id)
			print("top kills = ", top_kills)
			
		else:
			print("id not found in playerStats")
		
	if top_player_id != null:
		print("Winner: Player ", top_player_id)
		showWinner(top_player_id, top_kills)
		rpc("showWinner", top_player_id, top_kills)
	else:
		print("winner null")

@rpc("any_peer")		
func showWinner(name, kills):
	$CanvasLayer/WinMessage.text = "Winner: Player %d with %d kills!" % [name, kills]
	$CanvasLayer/WinMessage.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.game_active = false
	
