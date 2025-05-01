@tool
extends VBoxContainer

var editor_interface: EditorInterface
@onready var bookmark_tree: Tree = $Tree
@onready var add_button: Button = $HBoxContainer/AddBookmarkButton
@onready var remove_button: Button = $HBoxContainer/RemoveBookmarkButton

func _ready():
	bookmark_tree.clear()
	bookmark_tree.set_hide_root(false)  # ← SHOW root for now to keep it clean
	var root = bookmark_tree.create_item()  # ← Required when root is visible
	root.set_text(0, "Bookmarks")

func add_bookmark(name: String, node_path: NodePath):
	var root = bookmark_tree.get_root()
	var item = bookmark_tree.create_item(root)
	item.set_text(0, name)
	item.set_metadata(0, node_path)

func _on_tree_item_selected():
	var selected = bookmark_tree.get_selected()
	if not selected or selected.get_metadata(0) == null:
		return

	var node_path = selected.get_metadata(0)
	var scene_root = get_tree().edited_scene_root
	var target_node = scene_root.get_node_or_null(node_path)
	if target_node:
		editor_interface.edit_node(target_node)


func _on_add_bookmark_button_pressed():
	var selection = editor_interface.get_selection().get_selected_nodes()
	if selection.size() == 0:
		return

	var node = selection[0]
	var node_path = node.get_path()
	add_bookmark(node.name, node_path)


func _on_remove_bookmark_button_pressed() -> void:
	var selected = bookmark_tree.get_selected()
	if selected:
		selected.free()
