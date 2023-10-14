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

	# We need to trigger the transition to make sure we get to 'idle' before 
	# firing any signals since they will effectively halt execution of the state machine in its
	# tracks.
	emit_signal("finished", "idle")

	_dialog_manager.interrupt()
	_dialog_player.emit_signal("say_finished")


func exit():
	escoria.logger.trace(self, "Dialog State Machine: Leaving 'finish'.")
