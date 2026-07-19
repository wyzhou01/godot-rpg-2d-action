#!/usr/bin/env python3
"""批量生成 Chapter 4-7 真关卡（基于 Chapter 1 模板）"""
import re
from pathlib import Path

# Boss 名称 → 资源 + TileSet
CHAPTER_CONFIG = {
    4: {"boss": "goldguard", "tileset": "chapter_4", "color": "Color(0.30, 0.25, 0.15, 1.0)", "enemy": "knight", "enemy2": "archer"},
    5: {"boss": "fireheart", "tileset": "chapter_5", "color": "Color(0.30, 0.18, 0.12, 1.0)", "enemy": "mage", "enemy2": "knight"},
    6: {"boss": "greendruid", "tileset": "chapter_6", "color": "Color(0.15, 0.25, 0.18, 1.0)", "enemy": "archer", "enemy2": "mage"},
    7: {"boss": "onyx", "tileset": "chapter_7", "color": "Color(0.05, 0.05, 0.07, 1.0)", "enemy": "knight", "enemy2": "mage"},
}

# 读 Ch1 模板
template = Path("scenes/levels/chapter_1/chapter_1_intro.tscn").read_text()

for ch_num, cfg in CHAPTER_CONFIG.items():
    text = template
    # 替换 Ch1 → ChN
    text = text.replace("Chapter1Playable", f"Chapter{ch_num}Playable")
    text = text.replace("chapter_1.gd", f"chapter_{ch_num}.gd")
    text = text.replace("greyr1.tscn", f"{cfg['boss']}.tscn")
    text = text.replace("chapter_1_tileset.tres", f"{cfg['tileset']}_tileset.tres")
    text = text.replace("Color(0.15, 0.22, 0.15, 1.0)", cfg["color"])
    text = text.replace("Knight1", cfg["enemy"].capitalize() + "1")
    text = text.replace("Knight2", cfg["enemy2"].capitalize() + "2")
    text = text.replace('knight.tscn', f'{cfg["enemy"]}.tscn', 1)  # 第一个
    # 写文件
    out = Path(f"scenes/levels/chapter_{ch_num}/chapter_{ch_num}_intro.tscn")
    out.write_text(text)
    print(f"✓ Chapter {ch_num} tscn")
    
    # 复制 Ch1.gd 模板
    gd_template = Path("scenes/levels/chapter_1/chapter_1.gd").read_text()
    gd_text = gd_template.replace("Greyr1", cfg["boss"].capitalize()).replace("Chapter 1", f"Chapter {ch_num}")
    gd_out = Path(f"scenes/levels/chapter_{ch_num}/chapter_{ch_num}.gd")
    gd_out.write_text(gd_text)
    print(f"✓ Chapter {ch_num} gd")

print("Done")