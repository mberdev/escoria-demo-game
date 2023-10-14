# A simple dialog manager for Escoria
extends ESCDialogManager


var _speech_state_machine = preload("res://addons/escoria-dialog-simple/handlers/state_machines/esc_dialog_speech_state_machine.gd").new()
var _narrator_state_machine = preload("res://addons/escoria-dialog-simple/handlers/state_machines/esc_dialog_narrator_state_machine.gd").new()
var _choice_state_machine = preload("res://addons/escoria-dialog-simple/handlers/state_machines/esc_dialog_choice_state_machine.gd").new()

var _speech_manager: Node = preload("res://addons/escoria-dialog-simple/handlers/esc_dialog_render.gd").new()
var _choice_manager: Node = preload("res://addons/escoria-dialog-simple/handlers/esc_dialog_choose.gd").new()

var _current_manager: Node = null


func _ready() -> void:
	_speech_manager.set_state_machine(_speech_state_machine) # default
	_choice_manager.set_state_machine(_choice_state_machine)


# Check whether a specific type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Whether the type is supported or not
func has_type(type: String) -> bool:
	return _speech_manager.has_type(type)


# Check whether a specific chooser type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required chooser type
# *Returns* Whether the type is supported or not
func has_chooser_type(type: String) -> bool:
	return _choice_manager.has_chooser_type(type)


# Check whether a specific narrator type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Whether the narrator type is supported or not
func has_narrator_type(type: String) -> bool:
	return _speech_manager.has_narrator_type(type)


# Instructs the dialog manager to preserve the next dialog box used by a `say`
# command until a call to `disable_preserve_dialog_box` is made.
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `disable_preserve_dialog_box` being called, the result should be the
# same.
func enable_preserve_dialog_box() -> void:
	if is_instance_valid(_speech_manager):
		_speech_manager.enable_preserve_dialog_box()
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
	if is_instance_valid(_speech_manager):
		_speech_manager.disable_preserve_dialog_box()
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
	_speech_state_machine.initialize_states(_speech_manager, global_id, text, dialog_player)
	_speech_manager.set_state_machine(_speech_state_machine)

	_init_dialog_manager(global_id, text, type, dialog_player)

	_speech_manager.say(dialog_player, global_id, text, type)


# Output text said by an offscreen "narrator". Emit
# `say_finished` after finishing displaying the text.
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - text: Text to say, optional prefixed by a translation key separated
#   by a ":"
# - type: Type of dialog box to use
func narrator_say(dialog_player: Node, text: String, type: String) -> void:
	_narrator_state_machine.initialize_states(_speech_manager, text, dialog_player)
	_speech_manager.set_state_machine(_narrator_state_machine)

	_init_dialog_manager("", text, type, dialog_player)

	_speech_manager.narrator_say(dialog_player, text, type)


# Initializer the dialog manager.
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
# - type: The dialog chooser type to use
func _init_dialog_manager(global_id: String, text: String, type: String, dialog_player: Node) -> void:
	if not _speech_manager.is_connected("say_finished", self, "_on_internal_say_finished"):
		_speech_manager.connect("say_finished", self, "_on_internal_say_finished")

	if not _speech_manager.is_connected("say_visible", self, "_on_internal_say_visible"):
		_speech_manager.connect("say_visible", self, "_on_internal_say_visible")

	_attach_manager(_current_manager, _speech_manager)

	_current_manager = _speech_manager


func _attach_manager(old_manager, new_manager) -> void:
	if is_instance_valid(old_manager):
		remove_child(old_manager)

	add_child(new_manager)


func _on_internal_say_finished():
	emit_signal("say_finished")


func _on_internal_say_visible():
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
	_init__choice_manager(dialog_player, dialog, type)

	_choice_manager.choose(dialog_player, dialog, type)


# Initializer the dialog choice manager.
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
# - type: The dialog chooser type to use
func _init__choice_manager(dialog_player: Node, dialog: ESCDialog, type: String) -> void:
	_choice_state_machine.initialize_states(_choice_manager, dialog, type, dialog_player)

	_attach_manager(_current_manager, _choice_manager)

	_current_manager = _choice_manager


# Trigger running the dialogue faster
func speedup():
	if is_instance_valid(_speech_manager):
		_speech_manager.speedup()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)

# Trigger an instant finish of the current dialog
func finish():
	if is_instance_valid(_speech_manager):
		_speech_manager.finish()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)


# The say command has been interrupted, cancel the dialog display
func interrupt():
	if is_instance_valid(_speech_manager):
		_speech_manager.interrupt()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)


# To be called if voice audio has finished.
func voice_audio_finished():
	if is_instance_valid(_speech_manager):
		_speech_manager.voice_audio_finished()
		return

	escoria.logger.warn(
		self,
		"No valid speech manager!"
	)
