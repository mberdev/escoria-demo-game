extends "res://addons/escoria-dialog-simple/patterns/state_machine/state_machine.gd"


func _init() -> void:
	_create_states()
	_add_states_to_machine()

	current_state_name = "idle"
	START_STATE = states_map[current_state_name]

	initialize(START_STATE)


# #### Parameters
# - dialog_manager: Dialog manager to work with
# - global_id: Global id of the item that is speaking
# - text: Text to say, optional prefixed by a translation key separated
#   by a ":"
# - type: Type of dialog box to use
# - dialog_player: Node of the dialog player in the UI
func initialize_states(dialog_manager: ESCDialogManager, global_id: String, text: String, type: String, dialog_player: Node) -> void:
	states_map["say"].initialize(dialog_manager, global_id, text, type)
	states_map["say_fast"].initialize(dialog_manager)
	states_map["say_finish"].initialize(dialog_manager)
	states_map["visible"].initialize(dialog_manager)
	states_map["interrupt"].initialize(dialog_manager)
	states_map["finish"].initialize(dialog_player)


# Creates the states for this state machine.
func _create_states() -> void:
	states_map = {
		"idle": preload("res://addons/escoria-dialog-simple/states/dialog_idle.gd").new(),
		"say":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_say.gd").new(),
		"say_fast":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_say_fast.gd").new(),
		"say_finish":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_say_finish.gd").new(),
		"visible":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_visible.gd").new(),
		"finish":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_finish.gd").new(),
		"interrupt":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_interrupt.gd").new(),
	}


# Adds any created states into the state machine as children.
func _add_states_to_machine() -> void:
	for key in states_map:
		add_child(states_map[key])
