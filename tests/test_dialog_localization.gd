extends Node
## V2.5 — 对话本地化修真测试
##
## 修真: 21 个对话 JSON 文件 修真修真修真修真修真修真修真修真修真修真修真
## 修真: 中文字符完整 / 每行非空 / 修真修真修真修真修真修真修真修真修真修真
## 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真

const TestFramework = preload("res://tests/test_framework.gd")

# 修真字符范围: 中文/日文/韩文 修真
const CJK_PATTERN := "[一-鿿　-〿぀-ゟ゠-ヿ㐀-䶿가-힯]"
# 修真修真修真修真修真修真修真修真修真修真修真修真修真修真
const LOREM_IPSUM := "lorem ipsum dolor sit amet"

var _tf: TestFramework


func _ready() -> void:
	_tf = TestFramework.new()
	add_child(_tf)
	call_deferred("_start_tests")


func _start_tests() -> void:
	await _run_all()


func _run_all() -> void:
	_tf.start_suite("dialog_localization")

	var dir: DirAccess = DirAccess.open("res://dialogs/")
	if dir == null:
		_tf.run_test("dialog 修真", func() -> Dictionary:
			return {"pass": false, "message": "dialogs/ 修真"})
		_finish()
		return

	var json_files: PackedStringArray = _collect_json_files("res://dialogs/")
	var total: int = json_files.size()
	var no_cjk: Array = []
	var empty_lines_count: Array = []
	var lorem_count: Array = []
	var all_cjk_count: int = 0

	for path in json_files:
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var text: String = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if not json is Dictionary or not json.has("lines"):
			continue
		var lines: Array = json["lines"]
		var file_has_cjk: bool = false
		for line in lines:
			if not line is Dictionary:
				continue
			var line_text: String = line.get("text", "")
			if line_text.is_empty():
				empty_lines_count.append(path)
				break
			if LOREM_IPSUM in line_text.to_lower():
				lorem_count.append(path)
				break
			var regex := RegEx.new()
			regex.compile(CJK_PATTERN)
			if regex.search(line_text):
				file_has_cjk = true
		if file_has_cjk:
			all_cjk_count += 1
		else:
			no_cjk.append(path.get_file())

	# 修真: 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真
	var cjk_passed: bool = all_cjk_count >= 21  # 21 个对话都修真
	var no_empty: bool = empty_lines_count.is_empty()
	var no_lorem: bool = lorem_count.is_empty()

	_tf.run_test("21 个对话全含中文", func() -> Dictionary:
		return {"pass": cjk_passed, "message": "%d/21 含中文 (缺: %s)" % [all_cjk_count, str(no_cjk.slice(0, 5))]})
	var msg1: String = ""
	if no_empty:
		msg1 = "空行文件=%d" % empty_lines_count.size()
	else:
		msg1 = "FAIL: %s" % str(empty_lines_count.slice(0, 3))
	_tf.run_test("对话无空行", func() -> Dictionary:
		return {"pass": no_empty, "message": msg1})
	var msg2: String = ""
	if no_lorem:
		msg2 = "lorem 文件=%d" % lorem_count.size()
	else:
		msg2 = "FAIL: %s" % str(lorem_count.slice(0, 3))
	_tf.run_test("对话无 Lorem Ipsum 占位", func() -> Dictionary:
		return {"pass": no_lorem, "message": msg2})

	_finish()


func _finish() -> void:
	_tf.end_suite()
	_tf.print_summary()
	_tf.exit_with_result()


func _collect_json_files(dir_path: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var full_path: String = dir_path + name
		if dir.current_is_dir():
			var sub: PackedStringArray = _collect_json_files(full_path + "/")
			for s in sub:
				result.append(s)
		elif name.ends_with(".json"):
			result.append(full_path)
		name = dir.get_next()
	dir.list_dir_end()
	return result