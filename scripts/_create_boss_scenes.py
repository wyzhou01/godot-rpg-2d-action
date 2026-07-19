import os

# Boss 颜色映射
BOSS_COLORS = {
    'Frost': (0.3, 0.5, 0.9),       # 蓝色 (冰)
    'Rotlord': (0.4, 0.15, 0.4),    # 暗紫 (死灵)
    'Goldguard': (1.0, 0.85, 0.3),  # 金色
    'Fireheart': (1.0, 0.3, 0.1),    # 火红
    'Greendruid': (0.2, 0.6, 0.3),   # 绿色
    'Onyx': (0.1, 0.05, 0.1),       # 暗紫黑
}

# Boss names (PascalCase)
BOSSSES = ['Frost', 'Rotlord', 'Goldguard', 'Fireheart', 'Greendruid', 'Onyx']

BASE_TEMPLATE = '''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/characters/bosses/{name}.gd" id="1_boss"]

[node name="{name}" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 1
script = ExtResource("1_boss")
boss_stats = ExtResource("RES_stats")

[node name="Sprite2D" type="ColorRect" parent="."]
custom_minimum_size = Vector2(40, 80)
offset_left = -20.0
offset_top = -80.0
offset_right = 20.0
offset_bottom = 0.0
color = Color({r}, {g}, {b}, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Boss_collision")

[sub_resource type="RectangleShape2D" id="Boss_collision"]
size = Vector2(40, 80)

[node name="Stats" type="Node" parent="."]
script = ExtResource("RES_stats_script")

[node name="HurtBox" type="Area2D" parent="."]
collision_layer = 32
collision_mask = 4
script = ExtResource("RES_hurtbox")

[node name="CollisionShape2D" type="CollisionShape2D" parent="HurtBox"]
shape = SubResource("Hurtbox_shape")

[sub_resource type="RectangleShape2D" id="Hurtbox_shape"]
size = Vector2(36, 76)

[node name="PlayerDetectionZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 1
script = ExtResource("RES_detection")

[node name="CollisionShape2D" type="CollisionShape2D" parent="PlayerDetectionZone"]
shape = SubResource("Detection_shape")

[sub_resource type="RectangleShape2D" id="Detection_shape"]
size = Vector2(1000, 500)

[node name="ProjectileSpawner" type="Node2D" parent="."]
position = Vector2(0, -60)

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]

[ext_resource type="Resource" path="res://resources/bosses/{name_lower}_stats.tres" id="RES_stats"]
[ext_resource type="Script" path="res://scripts/core/Stats.gd" id="RES_stats_script"]
[ext_resource type="Script" path="res://scripts/core/HurtBox.gd" id="RES_hurtbox"]
[ext_resource type="Script" path="res://scripts/core/PlayerDetectionZone.gd" id="RES_detection"]
'''

# 写 6 个 Boss 场景
scenes_dir = "scenes/characters/bosses"
os.makedirs(scenes_dir, exist_ok=True)

for name in BOSSSES:
    color = BOSS_COLORS[name]
    content = BASE_TEMPLATE.format(
        name=name,
        name_lower=name.lower(),
        r=color[0], g=color[1], b=color[2]
    )
    path = f"{scenes_dir}/{name.lower()}.tscn"
    with open(path, 'w') as f:
        f.write(content)
    print(f'✓ {path}')

print(f'\n=== Created {len(BOSSSES)} boss scenes ===')
