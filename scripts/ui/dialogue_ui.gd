extends Control
## Hội thoại theo từng đoạn. Nút hành động chỉ hiện ở đoạn cuối.
signal closed
signal opened
signal page_advanced
signal action_requested
var pages: PackedStringArray = []
var page := 0
var action_text := ""

func _ready() -> void:
	%Next.pressed.connect(advance)
	%Action.pressed.connect(func(): action_requested.emit())

func open(title: String, text: String, action: String = "") -> void:
	%Speaker.text = title
	pages = text.split("\n", false)
	if pages.is_empty():
		pages.append("...")
	page = 0
	action_text = action
	show()
	render()
	opened.emit()

func render() -> void:
	%Message.text = pages[page]
	%Page.text = "%d / %d" % [page + 1, pages.size()]
	%Next.text = "Tiếp" if page < pages.size() - 1 else "Đóng"
	%Action.text = action_text
	%Action.visible = page == pages.size() - 1 and not action_text.is_empty()

func advance() -> void:
	if page < pages.size() - 1:
		page += 1
		render()
		page_advanced.emit()
	else:
		close()

func close() -> void:
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		advance()
	elif event.is_action_pressed("cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()
