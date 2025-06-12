extends Node

var playerStats := {} 
var player: Node = null
var players := {}
var playerList := []
var match_time: float = 10.0
var game_active: bool = false
var topKills = -1

func _on_player_spawned(peer_id: int, player_node: Node):
	players[peer_id] = player_node
	if not playerStats.has(peer_id):
		playerStats[peer_id] = { "kills": 0, "deaths": 0 }
	if not playerList.has(peer_id):
		playerList.append(peer_id)
	print("player thing: ", players[peer_id])

func get_player_by_peer(peer_id: int) -> Node:
	return players.get(peer_id)

func game_end():
	return
	
func game_restart():
	return
