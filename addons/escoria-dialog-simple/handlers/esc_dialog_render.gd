extends ESCDialogManager


# State machine that governs how the dialog manager behaves
var _state_machine = null setget set_state_machine

# The currently running player
var _type_player: Node = null
var _preserved_type_player_type: String = ""

# Reference to the dialog player
var _dialog_player: Node = null

# Basic state tracking
var _is_saying: bool = false

# Whether to preserve the next dialog box used by `say`, or, if already
# preserving a dialog box, whether to continue using that dialog box
var _should_preserve_dialog_box: bool = false


func set_state_machine(state_machine) -> void:
	if is_instance_valid(_state_machine):
		remove_child(_state_machine)

	_state_machine = state_machine

	add_child(_state_machine)


# Check whether a specific type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Whether the type is supported or not
func has_type(type: String) -> bool:
	return true if type in ["floating", "avatar"] else false


# Check whether a specific narrator type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# *Returns* Whether the narrator type is supported or not
func has_narrator_type(type: String) -> bool:
	return true if type in ["avatar"] else false


# Instructs the dialog manager to preserve the next dialog box used by a `say`
# command until a call to `disable_preserve_dialog_box` is made.
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `disable_preserve_dialog_box` being called, the result should be the
# same.
func enable_preserve_dialog_box() -> void:
	_should_preserve_dialog_box = true


# Instructs the dialog manager to no longer preserve the currently-preserved
# dialog box or to not preserve the next dialog box used by a `say` command
# (this is the default state).
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `enable_preserve_dialog_box` being called, the result should be the
# same.
func disable_preserve_dialog_box() -> void:
	_should_preserve_dialog_box = false

	if is_instance_valid(_dialog_player) and _dialog_player.get_children().has(_type_player):
		_dialog_player.remove_child(_type_player)
		_preserved_type_player_type = ""


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
	_dialog_player = dialog_player

	_resolve_type_player(type)

	_state_machine._change_state("say")


func do_say(global_id: String, text: String) -> void:
	# Only add_child here in order to prevent _type_player from running its _process method
	# before we're ready, and only if it's necessary
	if not _dialog_player.get_children().has(_type_player):
		_dialog_player.add_child(_type_player)

	_type_player.say(global_id, text)


# Output text said by an offscreen "narrator". Emit
# `say_finished` after finishing displaying the text.
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - text: Text to say, optional prefixed by a translation key separated
#   by a ":"
# - type: Type of dialog box to use
func narrator_say(dialog_player: Node, text: String, type: String):
	_dialog_player = dialog_player

	_resolve_type_player(type)

	_state_machine._change_state("say")


func do_narrator_say(text: String) -> void:
	# Only add_child here in order to prevent _type_player from running its _process method
	# before we're ready, and only if it's necessary
	if not _dialog_player.get_children().has(_type_player):
		_dialog_player.add_child(_type_player)
		_type_player.set_clear_text_by_click_only(true)

	_type_player.say("", text)


func _resolve_type_player(type: String) -> void:
	if _should_preserve_dialog_box:
		# If the dialog box type doesn't match what's currently being reused (if anything),
		# we want to remove the old one (if it exists) and then initialize and add the new dialog
		# box type to the dialog player
		if type != _preserved_type_player_type:
			if _dialog_player.get_children().has(_type_player):
				_dialog_player.remove_child(_type_player)

			_init_type_player(type)

		_preserved_type_player_type = type
	else:
		_init_type_player(type)


func _init_type_player(type: String) -> void:
	if type == "floating":
		_type_player = preload(\
			"res://addons/escoria-dialog-simple/types/floating.tscn"\
		).instance()
	else:
		_type_player = preload(\
			"res://addons/escoria-dialog-simple/types/avatar.tscn"\
		).instance()

	_type_player.connect("say_finished", self, "_on_say_finished")
	_type_player.connect("say_visible", self, "_on_say_visible")


func _on_say_finished():
	if not _should_preserve_dialog_box and _dialog_player.get_children().has(_type_player):
		_dialog_player.remove_child(_type_player)

	_is_saying = false

	emit_signal("say_finished")


func _on_say_visible():
	emit_signal("say_visible")


# Trigger running the dialogue faster
func speedup():
	if is_instance_valid(_type_player):
		_type_player.speedup()


# Trigger an instant finish of the current dialog
func finish():
	if is_instance_valid(_type_player):
		_type_player.finish()


# The say command has been interrupted, cancel the dialog display
func interrupt():
	if _dialog_player.get_children().has(_type_player):
		(
			escoria.object_manager.get_object(escoria.object_manager.SPEECH).node\
			 as ESCSpeechPlayer
		).set_state("off")

		if not _should_preserve_dialog_box and _dialog_player.get_children().has(_type_player):
			_dialog_player.remove_child(_type_player)

		emit_signal("say_finished")


# To be called if voice audio has finished.
func voice_audio_finished():
	if is_instance_valid(_type_player):
		_type_player.voice_audio_finished()