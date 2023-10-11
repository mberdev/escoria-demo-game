extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null


func initialize(dialog_manager: ESCDialogManager) -> void:
	_dialog_manager = dialog_manager


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'say_finish'.")

	if escoria.inputs_manager.input_mode != \
		escoria.inputs_manager.INPUT_NONE and \
		_dialog_manager != null:

		if not _dialog_manager.is_connected("say_visible", self, "_on_say_visible"):
			_dialog_manager.connect("say_visible", self, "_on_say_visible")

		_dialog_manager.finish()
	else:
		escoria.logger.error(self, "Illegal state.")


func exit() -> void:
	if _dialog_manager.is_connected("say_visible", self, "_on_say_visible"):
		_dialog_manager.disconnect("say_visible", self, "_on_say_visible")


func _on_say_visible() -> void:
	escoria.logger.trace(self, "Dialog State Machine: 'say_finish' -> 'visible'")
	emit_signal("finished", "visible")
