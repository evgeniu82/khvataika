extends Control

# Lightweight launcher: it owns the only post-splash loading screen and loads
# the heavy Main scene through Godot's threaded resource loader.
var load_path := "res://scenes/Main.tscn"
var load_started := false
var main_instance: Node = null

@onready var loading_screen: Control = $LoadingScreen
@onready var loading_status: Label = $LoadingScreen/LoadingStatus
@onready var loading_progress: ProgressBar = $LoadingScreen/LoadingProgress
@onready var loading_percent: Label = $LoadingScreen/LoadingPercent
@onready var loading_stage: Label = $LoadingScreen/LoadingStage

func _ready() -> void:
    loading_progress.value = 0.0
    loading_percent.text = "0%"
    loading_status.text = "ЗАГРУЗКА ИГРЫ..."
    loading_stage.text = "ПОДГОТОВКА ИГРОВОГО ДВИЖКА"
    await get_tree().process_frame
    ResourceLoader.load_threaded_request(load_path, "PackedScene", true)
    load_started = true
    set_process(true)

func _process(_delta: float) -> void:
    if not load_started:
        return
    var progress := []
    var status := ResourceLoader.load_threaded_get_status(load_path, progress)
    var value := 5.0
    if progress.size() > 0:
        value = 5.0 + clampf(float(progress[0]) * 70.0, 0.0, 70.0)
    loading_progress.value = value
    loading_percent.text = "%d%%" % int(value)
    loading_stage.text = "ЗАГРУЖАЕМ ОСНОВНУЮ ИГРУ"
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        var packed := ResourceLoader.load_threaded_get(load_path) as PackedScene
        if packed == null:
            _fail("ОШИБКА ЗАГРУЗКИ ИГРЫ")
            return
        load_started = false
        loading_progress.value = 75.0
        loading_percent.text = "75%"
        loading_status.text = "ИНИЦИАЛИЗИРУЕМ ИГРОВОЙ МИР..."
        loading_stage.text = "MAIN.TSCN ЗАГРУЖЕН"
        await get_tree().process_frame
        main_instance = packed.instantiate()
        main_instance.name = "ClawNeonReal3D"
        add_child(main_instance)
        await get_tree().process_frame
        # Main.gd continues the real staged initialization and advances this
        # same loading UI from 75% to 100%.
    elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        _fail("НЕ УДАЛОСЬ ЗАГРУЗИТЬ ИГРУ")

func _fail(message: String) -> void:
    load_started = false
    loading_status.text = message
    loading_stage.text = "ПЕРЕЗАПУСТИТЕ ПРИЛОЖЕНИЕ"
    loading_percent.text = "!"
