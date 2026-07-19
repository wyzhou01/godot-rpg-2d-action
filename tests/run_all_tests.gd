extends SceneTree
## 备用主入口：直接调各 suite 的 .tscn
## 注意：SceneTree 限制，主入口是 run_all_tests.sh

const SUITES = [
	{"name": "scene_validation", "tscn": "res://tests/test_scene_validation.tscn"},
	{"name": "resources", "tscn": "res://tests/test_resources.tscn"},
	{"name": "dialogue", "tscn": "res://tests/test_dialogue.tscn"},
	{"name": "combat", "tscn": "res://tests/test_combat.tscn"},
	{"name": "save_system", "tscn": "res://tests/test_save_system.tscn"},
	{"name": "e2e_full_game", "tscn": "res://tests/test_e2e_full_game.tscn"},
]


func _init() -> void:
	print("\n" + "=".repeat(60))
	print("  ETERNALDUTY 自动化测试套件 (主入口)")
	print("=".repeat(60))
	print("\n注意：SceneTree 单进程限制。")
	print("请使用: bash tests/run_all_tests.sh\n")
	
	# 列出所有 suite
	for s in SUITES:
		var exists = "✓" if ResourceLoader.exists(s.tscn) else "✗"
		print("  %s %s → %s" % [exists, s.name, s.tscn])
	
	print("\n退出")
	quit(0)