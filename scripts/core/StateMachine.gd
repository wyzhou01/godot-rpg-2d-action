class_name StateMachine extends Node
## enum-based 状态机基类
## 用法: 子类继承，定义 enum + 状态逻辑
##
## 关键设计: 替代一堆 bool 标志（is_attacking/is_dodging/is_dead）
##   - 状态可枚举、清晰
##   - 切换显式（state_change("Run")）
##   - 进入/退出/更新回调

signal state_changed(from_state, to_state)

var current_state: StringName = &"":
	set(value):
		if value == current_state:
			return
		var prev = current_state
		current_state = value
		if prev != &"":
			_on_exit_state(prev)
		_on_enter_state(value)
		state_changed.emit(prev, value)


func _physics_process(delta: float) -> void:
	if current_state != &"":
		_on_update_state(current_state, delta)


## 子类必须重写
func _on_enter_state(state: StringName) -> void:
	pass


func _on_exit_state(state: StringName) -> void:
	pass


func _on_update_state(state: StringName, _delta: float) -> void:
	pass


## 主动切换状态
func state_change(new_state: StringName) -> void:
	current_state = new_state


## 查询是否在某个状态
func is_in_state(state: StringName) -> bool:
	return current_state == state
