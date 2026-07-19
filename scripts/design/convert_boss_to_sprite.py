#!/usr/bin/env python3
"""把 Boss .tscn 的 Sprite2D ColorRect 替换为 AnimatedSprite2D"""
import re
from pathlib import Path

# Boss 视觉 modulate（保留颜色感）
BOSS_MODULATE = {
    "greyr1":     "Color(0.8, 0.8, 0.85, 1)",   # 银灰
    "frost":      "Color(0.6, 0.85, 1.0, 1)",   # 冰蓝
    "rotlord":    "Color(0.6, 0.85, 0.5, 1)",   # 毒绿
    "goldguard":  "Color(1.0, 0.85, 0.4, 1)",   # 暗金
    "fireheart":  "Color(1.0, 0.55, 0.3, 1)",   # 橙红
    "greendruid": "Color(0.4, 1.0, 0.6, 1)",    # 翡翠
    "onyx":       "Color(0.4, 0.2, 0.5, 1)",    # 紫
}


def replace_boss_sprite(scene_path: Path, boss_name: str):
    text = scene_path.read_text()
    
    # 添加 ext_resource for SpriteFrames
    sf_id = "10_spriteframes"
    sf_path = f"res://resources/bosses/{boss_name}_sprite_frames.tres"
    
    if sf_id not in text:
        # 找到第一个 [node name="..."] 之前插入 ext_resource
        pattern = r'(\[ext_resource[^\]]+\]\n)(\n\[node )'
        text = re.sub(pattern, r'\1[ext_resource type="SpriteFrames" path="' + sf_path + f'" id="{sf_id}"]\n\2', text, count=1)
    
    # 替换 Sprite2D ColorRect 块为 AnimatedSprite2D
    sprite_pattern = r'\[node name="Sprite2D" type="ColorRect" parent="\."\][^\[]*?(?=\[node |\Z)'
    
    modulate = BOSS_MODULATE[boss_name]
    new_sprite = f'''[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
position = Vector2(0, -80)
scale = Vector2(2.5, 2.5)
sprite_frames = ExtResource("{sf_id}")
animation = &"idle"
autoplay = "idle"
modulate = {modulate}

'''
    
    text = re.sub(sprite_pattern, new_sprite, text, count=1, flags=re.DOTALL)
    
    scene_path.write_text(text)


def main():
    base = Path("scenes/characters/bosses")
    for boss_file in sorted(base.glob("*.tscn")):
        if " 2." in boss_file.name:
            continue
        boss_name = boss_file.stem
        replace_boss_sprite(boss_file, boss_name)
        print(f"✓ {boss_file.name}")


if __name__ == "__main__":
    main()