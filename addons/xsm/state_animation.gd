# MIT LICENSE Copyright 2020-2021 Etienne Blanc - ATN
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
@tool
class_name StateAnimation, "res://addons/xsm/icons/state_animation.png"
extends State

# StateAnimation is there for all your States that play an animation on enter
#
# The usual way of using this class is to add a StateAnimation in your tree
# Then, you can chose an anim_on_enter and how much time it will play
# In on_anim_finished in the inspector, you can define what you want to do next
#
# You have additionnal functions to inherit:
#  _on_anim_finished(_name)
#     where _name is the name of the animation
#     You can differentiate between animations played (using play() below)
#
# There are additionnal functions to call in your StateAnimation:
#  play(anim: String, custom_speed: float = 1.0, from_end: bool = false) -> void:
#  play_backwards(anim: String) -> void:
#  play_blend(anim: String, custom_blend: float, custom_speed: float = 1.0,
#  play_sync(anim: String, custom_speed: float = 1.0,
#  pause() -> void:
#  queue(anim: String) -> void:
#  stop(reset: bool = true) -> void:
#  is_playing(anim: String) -> bool:


# EXPORTS
#
# Is exported in "_get_property_list():"
var anim_on_enter := "" setget set_anim_on_enter
var anim_times_to_play := 1
var anim_times_played := 0
enum {ANIM_FINISHED_CALLBACK, ANIM_FINISHED_LOOP, ANIM_FINISHED_CHAIN, ANIM_FINISHED_PARENT, ANIM_FINISHED_SELF}
var on_anim_finished := 0 setget set_on_anim_finished
var chained_anim := ""
var chained := false

# Is exported in "_get_property_list():" for root only
var animation_player: NodePath = NodePath() setget set_animation_player

#
# INIT
#
func _ready() -> void:
	if Engine.is_editor_hint() and not is_connected("renamed"):
		var _conn = self.renamed.connect(self._on_StateAnimation_renamed)
	
	set_anim_on_enter(anim_on_enter)
	if not animation_player or animation_player.is_empty():
		animation_player = guess_animation_player()
	

func _get_configuration_warning() -> String:
	if not animation_player or animation_player.is_empty():
		var warning := "Warning : Your StateAnimation does not have an AnimationPlayer set up.\n"
		warning += "Either set it in the inspector or have an AnimationPlayer be a sibling of your XSM's root"
		return warning
	return ""


# We want to add some export variables in their categories
# And separate those of the root state
func _get_property_list():
	var properties = []

	var ap_ok := true
	# Will guess the AnimationPlayer each time
	# the inspector loads for this Node
	if not animation_player or animation_player.is_empty():
		animation_player = guess_animation_player()
	if not animation_player or animation_player.is_empty():
		ap_ok = false
	
	# Adds a State category in the inspector
	properties.append({
		name = "StateAnimation",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})

	properties.append({
		name = "animation_player",
		type = TYPE_NODE_PATH
	})

	# Will guess the animation to play
	if ap_ok:
		var ap = get_node_or_null(animation_player)
		if ap and ap.has_animation(name) and anim_on_enter == "":
			anim_on_enter = name


		var anims_hint = "NONE"
		if ap:
			for anim in get_node_or_null(animation_player).get_animation_list():
				anims_hint = "%s,%s" % [anims_hint, anim]
		properties.append({
			name = "anim_on_enter",
			type = TYPE_STRING,
			hint = PROPERTY_HINT_ENUM, 
			"hint_string": anims_hint
		})

		if anim_on_enter != "NONE" and anim_on_enter != "": #ANIM_ENTER_NONE:
			properties.append({
				name = "anim_times_to_play",
				type = TYPE_INT,
				hint =  PROPERTY_HINT_RANGE,
				"hint_string": "1,10,or_greater"
			})
			properties.append({
				name = "on_anim_finished",
				type = TYPE_INT,
				hint = PROPERTY_HINT_ENUM, 
				"hint_string": "Callback Only:0, Loop Anim:1, Chained Anim:2, Parent's choice:3, Next from Self:4"
			})
		if on_anim_finished == ANIM_FINISHED_CHAIN:
			properties.append({
				name = "chained_anim",
				type = TYPE_STRING,
				hint = PROPERTY_HINT_ENUM,
				"hint_string": anims_hint
			})

	update_configuration_warning()
	return properties


func property_can_revert(property):
	if property == "animation_player":
		return true
	if property == "anim_times_to_play":
		return true
	if property == "on_anim_finished":
		return ANIM_FINISHED_CALLBACK
	return .property_can_revert(property)


func property_get_revert(property):
	if property == "animation_player":
		return guess_animation_player()
	if property == "anim_times_to_play":
		return 1
	return .property_get_revert(property)


#
# SETTERS
#
func set_anim_on_enter(value):
	anim_on_enter = value
	property_list_changed_notify()


func set_on_anim_finished(value):
	on_anim_finished = value
	property_list_changed_notify()


# this setter to recheck the warning on a missing AnimationPlayer
func set_animation_player(value):
	if value:
		animation_player = value
	update_configuration_warning()


#
# FUNCTIONS TO INHERIT
#
func _on_anim_finished(_name: String) -> void:
	pass


#
# FUNCTIONS TO CALL IN INHERITED STATES
#
func play(anim: String, custom_speed: float = 1.0, from_end: bool = false) -> void:
	if disabled or status != ACTIVE:
		return
	var anim_player = get_node_or_null(animation_player)
	if anim_player and anim_player.has_animation(anim):
		if not anim_player.is_playing() or anim_player.current_animation != anim:
			# anim_player.stop()
			anim_player.play(anim)
			# The goal here is to provide a way to change state automatically at the end of an animation
			if anim_player.animation_finished.is_connected(self._on_AnimationPlayer_animation_finished):
				anim_player.animation_finished.disconnect(self._on_AnimationPlayer_animation_finished)
			anim_player.animation_finished.connect(self._on_AnimationPlayer_animation_finished)


func play_backwards(anim: String) -> void:
	play(anim, -1.0, true)


func play_blend(anim: String, custom_blend: float, custom_speed: float = 1.0,
		from_end: bool = false) -> void:
	var anim_player = get_node_or_null(animation_player)
	if status == ACTIVE and anim_player != null and anim_player.has_animation(anim):
		if anim_player.current_animation != anim:
			anim_player.play(anim, custom_blend, custom_speed, from_end)


func play_sync(anim: String, custom_speed: float = 1.0,
		from_end: bool = false) -> void:
	var anim_player = get_node_or_null(animation_player)
	if status == ACTIVE and anim_player != null and anim_player.has_animation(anim):
		var curr_anim: String = anim_player.current_animation
		if curr_anim != anim and curr_anim != "":
			var curr_anim_pos: float = anim_player.current_animation_position
			var curr_anim_length: float = anim_player.current_animation_length
			var ratio: float = curr_anim_pos / curr_anim_length
			play(anim, custom_speed, from_end)
			anim_player.seek(ratio * anim_player.current_animation_length)
		else:
			play(anim, custom_speed, from_end)


func pause() -> void:
	stop(false)


func queue(anim: String) -> void:
	var anim_player = get_node_or_null(animation_player)
	if status == ACTIVE and anim_player != null and anim_player.has_animation(anim):
		anim_player.queue(anim)


func stop(reset: bool = true) -> void:
	var anim_player = get_node_or_null(animation_player)
	if status == ACTIVE and anim_player != null:
		anim_player.stop(reset)
		state_root.current_anim_priority = 0


func is_playing(anim: String) -> bool:
	var anim_player = get_node_or_null(animation_player)
	if anim_player != null:
		return anim_player.current_animation == anim
	return false


#
# PRIVATE FUNCTIONS
#
func guess_animation_player() -> NodePath:
	if not state_root:
		state_root = get_parent().state_root
	for c in state_root.get_parent().get_children():
		if c is AnimationPlayer:
			return get_path_to(c)
	return NodePath()


func exit(args = null) -> void:
	chained = false
	anim_times_played = 0
	var anim_player = get_node_or_null(animation_player)
	if anim_player and anim_player.animation_finished.is_connected(self._on_AnimationPlayer_animation_finished):
		anim_player.animation_finished.disconnect(self._on_AnimationPlayer_animation_finished)

	.exit(args)
		

func enter(args = null) -> void:
	.enter(args)

	if anim_on_enter != "" and anim_on_enter != "NONE":
		play(anim_on_enter)


func _on_AnimationPlayer_animation_finished(finished_animation):
	if chained:
		play(chained_anim)
	elif finished_animation == anim_on_enter:	
		anim_times_played += 1
		if anim_times_played >= anim_times_to_play:
			_on_anim_finished(finished_animation)
			match on_anim_finished:
				ANIM_FINISHED_LOOP:
					play(finished_animation)
				ANIM_FINISHED_CHAIN:
					if chained_anim != "" and chained_anim != "NONE":
						play(chained_anim)
						chained = true
				ANIM_FINISHED_PARENT:
					if get_parent().get_class() == "State":
						get_parent().change_to_next_substate()
				ANIM_FINISHED_SELF:
					change_to_next()
			anim_times_played = 0
		else:
			play(finished_animation)


func _on_StateAnimation_renamed():
	# Will guess the animation to play
	var ap = get_node_or_null(animation_player)
	if ap and ap.has_animation(name) and anim_on_enter == "":
		anim_on_enter = name
