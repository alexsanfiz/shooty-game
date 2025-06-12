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

func end_match():
      if not multiplayer.is_server():
            return
      print("Match over. Finding winner...")
      print(Global.playerList)
      
      var top_player_id = null
      var top_kills = -1
      
      for id in Global.playerList:
            if Global.playerStats.has(id):
                  print(Global.playerStats[id].kills)
                  var kills = Global.playerStats[id].kills
                  if kills > top_kills:
                        top_kills = kills
                        top_player_id = id
                  print("updated. top = ", kills, " by player ", top_player_id)
                  
            else:
                  print("id not found in playerStats")
            
      if top_player_id != null:
            print("Winner: Player ", top_player_id)
      else:
            print("winner null")
