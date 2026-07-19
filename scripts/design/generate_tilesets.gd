extends SceneTree

## 生成 7 章 TileSet 资源

func _init():
	make_tileset("chapter_1", "res://assets/environments/tiles/base/grass.png", 18, 18)
	make_tileset("chapter_2", "res://assets/environments/tiles/ice/snowMid.png", 18, 18)
	make_tileset("chapter_3", "res://assets/environments/tiles/base/dirt.png", 18, 18)
	make_tileset("chapter_4", "res://assets/environments/tiles/candy/cake.png", 18, 18)
	make_tileset("chapter_5", "res://assets/environments/tiles/base/liquidLava.png", 18, 18)
	make_tileset("chapter_6", "res://assets/environments/tiles/base/grass.png", 18, 18)
	make_tileset("chapter_7", "res://assets/environments/tiles/base/box.png", 18, 18)
	quit()


func make_tileset(chapter_name: String, source_tex: String, tile_w: int, tile_h: int) -> void:
	var png_path = "res://assets/environments/tiles/_" + chapter_name + "_tile.png"
	
	# 检查源图是否存在
	if not ResourceLoader.exists(source_tex):
		push_warning("Missing source: " + source_tex)
		return
	
	var tex: Texture2D = load(source_tex)
	var img: Image = tex.get_image()
	
	# 如果源图尺寸不等于 tile 尺寸，缩放到单 tile
	if img.get_width() != tile_w or img.get_height() != tile_h:
		img.resize(tile_w, tile_h)
	
	# 保存为单 tile PNG
	var save_result = img.save_png(png_path)
	if save_result != OK:
		push_warning("Failed save: " + png_path)
		return
	
	# 创建 TileSet
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_w, tile_h)
	
	var tile_set_atlas := TileSetAtlasSource.new()
	tile_set_atlas.texture = load(png_path)
	# TileSetAtlasSource 必须有 region
	var texture_size = tile_set_atlas.texture.get_size()
	tile_set_atlas.texture_region_size = Vector2i(tile_w, tile_h)
	tile_set_atlas.margins = Vector2i(0, 0)
	tile_set_atlas.separation = Vector2i(0, 0)
	tile_set_atlas.use_texture_padding = false
	
	tile_set.add_source(tile_set_atlas)
	
	var ts_path = "res://resources/tilesets/" + chapter_name + "_tileset.tres"
	ResourceSaver.save(tile_set, ts_path)
	print("[", ts_path, "] OK")