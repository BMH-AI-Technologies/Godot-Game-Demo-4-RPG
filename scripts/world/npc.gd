class_name TownNPC
extends GridEntity
## Có thể trò chuyện, mời vào đội hoặc nghỉ ngơi tùy dữ liệu trong Inspector.
@export_multiline var dialogue := ""
@export var companion: PartyMember
@export var offers_rest := false
