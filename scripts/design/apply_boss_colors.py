#!/usr/bin/env python3
"""
更新 Boss sprite 的 modulate 颜色
"""
import re
from pathlib import Path

# Boss modulate 颜色（用于 ColorRect 的 modulate 属性）
BOSS_MODULATE = {
    "Greyr1":      "Color(0.29, 0.29, 0.29, 1)",  # 灰
    "Frost":       "Color(0.35, 0.54, 0.80, 1)",  # 冰蓝
    "Rotlord":     "Color(0.29, 0.48, 0.23, 1)",  # 毒绿
    "Goldguard":   "Color(0.79, 0.65, 0.28, 1)",  # 暗金
    "Fireheart":   "Color(0.80, 0.40, 0.20, 1)",  # 橙红
    "Greendruid":  "Color(0.23, 0.80, 0.40, 1)",  # 翡翠
    "Onyx":        "Color(0.20, 0.10, 0.25, 1)",  # 紫色（黑曜+红眼）
}

# 同时更新 enemy modulate
ENEMY_MODULATE = {
    "Knight":  "Color(0.60, 0.50, 0.40, 1)",  # 棕铜
    "Archer":  "Color(0.40, 0.55, 0.40, 1)",  # 草绿
    "Mage":    "Color(0.40, 0.45, 0.70, 1)",  # 紫蓝
}


def update_boss_modulate(scene_path, boss_name):
    """更新 Boss Sprite2D modulate"""
    text = Path(scene_path).read_text()
    color = BOSS_MODULATE.get(boss_name)
    if not color:
        return False
    
    # Pattern: 在 BossName 节点下，Sprite2D 节点的 modulate
    pattern = rf'((\[node name="{boss_name}" type="CharacterBody2D"\][^\[]*?\[node name="Sprite2D" type="ColorRect" parent="\."\][^\[]*?modulate = ))Color\([^)]+\)'
    
    if re.search(pattern, text, re.DOTALL):
        text = re.sub(pattern, r'\1' + color, text, flags=re.DOTALL)
        Path(scene_path).write_text(text)
        return True
    return False


def update_enemy_modulate(scene_path, enemy_name):
    """更新 Enemy Sprite2D modulate"""
    text = Path(scene_path).read_text()
    color = ENEMY_MODULATE.get(enemy_name)
    if not color:
        return False
    
    # 通用 pattern：找 CharacterBody2D 下的 Sprite2D 的 modulate
    # 因为 enemy 节点名字 = scene filename
    pattern = rf'((\[node name="{enemy_name}" type="CharacterBody2D"\][^\[]*?\[node name="Sprite2D" type="ColorRect" parent="\."\][^\[]*?modulate = ))Color\([^)]+\)'
    
    if re.search(pattern, text, re.DOTALL):
        text = re.sub(pattern, r'\1' + color, text, flags=re.DOTALL)
        Path(scene_path).write_text(text)
        return True
    return False


def main():
    base = Path("scenes/characters")
    
    print("=== Boss modulate ===\n")
    for boss_name, color in BOSS_MODULATE.items():
        scene = base / "bosses" / f"{boss_name.lower()}.tscn"
        if scene.exists():
            if update_boss_modulate(str(scene), boss_name):
                print(f"✓ {boss_name}: modulate → {color}")
            else:
                print(f"⚠ {boss_name}: 没匹配")
    
    print("\n=== Enemy modulate ===\n")
    for enemy_name, color in ENEMY_MODULATE.items():
        scene = base / "enemies" / f"{enemy_name.lower()}.tscn"
        if scene.exists():
            if update_enemy_modulate(str(scene), enemy_name):
                print(f"✓ {enemy_name}: modulate → {color}")
            else:
                print(f"⚠ {enemy_name}: 没匹配")


if __name__ == "__main__":
    main()