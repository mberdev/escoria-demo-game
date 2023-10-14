extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# Owning dialog player
var _dialog_player

var _dialog_manager


func initialize(dialog_manager, dialog_player) -> void:
	_dialog_manager = dialog_manager
	_dialog_player = dialog_player


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'finish'.")


func update(_delta):
	escoria.logger.trace(self, "Dialog State Machine: 'finish' -> 'idle'")
	_dialog_manager.interrupt()
	_dialog_player.emit_signal("say_finished")
	emit_signal("finished", "idle")


func exit():
	escoria.logger.trace(self, "Dialog State Machine: Leaving 'finish'.")
