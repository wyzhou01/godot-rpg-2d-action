# MIT LICENSE Copyright 2020-2023 Etienne Blanc - ATN
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
extends EditorPlugin

const submenu_name = "Copy blank state to clipboard"
const template_root = "res://addons/xsm/templates/"
func _enter_tree():
	add_custom_type("State", "Node", load("res://addons/xsm/state.gd"), 		load("res://addons/xsm/icons/state.png"))
	add_custom_type("StateAnimation", "Node", load("res://addons/xsm/state_animation.gd"), 		load("res://addons/xsm/icons/state.png"))
	add_custom_type("StateLoop", "Node", load("res://addons/xsm/state_loop.gd"), 		load("res://addons/xsm/icons/state_loop.png"))
	add_custom_type("StateRegions", "Node", load("res://addons/xsm/state_regions.gd"), 		load("res://addons/xsm/icons/state_regions.png"))
	add_custom_type("StateRand", "Node", load("res://addons/xsm/state_rand.gd"), 		load("res://addons/xsm/icons/state_rand.png"))
	add_tool_submenu_item(submenu_name,get_state_helper_popup())
	ProjectSettings.set_setting("editor/script_templates_search_path", "res://addons/xsm/templates/")


func _exit_tree():
	remove_custom_type("StateRand")
	remove_custom_type("StateRegions")
	remove_custom_type("StateLoop")
	remove_custom_type("StateAnimation")
	remove_custom_type("State")
	remove_tool_menu_item(submenu_name)

	
func get_state_helper_popup()->Popup:
	var popup = PopupMenu.new()
	popup.add_item("State")
	popup.add_item("State Animation")
	popup.add_item("State Loop")
	popup.add_item("State Rand")
	popup.add_item("State Regions")
	popup.id_pressed.connect(self.submenu_pressed)
	return popup
	pass

func submenu_pressed(id):
	match(id):
		0: DisplayServer.clipboard_set(load_file(template_root+"/empty_state.gd"))
		1: DisplayServer.clipboard_set(load_file(template_root+"/empty_state_animation.gd"))
		2: DisplayServer.clipboard_set(load_file(template_root+"/empty_state_loop.gd"))
		3: DisplayServer.clipboard_set(load_file(template_root+"/empty_state_rand.gd"))
		4: DisplayServer.clipboard_set(load_file(template_root+"/empty_state_regions.gd"))
	pass
	
func load_file(file):
	var f = FileAccess
	FileAccess.open(file, FileAccess.READ)
	var text = f.get_as_text()
	f.close()
	return text
