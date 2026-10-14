class_name RPGItem
extends Resource
## Lớp cha của mọi vật phẩm. File .tres lưu dữ liệu, không chứa trạng thái túi đồ.
@export var id := ""
@export var item_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
