extends Node

func load():
	print("loading input pack")
	Game.add_global("Input",Inputs.new())
