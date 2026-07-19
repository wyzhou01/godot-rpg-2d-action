extends SceneTree

## 生成所有 SpriteFrames 资源（Godot 4 标准格式）

func _init():
	# Player SpriteFrames
	make_player_spriteframes()
	# Boss SpriteFrames
	make_boss_spriteframes()
	# Enemy SpriteFrames
	make_enemy_spriteframes()
	quit()


func make_spriteframes_from_pngs(animations: Dictionary, output_path: String) -> bool:
	var sf := SpriteFrames.new()
	for anim_name in animations:
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, true)
		sf.set_animation_speed(anim_name, 8.0)
		for png_path in animations[anim_name]:
			if not ResourceLoader.exists(png_path):
				push_warning("Missing: " + png_path)
				continue
			var tex := load(png_path)
			sf.add_frame(anim_name, tex)
	var result = ResourceSaver.save(sf, output_path)
	print("[", output_path, "] ", "OK" if result == OK else "FAIL")
	return result == OK


func make_player_spriteframes() -> void:
	var animations = {
		"idle": ["res://assets/characters/player/p1/p1_stand.png"],
		"walk": [
			"res://assets/characters/player/p1/p1_walk01.png",
			"res://assets/characters/player/p1/p1_walk02.png",
			"res://assets/characters/player/p1/p1_walk03.png",
			"res://assets/characters/player/p1/p1_walk04.png",
			"res://assets/characters/player/p1/p1_walk05.png",
			"res://assets/characters/player/p1/p1_walk06.png",
			"res://assets/characters/player/p1/p1_walk07.png",
			"res://assets/characters/player/p1/p1_walk08.png",
			"res://assets/characters/player/p1/p1_walk09.png",
			"res://assets/characters/player/p1/p1_walk10.png",
			"res://assets/characters/player/p1/p1_walk11.png",
		],
		"jump": ["res://assets/characters/player/p1/p1_jump.png"],
		"hurt": ["res://assets/characters/player/p1/p1_hurt.png"],
		"duck": ["res://assets/characters/player/p1/p1_duck.png"],
		"front": ["res://assets/characters/player/p1/p1_front.png"],
	}
	make_spriteframes_from_pngs(animations, "res://resources/player/player_sprite_frames.tres")


func make_boss_spriteframes() -> void:
	# 7 个 Boss：每个用 Kenney alien/enemy sprite 作占位（不同色 modulate 实现差异）
	# 简化：用同一个 sprite（enemies_spritesheet）但每个 Boss 配不同 sprite
	# 实际上 Kenney 没有 boss 精灵，我们用 enemy spritesheet 里的不同怪作 Boss 视觉
	
	# 策略：每个 Boss 用 knight_enemy sprite (绿皮) + 大尺寸
	# 或者：每个 Boss 用 enemy_spritesheet 里的一帧
	
	# 我们有 slimeWalk 系列（绿/蓝）
	# 简化方案：所有 Boss 用 enemies_spritesheet 单帧（视觉占位，Boss 仍由颜色区分）
	var boss_sprites = {
		"Greyr1": "res://assets/characters/enemies/slimeWalk1.png",
		"Frost": "res://assets/characters/enemies/slimeWalk2.png",
		"Rotlord": "res://assets/characters/enemies/slimeWalk3.png",
		"Goldguard": "res://assets/characters/enemies/blockerBody.png",
		"Fireheart": "res://assets/characters/enemies/flyFly1.png",
		"Greendruid": "res://assets/characters/enemies/snailWalk1.png",
		"Onyx": "res://assets/characters/enemies/snailShell_upsidedown.png",
	}
	for boss_name in boss_sprites:
		var sprite = boss_sprites[boss_name]
		var animations = {
			"idle": [sprite],
			"walk": [sprite],
			"attack": [sprite],
			"hurt": [sprite],
		}
		var path = "res://resources/bosses/" + boss_name.to_lower() + "_sprite_frames.tres"
		make_spriteframes_from_pngs(animations, path)


func make_enemy_spriteframes() -> void:
	# Knight, Archer, Mage 各自独立 sprite
	var enemy_sprites = {
		"knight": "res://assets/characters/enemies/slimeWalk1.png",  # 暂时复用 slime
		"archer": "res://assets/characters/enemies/blockerBody.png",
		"mage": "res://assets/characters/enemies/flyFly1.png",
	}
	for enemy_name in enemy_sprites:
		var sprite = enemy_sprites[enemy_name]
		var animations = {
			"idle": [sprite],
			"walk": [sprite],
			"attack": [sprite],
			"hurt": [sprite],
		}
		var path = "res://resources/enemies/" + enemy_name + "_sprite_frames.tres"
		make_spriteframes_from_pngs(animations, path)