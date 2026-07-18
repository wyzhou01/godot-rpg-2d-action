#!/usr/bin/env python3
"""
EternalDuty 静态检查脚本 (无需 Godot 引擎)
- .gd 脚本基本语法检查
- .tres 资源引用完整性
- scene 引用完整性

用法: python3 scripts/static_check.py
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
ERRORS = []
WARNINGS = []


def check_chinese_filename():
    print("\n[1] 检查中文文件名...")
    chinese = []
    for item in ROOT.iterdir():
        if item.is_file():
            if any(0x4E00 <= ord(c) <= 0x9FFF for c in item.name):
                chinese.append(item.name)
    if chinese:
        WARNINGS.append(f"根目录有 {len(chinese)} 个中文文件名: {chinese[:3]}")
        print(f"  ⚠️ {len(chinese)} 个")
    else:
        print("  ✅ 干净")


def check_gdscript_syntax():
    print("\n[2] GDScript 基础语法检查...")
    issues = []
    for root, dirs, files in os.walk(ROOT / "scripts"):
        if "/.git/" in root or "/addons/" in root:
            continue
        for f in files:
            if not f.endswith(".gd"):
                continue
            path = Path(root) / f
            with open(path) as fh:
                content = fh.read()
            # 检查括号匹配
            if content.count('(') != content.count(')'):
                issues.append(f"{path}: paren mismatch")
            if content.count('{') != content.count('}'):
                issues.append(f"{path}: brace mismatch")
            if content.count('[') != content.count(']'):
                issues.append(f"{path}: bracket mismatch")
            # 检查 indentation
            for i, line in enumerate(content.split('\n'), 1):
                if '\t' in line and '    ' in line.lstrip():
                    issues.append(f"{path}:{i}: mixed indent")
                    break  # 只报告第一个
    if issues:
        for i in issues[:10]:
            print(f"  ⚠️ {i}")
        WARNINGS.append(f"{len(issues)} 个语法/格式问题")
    else:
        print("  ✅ 通过")


def check_tres_references():
    print("\n[3] .tres 资源引用完整性...")
    issues = []
    for tres in ROOT.rglob("*.tres"):
        if "/.git/" in str(tres) or "/.godot/" in str(tres) or "/addons/" in str(tres):
            continue
        try:
            content = tres.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        # 找出所有 ext_resource path
        for ref in re.findall(r'path="(res://[^"]+\.gd)"', content):
            local = ROOT / ref.replace("res://", "")
            if not local.exists():
                issues.append(f"{tres.name}: {ref}")
    if issues:
        for i in issues[:10]:
            print(f"  ⚠️ {i}")
        WARNINGS.append(f"{len(issues)} 个失效引用")
    else:
        print("  ✅ 通过")


def check_class_name_uniqueness():
    print("\n[4] class_name 唯一性...")
    classes = {}
    issues = []
    for root, dirs, files in os.walk(ROOT / "scripts"):
        if "/.git/" in root or "/addons/" in root:
            continue
        for f in files:
            if not f.endswith(".gd"):
                continue
            path = Path(root) / f
            try:
                content = path.read_text()
            except UnicodeDecodeError:
                continue
            m = re.search(r'^class_name\s+(\w+)', content, re.MULTILINE)
            if m:
                name = m.group(1)
                if name in classes:
                    issues.append(f"DUPLICATE: {name} in {path.relative_to(ROOT)} and {classes[name].relative_to(ROOT)}")
                else:
                    classes[name] = path
    if issues:
        for i in issues:
            ERRORS.append(i)
            print(f"  ❌ {i}")
    else:
        print(f"  ✅ {len(classes)} 个唯一 class_name")


def check_project_godot():
    print("\n[5] project.godot 完整性...")
    pg = ROOT / "project.godot"
    if not pg.exists():
        print("  ❌ project.godot 不存在")
        ERRORS.append("project.godot missing")
        return
    content = pg.read_text()
    # autoload 路径
    for m in re.finditer(r'^\w+="\*?(res://[^"]+)"', content, re.MULTILINE):
        path = m.group(1).replace("res://", "")
        full = ROOT / path
        if not full.exists():
            ERRORS.append(f"autoload/plugin path missing: {path}")
            print(f"  ❌ {path}")
    if not [e for e in ERRORS if "autoload" in e]:
        print("  ✅ 所有 autoload/plugin 路径有效")


def main():
    print(f"=" * 50)
    print(f"EternalDuty 静态检查 - {ROOT.name}")
    print(f"=" * 50)

    check_chinese_filename()
    check_gdscript_syntax()
    check_tres_references()
    check_class_name_uniqueness()
    check_project_godot()

    print(f"\n{'=' * 50}")
    print(f"汇总: {len(ERRORS)} 错误, {len(WARNINGS)} 警告")
    print(f"{'=' * 50}")
    if ERRORS:
        print("\n❌ 错误:")
        for e in ERRORS:
            print(f"  - {e}")
        sys.exit(1)
    if WARNINGS:
        print("\n⚠️ 警告:")
        for w in WARNINGS:
            print(f"  - {w}")
    print("\n✅ 通过")


if __name__ == "__main__":
    main()
