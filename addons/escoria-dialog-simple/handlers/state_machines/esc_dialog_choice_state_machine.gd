extends "res://addons/escoria-dialog-simple/patterns/state_machine/state_machine.gd"


func _init():
	_create_states()
	_add_states_to_machine()

	current_state_name = "idle"
	START_STATE = states_map[current_state_name]

	initialize(START_STATE)


# #### Parameters
# - dialog_manager: Dialog manager to work with
# - dialog: Information about the dialog to display
# - type: Type of dialog box to use
# - dialog_player: Node of the dialog player in the UI
func initialize_states(dialog_manager: ESCDialogManager, dialog: ESCDialog, type: String, dialog_player: Node) -> void:
	states_map["choices"].initialize(dialog_player, dialog_manager, dialog, type)


# Creates the states for this state machine.
func _create_states() -> void:
	states_map = {
		"idle": preload("res://addons/escoria-dialog-simple/states/dialog_idle.gd").new(),
		"choices":  preload("res://addons/escoria-dialog-simple/states/choose/dialog_choices.gd").new(),
	}


# Adds any created states into the state machine as children.
func _add_states_to_machine() -> void:
	for key in states_map:
		add_child(states_map[key])
