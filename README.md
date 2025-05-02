# Node Bookmark Manager

**Node Bookmark Manager** is a lightweight Godot Editor plugin that allows you to bookmark nodes within your scene for fast access during development. Perfect for large or complex hierarchies.

## Features

-  Bookmark any selected node in the scene
-  Right-click to rename or remove bookmarks
-  Automatically reloads bookmarks when switching scenes
-  Remembers bookmarks per scene, saved in `user://`
-  Handles corrupted or missing save data with automatic recovery
-  Remembers user-defined names even if the node name changes
-  Click to instantly focus and select the bookmarked node

## Installation

1. Copy the `addons/node_bookmarker` folder into your project's `addons/` directory.
2. In Godot, go to `Project > Project Settings > Plugins`.
3. Enable **Node Bookmark Manager** from the list.

## Usage

- Open a scene and select any node.
- Click **"Add Selected Node"** in the plugin dock to bookmark it.
- Right-click a bookmark to rename or remove it.
- Click a bookmark to jump to and select that node in the editor.
- Bookmarks are saved per scene and persist across sessions.
- Use **"Reload Bookmarks"** if the list ever appears out of sync (normally unnecessary).

## License

This plugin is licensed under the MIT License. See the LICENSE file for details.
