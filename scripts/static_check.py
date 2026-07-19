#!/usr/bin/env python3
"""
EternalDuty 静态检查脚本 (无需 Godot 引擎)
- 检测所有静态可发现的 parse error
- 检测 Godot 3 → 4 API 残留
- 检测 autoload / class_name 冲突
- 检测 setget / export / extends 错误

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
    """检查根目录是否有中文文件名"""
    print("\n[1] 检查中文文件名...")
    chinese = []
    for item in ROOT.iterdir():
        if item.is_file():
            if any(0x4E00 <= ord(c) <= 0x9FFF for c in item.name):
                chinese.append(item.name)
    if chinese:
        WARNINGS.append(f"根目录有 {len(chinese)} 个中文文件名: {chinese[:3]}")
        print(f"  ⚠️  {len(chinese)} 个: {chinese[:3]}")
    else:
        print("  ✅ 干净")


def check_autoload_classname_conflict():
    """检查 autoload 和 class_name 冲突（关键 parse error 来源）"""
    print("\n[2] 检查 autoload + class_name 冲突...")
    pg = ROOT / "project.godot"
    if not pg.exists():
        return
    content = pg.read_text()
    m = re.search(r'\[autoload\](.*?)\n\[', content, re.DOTALL)
    if not m:
        return
    autoloads = re.findall(r'(\w+)="\*?(res://[^"]+)"', m.group(1))
    for name, path in autoloads:
        local = path.replace("res://", "")
        full = ROOT / local
        if not full.exists():
            continue
        with open(full) as f:
            c = f.read()
        cm = re.search(r'^class_name\s+(\w+)', c, re.MULTILINE)
        if cm and cm.group(1) == name:
            ERRORS.append(f"❌ {path}: class_name '{cm.group(1)}' 隐藏了 autoload '{name}'")
            print(f"  ❌ {name}: class_name 冲突")
        else:
            print(f"  ✅ {name}")


def check_first_line_valid():
    """检查所有 .gd 脚本第一行是有效的 Godot 4 语句"""
    print("\n[3] 检查脚本起始语句...")
    valid_starts = ('extends ', 'class_name ', '@onready', '@export', 'const ',
                    'var ', 'func ', 'enum ', 'signal ', 'static ', '@tool')
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
            for line in content.split('\n'):
                s = line.strip()
                if not s or s.startswith('#') or s.startswith('@tool'):
                    continue
                if not s.startswith(valid_starts):
                    ERRORS.append(f"❌ {path}: 首行 '{s[:60]}' 不是有效 Godot 4 起始语句")
                break
    print(f"  检查 {sum(1 for r, d, fs in os.walk(ROOT / 'scripts') for f in fs if f.endswith('.gd'))} 个脚本")


def check_gdscript_godot3_api():
    """检查 Godot 3 API 残留（setter / API 改名）"""
    print("\n[4] 检查 Godot 3 → 4 API 残留...")
    patterns = [
        (r'^\s*tool\s*$', "@tool 应该是 @tool 注解"),
        (r'connect\(\s*["\'][a-z_]+["\']\s*,\s*self\s*,\s*["\'][a-z_]+["\']', "旧式 connect('sig', self, 'method')"),
        (r'connect\(\s*["\'][a-z_]+["\']\s*,\s*self\s*,\s*["\'][a-z_]+["\']\s*,', "旧式 connect 4-arg"),
        (r'disconnect\(\s*["\'][a-z_]+["\']\s*,\s*self\s*,', "旧式 disconnect"),
        (r'is_connected\(\s*["\'][a-z_]+["\']\s*,\s*self\s*,', "旧式 is_connected"),
        (r'\bFile\.new\(\)', "File.new() (Godot 3)"),
        (r'f\.open\([^)]*File\.READ\s*\)', "f.open with File.READ"),
        (r'\bOS\.clipboard\s*=', "OS.clipboard = (Godot 3)"),
        (r'\bget_position_in_parent\(\)', "get_position_in_parent() → get_index()"),
        (r'\bTYPE_REAL\b', "TYPE_REAL → TYPE_FLOAT"),
        (r'property_list_changed_notify\(\)', "property_list_changed_notify() → notify_property_list_changed()"),
        (r'\.update_configuration_warning\(\)', "update_configuration_warning() → update_configuration_warnings()"),
        (r'\.empty\(\)', ".empty() → .is_empty()"),
        (r'^\s*export\s*\(', "export() → @export()"),
        (r'^\s*export\s+[A-Z]', "export keyword → @export"),
        (r'\ssetget\s+', "setget → : set = / : get ="),
        (r'^class_name\s+\w+\s*,\s*"', "Godot 3 class_name X, 'icon' → @icon() + class_name X extends Y"),
    ]
    count = 0
    for root, dirs, files in os.walk(ROOT):
        if "/.git/" in root or "/.godot/" in root or "/addons/" in root:
            continue
        for f in files:
            if not f.endswith(".gd"):
                continue
            path = Path(root) / f
            try:
                content = path.read_text()
            except UnicodeDecodeError:
                continue
            for i, line in enumerate(content.split('\n'), 1):
                for pat, desc in patterns:
                    if re.search(pat, line):
                        ERRORS.append(f"❌ {path}:{i} {desc}")
                        count += 1
                        break  # 一行只报一次
    if count:
        print(f"  ❌ {count} 个 Godot 3 API 残留")
    else:
        print(f"  ✅ 干净")


def check_setter_deadloop():
    """检查 setter 中是否给 self 同名变量赋值（死循环）"""
    print("\n[5] 检查 setter 死循环...")
    count = 0
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
            # 找 var X: type: set/get 形式，提取 var name
            in_setter = False
            var_name = ""
            for line in content.split('\n'):
                stripped = line.strip()
                # 找 var 声明带 set
                m = re.match(r'^var\s+(\w+)\s*:.*\bset\b', stripped)
                if m:
                    var_name = m.group(1)
                    in_setter = True
                    continue
                if in_setter:
                    # 检测 set/get/set =/get = 出现 → 结束 setter
                    if re.search(r'^\s*(set|get)\s*=', stripped) or stripped == '':
                        if 'set =' in stripped or 'get =' in stripped:
                            # 这还是 setter 配置
                            if '=' in stripped and not (stripped.startswith('set =') or stripped.startswith('get =')):
                                in_setter = False
                        continue
                    # setter 结束: 遇到空行或非缩进行
                    if not line.startswith('\t') and not line.startswith('    '):
                        in_setter = False
                        continue
                    # 检查赋值同名
                    if var_name and re.search(rf'\b{re.escape(var_name)}\s*=\s*[^=]', stripped):
                        # 排除 _backing 这种带下划线前缀的合法模式
                        if not var_name.startswith('_'):
                            ERRORS.append(f"❌ {path}: setter 可能赋给同名变量 '{var_name}' (死循环)")
                            count += 1
                    # 真正的 setter 体结束
                    if not stripped.startswith('#') and stripped and ':' not in stripped and 'set' not in stripped and 'get' not in stripped:
                        in_setter = False
    if count:
        print(f"  ❌ {count} 处可能死循环")
    else:
        print(f"  ✅ 干净")


def check_tscn_references():
    """验证所有 .tscn 的 ext_resource 引用都指向存在的文件"""
    print("\n[6] 检查 .tscn 引用完整性...")
    issues = []
    for tscn in ROOT.rglob("*.tscn"):
        if "/.git/" in str(tscn) or "/.godot/" in str(tscn):
            continue
        try:
            content = tscn.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for ref in re.findall(r'path="(res://[^"]+)"', content):
            local = ROOT / ref.replace("res://", "")
            if not local.exists():
                issues.append(f"{tscn.name}: {ref}")
    if issues:
        for i in issues[:10]:
            ERRORS.append(f"❌ {i}")
        print(f"  ❌ {len(issues)} 个失效引用")
        for i in issues[:5]:
            print(f"     {i}")
    else:
        print("  ✅ 全部有效")


def check_classname_uniqueness():
    """检查所有 class_name 全局唯一"""
    print("\n[7] 检查 class_name 唯一性...")
    classes = {}
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
                    ERRORS.append(f"❌ class_name '{name}' 重复: {path.relative_to(ROOT)} 和 {classes[name].relative_to(ROOT)}")
                else:
                    classes[name] = path
    print(f"  ✅ {len(classes)} 个唯一 class_name" if len(classes) == len(set(classes)) else f"  ❌ {len(classes) - len(set(classes))} 个冲突")


def check_project_godot():
    """检查 project.godot 完整性"""
    print("\n[8] 检查 project.godot 完整性...")
    pg = ROOT / "project.godot"
    if not pg.exists():
        ERRORS.append("❌ project.godot 不存在")
        return
    content = pg.read_text()
    # autoload 路径
    m = re.search(r'\[autoload\](.*?)\n\[', content, re.DOTALL)
    if m:
        for autoload in re.finditer(r'\w+="\*?(res://[^"]+)"', m.group(1)):
            path = autoload.group(1).replace("res://", "")
            if not (ROOT / path).exists():
                ERRORS.append(f"❌ autoload 路径失效: {path}")
    # editor_plugin 路径
    m = re.search(r'\[editor_plugins\](.*?)\n\[', content, re.DOTALL)
    if m:
        for plugin in re.finditer(r'"(res://[^"]+plugin\.cfg)"', m.group(1)):
            path = plugin.group(1).replace("res://", "")
            if not (ROOT / path).exists():
                ERRORS.append(f"❌ plugin 路径失效: {path}")
    print(f"  ✅ 验证完成")


def main():
    print(f"=" * 50)
    print(f"EternalDuty 静态检查 v2 - {ROOT.name}")
    print(f"=" * 50)

    check_chinese_filename()
    check_autoload_classname_conflict()
    check_first_line_valid()
    check_gdscript_godot3_api()
    check_setter_deadloop()
    check_tscn_references()
    check_classname_uniqueness()
    check_project_godot()

    print(f"\n{'=' * 50}")
    print(f"汇总: {len(ERRORS)} 错误, {len(WARNINGS)} 警告")
    print(f"{'=' * 50}")
    if ERRORS:
        print("\n❌ 错误列表:")
        for e in ERRORS[:20]:
            print(f"  {e}")
        sys.exit(1)
    if WARNINGS:
        print("\n⚠️  警告列表:")
        for w in WARNINGS:
            print(f"  {w}")
    print("\n✅ 通过")


if __name__ == "__main__":
    main()
