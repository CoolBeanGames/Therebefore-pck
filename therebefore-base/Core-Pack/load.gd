extends Node

func load():
	print("load core")
	Game.add_global("signal_bus",signal_bus.new())
	Game.add_global("game_manager",game_manager.new())
