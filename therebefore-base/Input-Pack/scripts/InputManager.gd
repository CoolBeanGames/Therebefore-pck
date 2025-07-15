extends Node
class_name Inputs

var discreet_actions = ["confirm","cancel","pause","up", "down", "left","right",
"sprint","crouch","aux_1","aux_2","aux_3","aux_4"]

@export var look_axis : Vector2
@export var move_axis : Vector2
@export var input_paused : bool = false
@export var input_lockers : Dictionary[int,Array] = {}

#region signals
signal confirm_pressed
signal confirm_released
signal cancel_pressed
signal cancel_released
signal pause_pressed
signal pause_released
signal sprint_pressed
signal sprint_released
signal crouch_pressed
signal crouch_released
signal up_pressed
signal up_released
signal down_pressed
signal down_released
signal left_pressed
signal left_released
signal right_pressed
signal right_released
signal aux_1_pressed
signal aux_1_released
signal aux_2_pressed
signal aux_2_released
signal aux_3_pressed
signal aux_3_released
signal aux_4_pressed
signal aux_4_released

signal camera_moved(Vector2)
signal movement_input(Vector2)
#endregion

func check_all_inputs():
	for a in discreet_actions:
		check_single_input(a)

func check_single_input(action : String):
	if !InputMap.has_action(action):
		print("Error in check single input. Action: ", action, " Does not exist")
	if Input.is_action_just_pressed(action):
		emit_signal(action + "_pressed")
	if Input.is_action_just_released(action):
		emit_signal(action + "_released")

func _process(delta: float) -> void:
	check_all_inputs()
	move_axis = Input.get_vector("left","right","up","down")
	if move_axis != Vector2.ZERO:
		movement_input.emit(move_axis)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_axis = event.relative
		camera_moved.emit(look_axis)


#region input_locking

func lock_input(locker : Node):
	var locker_id = locker.get_instance_id()
	
	if input_lockers.has(locker_id):
		print("Inputs: Attempted to lock input, but it is already locked by node UID: %s (Node: %s)." % [locker_id, locker.name])
		return

	# Create the Callable for disconnection, binding the locker_id to unlock_input_by_id
	var unlock_callable_for_disconnect = Callable(self, "unlock_input_by_id").bind(locker_id)
	
	# Store the node reference AND the specific bound Callable object
	input_lockers[locker_id] = [locker, unlock_callable_for_disconnect] 
	
	# Connect to the locker node's tree_exiting signal using the stored Callable
	if not locker.tree_exiting.is_connected(unlock_callable_for_disconnect):
		locker.tree_exiting.connect(unlock_callable_for_disconnect)
	
	is_locked() # Recalculate input_paused status
	print("Inputs: Input locked by node UID: %s (Node: %s). Total active lockers: %d" % [locker_id, locker.name, input_lockers.size()])

func unlock_input(locker : Node):
	# Directly call the by_id version, passing the node's current ID
	unlock_input_by_id(locker.get_instance_id())

# This helper function allows unlocking by ID, useful for tree_exiting signal
func unlock_input_by_id(locker_id: int):
	if not input_lockers.has(locker_id):
		print("Inputs: Attempted to unlock input, but failed: UID %s is not currently an active locker." % locker_id)
		return
	
	# Retrieve the stored node reference and Callable
	var stored_data = input_lockers[locker_id]
	var locker_node = stored_data[0] # The node reference
	var unlock_callable_for_disconnect = stored_data[1] # The exact Callable object used for connection
	
	input_lockers.erase(locker_id) # Remove from active lockers
	
	# Disconnect the tree_exiting signal using the exact stored Callable object
	if is_instance_valid(locker_node) and locker_node.tree_exiting.is_connected(unlock_callable_for_disconnect):
		locker_node.tree_exiting.disconnect(unlock_callable_for_disconnect)
	
	is_locked() # Recalculate input_paused status
	print("Inputs: Input unlocked by node UID: %s. Total active lockers: %d" % [locker_id, input_lockers.size()])

func is_locked () -> bool:
	# Periodic cleanup: Remove any locker IDs whose associated nodes have become invalid
	var uids_to_remove = []
	for uid in input_lockers.keys():
		# Access the node reference from the stored Array
		if not is_instance_valid(input_lockers[uid][0]): 
			uids_to_remove.append(uid)
	
	for uid in uids_to_remove:
		# Also retrieve the callable to ensure clean disconnect before erasing
		var stored_data = input_lockers[uid]
		var locker_node = stored_data[0]
		var unlock_callable_for_disconnect = stored_data[1]
		
		input_lockers.erase(uid)
		print("Inputs: Input Locker Cleanup: Removed invalid locker UID: %s (node no longer valid)." % uid)
		
		# Attempt to disconnect if still valid, to be thorough (though node might be fully gone)
		if is_instance_valid(locker_node) and locker_node.tree_exiting.is_connected(unlock_callable_for_disconnect):
			locker_node.tree_exiting.disconnect(unlock_callable_for_disconnect)

	input_paused = input_lockers.size() > 0
	return input_paused


#endregion
