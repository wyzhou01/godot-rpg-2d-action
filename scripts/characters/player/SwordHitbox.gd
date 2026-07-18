class_name SwordHitbox extends HitBox
## 玩家的剑攻击区域
## 挂在 HitboxPivot/SwordHitbox
##
## 关键设计:
##   - knockback_direction 由 Player 根据面向动态设置
##   - 默认 layer = 4 (PLAYER_ATTACK), mask = 4 (ENEMY_HURTBOX)

## 子类可以扩展：蓄力剑、特殊效果
