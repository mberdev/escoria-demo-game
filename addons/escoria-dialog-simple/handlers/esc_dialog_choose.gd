extends ESCDialogManager


# State machine that governs how the dialog manager behaves
var _state_machine = null setget set_state_machine

# Reference to the dialog player
var _dialog_player: Node = null


func set_state_machine(state_machine) -> void:
	if is_instance_valid(_state_machine):
		remove_child(_state_machine)
		_state_machine.queue_free() # keep an eye on this

	_state_machine = state_machine

	add_child(_state_machine)


# Present an option chooser to the player and sends the signal
# `option_chosen` with the chosen dialog option
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
# - type: The dialog chooser type to use
func choose(dialog_player: Node, dialog: ESCDialog, type: String):
	_dialog_player = dialog_player

	_state_machine._change_state("choices")


func do_choose(dialog_player: Node, dialog: ESCDialog, type: String = "simple"):
	var chooser

	if type == "simple" or type == "":
		chooser = preload(\
			"res://addons/escoria-dialog-simple/chooser/simple.tscn"\
		).instance()

	dialog_player.add_child(chooser)
	chooser.set_dialog(dialog)
	chooser.show_chooser()

	var option = yield(chooser, "option_chosen")
	dialog_player.remove_child(chooser)
	emit_signal("option_chosen", option)
