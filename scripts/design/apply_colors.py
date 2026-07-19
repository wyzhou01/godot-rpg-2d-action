#!/usr/bin/env python3
"""
按设计文档统一应用 7 章配色
- intro: 深色叙事色调
- combat: 中度游戏色调
- boss: 强烈压迫色调
"""
import re
from pathlib import Path

# 配色表（R, G, B, A）— 0-1 范围
THEMES = {
    1: {  # 圣剑骑士团旧址 — 枯草绿
        "intro":  (0.18, 0.22, 0.18, 1.0),
        "combat": (0.22, 0.28, 0.22, 1.0),
        "boss":   (0.15, 0.18, 0.15, 1.0),
    },
    2: {  # 雪山修道院 — 冰蓝灰
        "intro":  (0.20, 0.25, 0.32, 1.0),
        "combat": (0.25, 0.30, 0.38, 1.0),
        "boss":   (0.18, 0.22, 0.30, 1.0),
    },
    3: {  # 腐木森林 — 毒绿+棕
        "intro":  (0.20, 0.25, 0.15, 1.0),
        "combat": (0.25, 0.32, 0.18, 1.0),
        "boss":   (0.18, 0.22, 0.12, 1.0),
    },
    4: {  # 黄金圣殿 — 暗金
        "intro":  (0.28, 0.24, 0.15, 1.0),
        "combat": (0.35, 0.30, 0.18, 1.0),
        "boss":   (0.30, 0.25, 0.12, 1.0),
    },
    5: {  # 烈焰之心 — 暗红橙
        "intro":  (0.30, 0.18, 0.12, 1.0),
        "combat": (0.35, 0.20, 0.12, 1.0),
        "boss":   (0.40, 0.15, 0.10, 1.0),
    },
    6: {  # 翡翠德鲁伊圣地 — 翡翠绿
        "intro":  (0.15, 0.25, 0.18, 1.0),
        "combat": (0.18, 0.32, 0.22, 1.0),
        "boss":   (0.12, 0.28, 0.18, 1.0),
    },
    7: {  # 黑曜石王座 — 接近纯黑
        "intro":  (0.05, 0.05, 0.07, 1.0),
        "combat": (0.06, 0.06, 0.08, 1.0),
        "boss":   (0.04, 0.04, 0.06, 1.0),
    },
}

# Boss 视觉配色（与场景分离）
BOSS_COLORS = {
    "Greyr1":      (0.29, 0.29, 0.29, 1.0),  # 灰
    "Frost":       (0.35, 0.54, 0.80, 1.0),  # 冰蓝
    "Rotlord":     (0.29, 0.48, 0.23, 1.0),  # 毒绿
    "Goldguard":   (0.79, 0.65, 0.28, 1.0),  # 暗金
    "Fireheart":   (0.80, 0.40, 0.20, 1.0),  # 橙红
    "Greendruid":  (0.23, 0.80, 0.40, 1.0),  # 翡翠
    "Onyx":        (0.04, 0.04, 0.06, 1.0),  # 纯黑
}

GROUND_COLOR = (0.30, 0.30, 0.35, 1.0)  # 通用灰色地面
PLAYER_COLOR = (0.80, 0.80, 0.85, 1.0)  # 银白


def color_str(c):
    return f"Color({c[0]}, {c[1]}, {c[2]}, {c[3]})"


def update_scene_bg(scene_path, color):
    """更新场景的 Background ColorRect"""
    text = Path(scene_path).read_text()
    # 匹配 Background ColorRect 的 color = Color(...)
    pattern = r'(\[node name="Background" type="ColorRect" parent="\."\][^\[]*?color = )Color\([^)]+\)'
    new = color_str(color)
    if re.search(pattern, text, re.DOTALL):
        text = re.sub(pattern, r'\1' + new, text, flags=re.DOTALL)
        Path(scene_path).write_text(text)
        return True
    return False


def update_ground(scene_path, color):
    """更新地面 StaticBody 的视觉（如果有 ColorRect child）"""
    text = Path(scene_path).read_text()
    # Ground 节点下可能有 ColorRect 或类似 visual
    # 直接添加一个 VisualColorRect（如果没有）
    return False  # 暂不自动改


def update_boss_sprite_color(scene_path, boss_name):
    """更新 Boss sprite ColorRect 颜色"""
    if boss_name not in BOSS_COLORS:
        return False
    text = Path(scene_path).read_text()
    # Boss node 下第一个 ColorRect（通常是 Sprite2D 占位）
    # Pattern: [node name="X" type="ColorRect" parent="Boss"]
    # 改为 boss 名字匹配
    color = color_str(BOSS_COLORS[boss_name])
    
    # 找 Boss 节点的 ColorRect
    # Pattern: 在 [node name="BossName" type="CharacterBody2D"] 下，[node name="Sprite2D" type="ColorRect" parent="."]
    # 这种结构实际是 sprite = ColorRect with color = ...
    pattern = rf'((\[node name="{boss_name}" type="CharacterBody2D"\][^\[]*?\[node name="Sprite2D" type="ColorRect" parent="\."\][^\[]*?color = ))Color\([^)]+\)'
    
    if re.search(pattern, text, re.DOTALL):
        text = re.sub(pattern, r'\1' + color, text, flags=re.DOTALL)
        Path(scene_path).write_text(text)
        return True
    return False


def main():
    base = Path("scenes/levels")
    print("=== 应用 7 章配色 ===\n")
    
    for ch in range(1, 8):
        for kind in ["intro", "combat", "boss"]:
            scene = base / f"chapter_{ch}" / f"chapter_{ch}_{kind}.tscn"
            if scene.exists():
                color = THEMES[ch][kind]
                if update_scene_bg(scene, color):
                    print(f"✓ {scene.name}: bg → {color}")
                else:
                    print(f"⚠ {scene.name}: 没找到 Background 节点")
    
    print("\n=== 应用 Boss 配色 ===\n")
    
    boss_scenes = {
        1: "Greyr1",
        2: "Frost",
        3: "Rotlord",
        4: "Goldguard",
        5: "Fireheart",
        6: "Greendruid",
        7: "Onyx",
    }
    
    for ch, boss_name in boss_scenes.items():
        scene = base / f"chapter_{ch}" / f"chapter_{ch}_boss.tscn"
        if scene.exists():
            if update_boss_sprite_color(scene, boss_name):
                print(f"✓ Ch{ch} {boss_name}: sprite color")
            else:
                print(f"⚠ Ch{ch} {boss_name}: 没找到 Sprite2D ColorRect")
    
    print("\n=== 完成 ===")


if __name__ == "__main__":
    main()