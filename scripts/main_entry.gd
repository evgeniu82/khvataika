extends Node3D

# Ultra-light entry point. The heavy game script is NOT referenced by Main.tscn.
# It is loaded only after the brown loading screen is already visible.
const GAME_CORE_SCENE := "res://scenes/GameCore.tscn"
var core_scene: PackedScene = null
var core_instance: Node3D = null
var started := false
var loading_elapsed := 0.0

func _ready() -> void:
    set_process(true)
    await get_tree().process_frame
    await get_tree().process_frame
    if started:
        return
    started = true
    _set_loading(16.0, "ЗАГРУЖАЕМ ИГРОВОЙ МОДУЛЬ ПО ЧАСТЯМ...", "ШАГ 6 • ИГРОВОЙ МОДУЛЬ")
    ResourceLoader.load_threaded_request(GAME_CORE_SCENE, "PackedScene", true)

func _process(delta: float) -> void:
    loading_elapsed += delta
    _update_tip()
    if not started:
        return
    var progress := []
    var status := ResourceLoader.load_threaded_get_status(GAME_CORE_SCENE, progress)
    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        var raw := 0.0
        if progress.size() > 0:
            raw = clampf(float(progress[0]), 0.0, 1.0)
        _set_loading(16.0 + raw * 4.0, "ЗАГРУЖАЕМ ИГРОВОЙ МОДУЛЬ ПО ЧАСТЯМ...", "ШАГ 6 • ИГРОВОЙ МОДУЛЬ")
        return
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        core_scene = ResourceLoader.load_threaded_get(GAME_CORE_SCENE) as PackedScene
        if core_scene == null:
            _fail("ОШИБКА ЗАГРУЗКИ ИГРОВОГО МОДУЛЯ")
            set_process(false)
            return
        _set_loading(20.0, "ИГРОВОЙ МОДУЛЬ ЗАГРУЖЕН", "ШАГ 7 • ПОДГОТОВКА ИГРЫ")
        core_instance = core_scene.instantiate() as Node3D
        if core_instance == null:
            _fail("ОШИБКА СОЗДАНИЯ ИГРОВОГО МОДУЛЯ")
            set_process(false)
            return
        core_instance.name = "ClawNeonReal3D"
        add_child(core_instance)
        await get_tree().process_frame
        if is_instance_valid(core_instance) and core_instance.has_method("begin_sequential_initialization"):
            core_instance.call("begin_sequential_initialization")
            set_process(false)
        return
    if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        _fail("НЕ УДАЛОСЬ ЗАГРУЗИТЬ ИГРОВОЙ МОДУЛЬ")
        set_process(false)

func _find_loading() -> Control:
    var n := get_tree().root.find_child("LoadingScreen", true, false)
    return n as Control if n else null

func _set_loading(value: float, text: String, stage: String) -> void:
    var screen := _find_loading()
    if screen == null:
        return
    var bar := screen.get_node_or_null("LoadingProgress") as ProgressBar
    var pct := screen.get_node_or_null("LoadingPercent") as Label
    var status := screen.get_node_or_null("LoadingStatus") as Label
    var st := screen.get_node_or_null("LoadingStage") as Label
    if bar: bar.value = maxf(float(bar.value), value)
    if pct: pct.text = "%d%%" % int(maxf(float(bar.value), value))
    if status: status.text = text
    if st: st.text = stage

func _update_tip() -> void:
    var screen := _find_loading()
    if screen == null:
        return
    var tip := screen.get_node_or_null("LoadingTip") as Label
    if tip == null:
        return
    var tips := [
        "СОВЕТ: ТЩАТЕЛЬНО НАВОДИ КЛЕШНЮ — РЕДКИЕ ИГРУШКИ СТОЯТ ТОГО.",
        "СОВЕТ: СОБИРАЙ КОЛЛЕКЦИИ — ЗА ДОСТИЖЕНИЯ ПОЛАГАЮТСЯ НАГРАДЫ.",
        "СОВЕТ: ПРОКАЧИВАЙ АППАРАТ — УЛУЧШЕНИЯ ПОМОГАЮТ ЛОВИТЬ ПРИЗЫ.",
        "СОВЕТ: ПРОВЕРЯЙ ЕЖЕДНЕВНЫЕ НАГРАДЫ И СОБЫТИЯ.",
        "СОВЕТ: ТОЧНОСТЬ И ТЕРПЕНИЕ — ЛУЧШИЕ ПОМОЩНИКИ В ХВАТАЙКЕ.",
        "СОВЕТ: СОБИРАЙ ИГРУШКИ • ОТКРЫВАЙ СУНДУКИ • ПОЛУЧАЙ БОНУСЫ."
    ]
    tip.text = tips[int(loading_elapsed / 2.5) % tips.size()]

func _fail(message: String) -> void:
    var screen := _find_loading()
    if screen:
        var status := screen.get_node_or_null("LoadingStatus") as Label
        var st := screen.get_node_or_null("LoadingStage") as Label
        if status: status.text = message
        if st: st.text = "ПЕРЕЗАПУСТИТЕ ПРИЛОЖЕНИЕ"
