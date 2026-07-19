#!/usr/bin/env python3
"""
升级 chapter_X.gd：
- 加 show_intro_dialog / intro_dialog_path 字段
- _ready() 中先播放 intro 对话
"""
import re
from pathlib import Path


def upgrade_chapter_gd(chapter_num: int):
    path = Path(f"scenes/levels/chapter_{chapter_num}/chapter_{chapter_num}.gd")
    if not path.exists():
        return False
    
    text = path.read_text()
    
    # 替换 header 区（无论原文如何，都强制替换为新格式）
    new_header = f'''extends Node2D
## Chapter {chapter_num} 关卡控制

@export var next_scene: String = "res://scenes/levels/chapter_{chapter_num}/chapter_{chapter_num}_combat.tscn"
@export var chapter_name: String = "Chapter {chapter_num}"
@export var show_intro_dialog: bool = true
@export var intro_dialog_path: String = "res://dialogs/chapter_{chapter_num}_intro.json"
'''
    
    # 找到第一个 @export var player 行，在它前面插入新 header
    # 或者简单地：替换文件开头到 @export var next_scene ... 整段
    pattern = r'extends Node2D.*?@export var chapter_name: String = "Chapter[^"]+"'
    
    if re.search(pattern, text, re.DOTALL):
        text = re.sub(pattern, new_header.rstrip(), text, count=1, flags=re.DOTALL)
    else:
        # 没匹配上：在文件开头插入
        text = new_header + text
    
    # 在 _ready 函数开头插入对话播放逻辑（避免重复插入）
    if "show_intro_dialog and intro_dialog_path" not in text:
        ready_pattern = r'(func _ready\(\) -> void:\n)(\s*)([^\s])'
        
        def add_dialog_call(match):
            indent = match.group(2)
            first_char = match.group(3)
            dialog_block = f'''{indent}# 显示章节 intro 对话
{indent}if show_intro_dialog and intro_dialog_path and DialogueHelper:
{indent}{indent}DialogueHelper.dialogue_ended.connect(_on_intro_dialog_ended, CONNECT_ONE_SHOT)
{indent}{indent}DialogueHelper.show(intro_dialog_path)
{indent}{indent}await DialogueHelper.dialogue_ended
{indent}{first_char}'''
            return match.group(1) + dialog_block
        
        text = re.sub(ready_pattern, add_dialog_call, text, count=1, flags=re.DOTALL)
    
    # 添加 _on_intro_dialog_ended 处理函数（避免重复）
    if "_on_intro_dialog_ended" not in text:
        text += '''

func _on_intro_dialog_ended(_timeline: String) -> void:
	# intro 对话结束，玩家可以移动
	pass
'''
    
    path.write_text(text)
    return True


def main():
    for ch in range(1, 8):
        if upgrade_chapter_gd(ch):
            print(f"✓ Chapter {ch}")
        else:
            print(f"⚠ Chapter {ch}")


if __name__ == "__main__":
    main()