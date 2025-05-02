@tool
extends EditorPlugin

var dock
var last_scene_path: String = ""

func _enter_tree():
	var interface = get_editor_interface()
	dock = preload("res://addons/node_bookmarker/BookmarkDock.tscn").instantiate()
	dock.editor_interface = interface
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	set_process(true)

	add_tool_menu_item("Add Selected Node to Bookmarks", Callable(self, "_on_add_bookmark_pressed"))

func _exit_tree():
	remove_control_from_docks(dock)
	dock.queue_free()
	remove_tool_menu_item("Add Selected Node to Bookmarks")

func _on_add_bookmark_pressed():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.is_empty():
		return

	var node = selection[0]
	var node_path = node.get_path()
	dock.add_bookmark(node.name, node_path)

func _edit(_object):
	if dock:
		dock.load_bookmarks_for_scene()
		
func _process(_delta):
	var current_scene = get_tree().edited_scene_root
	if not current_scene:
		return

	var current_path = current_scene.scene_file_path
	if current_path != "" and current_path != last_scene_path:
		last_scene_path = current_path
		dock.load_bookmarks_for_scene()
