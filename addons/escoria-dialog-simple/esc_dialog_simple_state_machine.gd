extends "res://addons/escoria-dialog-simple/patterns/state_machine/state_machine.gd"


func _init():
	_create_states()
	_add_states_to_machine()

	current_state_name = "idle"
	START_STATE = states_map[current_state_name]

	initialize(START_STATE)


# Creates the states for this state machine.
func _create_states() -> void:
	states_map = {
		# "idle" state is entry point for the state machine for all states.
		"idle": preload("res://addons/escoria-dialog-simple/states/dialog_idle.gd").new(),

		# States relevant to characters/items speaking.
		"say":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_say.gd").new(),
		"say_fast":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_say_fast.gd").new(),
		"say_finish":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_say_finish.gd").new(),
		"visible":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_visible.gd").new(),
		"finish":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_finish.gd").new(),
		"interrupt":  preload("res://addons/escoria-dialog-simple/states/speak/dialog_interrupt.gd").new(),

		# States relevant to the narrator speaking.
#		"narrator_say":  preload("res://addons/escoria-dialog-simple/states/narrator/dialog_narrator_say.gd").new(),

		# States relevant to dialog choices.
		"choices":  preload("res://addons/escoria-dialog-simple/states/choose/dialog_choices.gd").new(),
	}


# Adds any created states into the state machine as children.
func _add_states_to_machine() -> void:
	for key in states_map:
		add_child(states_map[key])
