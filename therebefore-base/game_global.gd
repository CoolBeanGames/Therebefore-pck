extends Node
class_name game

#this global script contains ALL other global scripts
#as loaded in resource packs (pck files)

@export var globals : Dictionary[String,Node]
@export var tree_root : Node
@export var ui_root : CanvasLayer


func _process(delta: float) -> void:
	for k in globals:
		if globals[k].has_method("_process"):
			globals[k]._process(delta)

#remove a global system
func add_global(key : String, global : Node):
	print("Attempting to add global script")
	if globals.has(key):
		print("Key already exists in globals: ", key)
		return
	for k in globals:
		if globals[k]==global:
			print("global already exists in global: ", global.name)
			return
	globals[key] = global
	if global.has_method("_ready"):
		global._ready()
	print("successfully added global script")

#attempts to remove a value by key
func remove_global(key : String):
	print("Removing global by key")
	if !globals.has(key):
		print("key does NOT exist in globals, failed to remove: ",key)
		return
	globals.erase(key)

#attempts to remove a system by value
func remove_global_value(global : Node):
	print("Removing global by value")
	for k in globals:
		if globals[k] == global:
			print("global removed")
			globals.erase(k)
			return
	print("value NOT gound in globals")

#attempting to pull a global
func get_global(key : String) -> Node:
	print("Attempting to retrieve a global")
	if globals.has(key):
		print("global found ")
		return globals[key]
	print("global not found returning null")
	return null
