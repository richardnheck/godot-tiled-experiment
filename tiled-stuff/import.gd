tool
extends Node
var scene

const default_meta = ["gid", "height", "width", "imageheight", "imagewidth", "path"]

func post_import(imported_scene):
	scene = imported_scene
	
	for child in scene.get_children():
		if child is TileMap:
			import_tilemap(child)
		elif child is Node2D:
			for object in child.get_children():
				spawn_object(object)
			child.free()
	
	return scene

func import_tilemap(tilemap):
	if tilemap.has_meta("group"):
		
		var group = tilemap.get_meta("group")
		
		tilemap.add_to_group(group, true)
		print("in group ", tilemap.is_in_group(group))

func spawn_object(object):
	if object.has_meta("path"):
		var path = object.get_meta("path")
		var node = load(path).instance()
		scene.add_child(node)
		node.set_owner(scene)
		node.position = object.position + Vector2(0,0)
		
		for meta in object.get_meta_list():
			if meta in default_meta:
				continue
			print(object.get_meta(meta))
			node.set(meta, object.get_meta(meta))
			
#		if object.name == "FireSpinner":
#			print(object.get_meta_list())
#			print(node)
#			node.length = 4
#			node.start_direction = 90
	else:
		object.get_parent().remove_child(object)
		scene.add_child(object)
		object.set_owner(scene)

func set_properties(object, node):
	for meta in object.get_meta_list():
		if meta in default_meta:
			continue
		node.set(meta, object.get_meta(meta))
