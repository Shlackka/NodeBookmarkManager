@tool
extends VBoxContainer

@onready var bookmark_tree: Tree = $Tree
@onready var add_button: Button = $HBoxContainer/AddBookmarkButton
@onready var remove_button: Button = $HBoxContainer/RemoveBookmarkButton
@onready var reload_button: Button = $HBoxContainer/ReloadButton
@onready var context_menu: PopupMenu = $ContextMenu
@onready var rename_dialog := $RenameDialog
@onready var rename_input := $RenameDialog/LineEdit

var editor_interface: EditorInterface
var pending_rename_item: TreeItem = null
var fallback_scene_key: String = ""

func _ready():
	bookmark_tree.clear()
	bookmark_tree.set_hide_root(false)
	var root = bookmark_tree.create_item()
	root.set_text(0, "Bookmarks")

	var scene_root = get_tree().edited_scene_root
	if scene_root:
		scene_root.connect("tree_exited", Callable(self, "_on_node_removed"), CONNECT_DEFERRED)

	load_bookmarks_for_scene()
	
	context_menu.connect("id_pressed", Callable(self, "_on_context_menu_pressed"))
	bookmark_tree.connect("gui_input", Callable(self, "_on_tree_gui_input"))


func add_bookmark(name: String, node_path: NodePath, locked := false):
	var scene_root = get_tree().edited_scene_root
	if not scene_root:
		return

	var target_node = scene_root.get_node_or_null(node_path)
	if not target_node:
		print("Node path not found when adding bookmark:", node_path)
		return

	var bookmark_id = ensure_node_has_bookmark_id(target_node)

	# Prevent duplicate ID bookmarks
	var root = bookmark_tree.get_root()
	var item = root.get_first_child()
	while item:
		var meta = item.get_metadata(0)
		if typeof(meta) == TYPE_DICTIONARY and meta.get("id") == bookmark_id:
			print("Node already bookmarked via ID:", bookmark_id)
			return
		item = item.get_next()

	var new_item = bookmark_tree.create_item(root)
	new_item.set_text(0, name)
	new_item.set_metadata(0, {
		"path": node_path,
		"id": bookmark_id,
		"name": name,
		"locked": locked
	})

	_save_current_bookmarks()

func _on_tree_item_selected():
	var selected = bookmark_tree.get_selected()
	if not selected:
		return

	var meta = selected.get_metadata(0)
	if typeof(meta) != TYPE_DICTIONARY or not meta.has("path"):
		return

	var node_path = meta["path"]
	var scene_root = get_tree().edited_scene_root
	if not scene_root:
		return

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
	if not selected:
		return

	if selected == bookmark_tree.get_root():
		print("Cannot remove the root 'Bookmarks' item.")
		return

	selected.free()
	_save_current_bookmarks()

func _on_reload_button_pressed():
	load_bookmarks_for_scene()

func ensure_node_has_bookmark_id(node: Node) -> String:
	if not node.has_meta("bookmark_id"):
		var new_id = str(Time.get_ticks_usec()) + "_" + node.name
		node.set_meta("bookmark_id", new_id)
		print("Assigned new bookmark ID:", new_id)
		return new_id
	return node.get_meta("bookmark_id")

func _get_save_path() -> String:
	return "user://node_bookmarks.json"

func _get_scene_key() -> String:
	var scene = get_tree().edited_scene_root
	if scene and scene.scene_file_path != "":
		fallback_scene_key = scene.scene_file_path
		return fallback_scene_key
	return fallback_scene_key

func _load_bookmarks() -> Dictionary:
	var path = _get_save_path()
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var result = JSON.parse_string(content)
		if typeof(result) == TYPE_DICTIONARY:
			return result
	return {}

func _save_bookmarks(data: Dictionary) -> void:
	var file = FileAccess.open(_get_save_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

func _save_current_bookmarks():
	var scene_key = _get_scene_key()
	var root = bookmark_tree.get_root()
	if not root:
		return

	var bookmarks = []
	var item = root.get_first_child()
	while item:
		var meta = item.get_metadata(0)
		if typeof(meta) == TYPE_DICTIONARY:
			bookmarks.append({
				"id": meta.get("id", ""),
				"path": meta.get("path", ""),
				"name": meta.get("name", "")
			})
		item = item.get_next()

	var data = _load_bookmarks()
	data[scene_key] = bookmarks
	_save_bookmarks(data)

func load_bookmarks_for_scene():
	bookmark_tree.clear()
	var root = bookmark_tree.create_item()
	root.set_text(0, "Bookmarks")

	var data = _load_bookmarks()
	var scene_key = _get_scene_key()

	if not data.has(scene_key):
		return

	var scene_root = get_tree().edited_scene_root
	if not scene_root:
		return

	for saved in data[scene_key]:
		if typeof(saved) != TYPE_DICTIONARY:
			continue

		var found_node: Node = null

		# Match by ID
		for node in scene_root.get_children():
			if node.has_meta("bookmark_id") and node.get_meta("bookmark_id") == saved["id"]:
				found_node = node
				break

		# Fallback to path
		if not found_node and scene_root.has_node(saved["path"]):
			found_node = scene_root.get_node(saved["path"])

		if found_node:
			add_bookmark(saved["name"], found_node.get_path(), true)
			
func _process(_delta):
	var scene_root = get_tree().edited_scene_root
	if not scene_root:
		return

	var root = bookmark_tree.get_root()
	if not root:
		return

	var item = root.get_first_child()
	while item:
		var meta = item.get_metadata(0)
		if typeof(meta) == TYPE_DICTIONARY:
			if meta.get("locked", false) == false:
				var path: NodePath = meta.get("path", "")
				var node = scene_root.get_node_or_null(path)
				if node and node.name != item.get_text(0):
					item.set_text(0, node.name)
					meta["name"] = node.name
					item.set_metadata(0, meta)
		item = item.get_next()


func _on_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var click_pos = event.position
		var clicked_item = bookmark_tree.get_item_at_position(click_pos)
		if clicked_item:
			clicked_item.select(0)
			context_menu.set_position(get_viewport().get_mouse_position())
			context_menu.popup()


func _on_context_menu_pressed(id: int) -> void:
	var selected = bookmark_tree.get_selected()
	if not selected:
		return

	match id:
		0:  # Rename
			_show_rename_dialog(selected)
		1:  # Remove
			selected.free()
			_save_current_bookmarks()

func _show_rename_dialog(item: TreeItem):
	pending_rename_item = item
	rename_input.text = item.get_text(0)
	rename_dialog.popup_centered()

func _on_rename_dialog_confirmed() -> void:
	if pending_rename_item == null:
		print("No pending item to rename.")
		return

	var new_name = rename_input.text.strip_edges()
	if new_name == "":
		print("Empty name entered, skipping.")
		return

	var meta = pending_rename_item.get_metadata(0)
	if typeof(meta) != TYPE_DICTIONARY:
		print("Invalid metadata on item.")
		return

	meta["name"] = new_name
	pending_rename_item.set_text(0, new_name)
	pending_rename_item.set_metadata(0, meta)
	print("Renamed to:", new_name)

	_save_current_bookmarks()
