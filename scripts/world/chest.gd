class_name LootChest
extends GridEntity
# Emitted by game.gd after loot is granted; connected to OpenSound in the scene.
@warning_ignore("unused_signal")
signal opened
@export var item: RPGItem
@export var amount := 1
