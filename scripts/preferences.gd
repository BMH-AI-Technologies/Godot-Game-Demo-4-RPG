extends Node
## Cài đặt riêng với tiến trình chơi. Reset cuộc phiêu lưu không xóa cài đặt.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1280, 720),
	Vector2i(1600, 900), Vector2i(1920, 1080)]
const DISPLAY_VERSION := 2
var volume := 0.80
var muted := false
var fullscreen := true
var resolution_index := 3
var file_path := "user://settings.cfg"
var persist_enabled := not "--test-mode" in OS.get_cmdline_user_args()

func _ready() -> void:
	load_settings()
	apply_sound()
	# Chờ cửa sổ gốc khởi tạo xong rồi mới áp dụng lựa chọn đã lưu.
	apply_display.call_deferred()

func load_settings() -> void:
	if not persist_enabled:
		return
	var config := ConfigFile.new()
	if config.load(file_path) != OK:
		return
	volume = clampf(float(config.get_value("sound", "volume", 0.80)), 0.0, 1.0)
	muted = bool(config.get_value("sound", "muted", false))
	# Bản 16:9 dùng mặc định mới một lần; vẫn giữ âm lượng của bản 4:3.
	if int(config.get_value("display", "version", 0)) == DISPLAY_VERSION:
		fullscreen = bool(config.get_value("display", "fullscreen", true))
		resolution_index = clampi(int(config.get_value("display", "resolution", 3)), 0, RESOLUTIONS.size() - 1)

func save_settings() -> void:
	if not persist_enabled:
		return
	var config := ConfigFile.new()
	config.set_value("sound", "volume", volume)
	config.set_value("sound", "muted", muted)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "version", DISPLAY_VERSION)
	config.set_value("display", "resolution", resolution_index)
	config.save(file_path)

func apply_sound() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, muted or volume <= 0.0)

func apply_display() -> void:
	# Máy chạy kiểm thử headless không có cửa sổ thật.
	if DisplayServer.get_name() == "headless":
		return
	# Dùng Window để Godot và cửa sổ hệ điều hành luôn có cùng mode/size.
	var window := get_window()
	window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	if not fullscreen:
		var screen := DisplayServer.window_get_current_screen()
		var usable := DisplayServer.screen_get_usable_rect(screen)
		var wanted := RESOLUTIONS[resolution_index]
		# Màn hình nhỏ vẫn giữ cửa sổ trong vùng nhìn thấy được.
		var size := Vector2i(mini(wanted.x, usable.size.x), mini(wanted.y, usable.size.y))
		window.size = size
		window.position = usable.position + (usable.size - size) / 2
