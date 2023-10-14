extends "res://addons/escoria-dialog-simple/patterns/state_machine/state.gd"


# A regular expression that separates the translation key from the text
const KEYTEXT_REGEX = "^((?<key>[^:]+):)?\"(?<text>.+)\""


# Reference to the currently playing dialog manager
var _dialog_manager: ESCDialogManager = null

# Text to say
var _text: String

# Regular expression object for the separation of key and text
var _keytext_regex: RegEx = RegEx.new()

var _ready_to_say: bool


# Constructor
func _init() -> void:
	_keytext_regex.compile(KEYTEXT_REGEX)


func initialize(dialog_manager: ESCDialogManager, text: String) -> void:
	_dialog_manager = dialog_manager
	_text = text


func enter():
	escoria.logger.trace(self, "Dialog State Machine: Entered 'say'.")

#	if not _dialog_manager.is_connected("say_visible", self, "_on_say_visible"):
#		_dialog_manager.connect("say_visible", self, "_on_say_visible")

	var matches = _keytext_regex.search(_text)

	if not matches:
		escoria.logger.error(
			self,
			"Unexpected text encountered: %s." % _text
		)

	var key = matches.get_string("key")

	if matches.get_string("key") != "":
		var _speech_resource = _get_voice_file(
			matches.get_string("key")
		)

		if _speech_resource == "":
			escoria.logger.warn(
				self,
				"Unable to find voice file with key '%s'." % matches.get_string("key")
			)
		else:
			(
				escoria.object_manager.get_object(escoria.object_manager.SPEECH).node\
				 as ESCSpeechPlayer
			).set_state(_speech_resource)

		var translated_text: String = tr(matches.get_string("key"))

		# Only update the text if the translated text was found; otherwise, raise
		# a warning and use the original, untranslated text.
		if translated_text == matches.get_string("key"):
			escoria.logger.warn(
				self,
				"Unable to find translation key '%s'. Using untranslated text." % matches.get_string("key")
			)
			_text = matches.get_string("text")
		else:
			_text = translated_text
	else:
		_text = matches.get_string("text")

	_ready_to_say = true


func update(_delta):
	if _ready_to_say:
		_dialog_manager.do_narrator_say(_text)
		emit_signal("finished", "say_finish")
		_ready_to_say = false


# Find the matching voice output file for the given key
#
# #### Parameters
#
# - key: Text key provided
# - start: Starting folder to search for voices
#
# *Returns* The path to the matching voice file
func _get_voice_file(key: String, start: String = "") -> String:
	if start == "":
		start = ESCProjectSettingsManager.get_setting(
			ESCProjectSettingsManager.SPEECH_FOLDER
		)
	var _dir = Directory.new()
	if _dir.open(start) == OK:
		_dir.list_dir_begin(true, true)
		var file_name = _dir.get_next()
		while file_name != "":
			if _dir.current_is_dir():
				var _voice_file = _get_voice_file(
					key,
					start.plus_file(file_name)
				)
				if _voice_file != "":
					return _voice_file
			else:
				if file_name == "%s.%s.import" % [
					key,
					ESCProjectSettingsManager.get_setting(
						ESCProjectSettingsManager.SPEECH_EXTENSION
					)
				]:
					return start.plus_file(file_name.trim_suffix(".import"))
			file_name = _dir.get_next()
	return ""


#func _on_say_visible() -> void:
#	escoria.logger.trace(self, "Dialog State Machine: 'say' -> 'visible'")
#	emit_signal("finished", "visible")
