extends Control
## Scene này vẫn nhận input khi SceneTree bị pause.
signal closed
signal opened
signal reset_cancelled
signal reset_requested

func _ready() -> void:
	%Close.pressed.connect(close)
	%Volume.value_changed.connect(change_volume)
	%Mute.toggled.connect(change_mute)
	%DisplayMode.item_selected.connect(change_display_mode)
	%Resolution.item_selected.connect(change_resolution)
	%Reset.pressed.connect(func(): %Confirm.show())
	%CancelReset.pressed.connect(cancel_reset)
	%ConfirmReset.pressed.connect(func():
		Preferences.save_settings()
		reset_requested.emit())
	%DisplayMode.add_item("Cửa sổ")
	%DisplayMode.add_item("Toàn màn hình")
	for size in Preferences.RESOLUTIONS:
		%Resolution.add_item("%d × %d" % [size.x, size.y])

func open() -> void:
	%Confirm.hide()
	%Volume.set_value_no_signal(Preferences.volume * 100.0)
	%Mute.set_pressed_no_signal(Preferences.muted)
	%DisplayMode.select(1 if Preferences.fullscreen else 0)
	%Resolution.select(Preferences.resolution_index)
	refresh_labels()
	show()
	opened.emit()

func refresh_labels() -> void:
	%DisplayMode.select(1 if Preferences.fullscreen else 0)
	%Resolution.select(Preferences.resolution_index)
	%VolumeValue.text = "%d%%" % roundi(Preferences.volume * 100.0)
	%Resolution.disabled = Preferences.fullscreen
	%DisplayHint.text = "Thiết kế 1920 × 1080 • Tự khớp màn hình hiện tại." if Preferences.fullscreen else "Khung hình 16:9 • Chọn kích thước cửa sổ bên trên."

func change_volume(value: float) -> void:
	Preferences.volume = value / 100.0
	Preferences.apply_sound()
	refresh_labels()

func change_mute(value: bool) -> void:
	Preferences.muted = value
	Preferences.apply_sound()

func change_display_mode(index: int) -> void:
	Preferences.fullscreen = index == 1
	Preferences.apply_display()
	refresh_labels()

func change_resolution(index: int) -> void:
	Preferences.resolution_index = index
	Preferences.apply_display()
	refresh_labels()

func close() -> void:
	Preferences.save_settings()
	hide()
	closed.emit()

func cancel_reset() -> void:
	%Confirm.hide()
	reset_cancelled.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		if %Confirm.visible:
			cancel_reset()
		else:
			close()
		get_viewport().set_input_as_handled()
