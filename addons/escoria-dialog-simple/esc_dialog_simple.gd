# A simple dialog manager for Escoria
extends ESCDialogManager


var speech_state_machine = preload("res://addons/escoria-dialog-simple/handlers/state_machines/esc_dialog_speech_state_machine.gd").new()

var speech_manager: Node = preload("res://addons/escoria-dialog-simple/handlers/esc_dialog_render.gd").new()

var current_manager: Node = null

# The currently running player
var _type_player: Node = null

# Reference to the dialog player
var _dialog_player: Node = null


func _ready() -> void:
	speech_manager.set_state_machine(speech_state_machine)
	add_child(speech_manager)


# Check whether a specific type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Whether the type is supported or not
func has_type(type: String) -> bool:
	return true if type in ["floating", "avatar"] else false


# Check whether a specific chooser type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required chooser type
# *Returns* Whether the type is supported or not
func has_chooser_type(type: String) -> bool:
	return true if type == "simple" else false


# Instructs the dialog manager to preserve the next dialog box used by a `say`
# command until a call to `disable_preserve_dialog_box` is made.
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `disable_preserve_dialog_box` being called, the result should be the
# same.
func enable_preserve_dialog_box() -> void:
	if is_instance_valid(speech_manager):
		speech_manager.enable_preserve_dialog_box()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)


# Instructs the dialog manager to no longer preserve the currently-preserved
# dialog box or to not preserve the next dialog box used by a `say` command
# (this is the default state).
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `enable_preserve_dialog_box` being called, the result should be the
# same.
func disable_preserve_dialog_box() -> void:
	if is_instance_valid(speech_manager):
		speech_manager.disable_preserve_dialog_box()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)

# Output a text said by the item specified by the global id. Emit
# `say_finished` after finishing displaying the text.
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - global_id: Global id of the item that is speaking
# - text: Text to say, optional prefixed by a translation key separated
#   by a ":"
# - type: Type of dialog box to use
func say(dialog_player: Node, global_id: String, text: String, type: String):
	_init_speech_manager(global_id, text, type, dialog_player)

	speech_manager.say(dialog_player, global_id, text, type)


func do_narrator_say(global_id: String, text: String) -> void:
	# Only add_child here in order to prevent _type_player from running its _process method
	# before we're ready, and only if it's necessary
	if not _dialog_player.get_children().has(_type_player):
		_dialog_player.add_child(_type_player)

	_type_player.say(global_id, text)


func _init_speech_manager(global_id: String, text: String, type: String, dialog_player: Node) -> void:
	speech_state_machine.initialize_states(speech_manager, global_id, text, type, dialog_player)

	if not speech_manager.is_connected("say_finished", self, "_on_say_finished"):
		speech_manager.connect("say_finished", self, "_on_say_finished")

	if not speech_manager.is_connected("say_visible", self, "_on_say_visible"):
		speech_manager.connect("say_visible", self, "_on_say_visible")

	current_manager = speech_manager


func _on_say_finished():
	emit_signal("say_finished")


func _on_say_visible():
	emit_signal("say_visible")


func _on_narrator_say_visible():
	emit_signal("narrator_say_visible")


# Present an option chooser to the player and sends the signal
# `option_chosen` with the chosen dialog option
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
# - type: The dialog chooser type to use
func choose(dialog_player: Node, dialog: ESCDialog, type: String):
	_dialog_player = dialog_player

#	state_machine.states_map["choices"].initialize(dialog_player, self, dialog, type)
#	state_machine._change_state("choices")


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


# Trigger running the dialogue faster
func speedup():
	if is_instance_valid(speech_manager):
		speech_manager.speedup()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)

# Trigger an instant finish of the current dialog
func finish():
	if is_instance_valid(speech_manager):
		speech_manager.finish()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)


# The say command has been interrupted, cancel the dialog display
func interrupt():
	if is_instance_valid(speech_manager):
		speech_manager.interrupt()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)


# To be called if voice audio has finished.
func voice_audio_finished():
	if is_instance_valid(speech_manager):
		speech_manager.voice_audio_finished()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)
