extends Control

# Лёгкий стартовый загрузчик. Коричневый экран ниже НЕ меняем.
# Главная сцена больше не загружается целиком: сначала отдельно загружается
# только runtime-скрипт, затем создаётся пустой Node3D и уже после кадра
# запускается последовательная инициализация игры.
var main_scene_path := "res://scenes/Main.tscn"
var main_scene_load_started := false
var main_scene_attaching := false
var main_scene: PackedScene = null
var main_instance: Node3D = null
var loading_screen: Control
var loading_progress: ProgressBar
var loading_status: Label
var loading_stage: Label
var loading_percent: Label
var loading_tip: Label
var loading_elapsed: float = 0.0
var loading_tip_index: int = 0
var handoff_started: bool = false
var handoff_elapsed: float = 0.0
var handoff_wait_frames: int = 0

var tips := [
    "СОВЕТ: РЕДКИЕ ИГРУШКИ ПОЯВЛЯЮТСЯ НЕ СЛУЧАЙНО.",
    "СОВЕТ: НАВОДИ КЛЕШНЮ ТОЧНЕЕ — ТАК ПРОЩЕ ЗАХВАТИТЬ ПРИЗ.",
    "СОВЕТ: СОБИРАЙ КОЛЛЕКЦИИ — ЗА ДОСТИЖЕНИЯ ПОЛАГАЮТСЯ НАГРАДЫ.",
    "СОВЕТ: МАСТЕРСКАЯ ПОМОГАЕТ ПРОКАЧИВАТЬ ВОЗМОЖНОСТИ АППАРАТА.",
    "СОВЕТ: ПРОВЕРЯЙ СУНДУКИ И СЕЗОННЫЕ НАГРАДЫ.",
    "СОВЕТ: ПРАЗДНИЧНЫЕ СОБЫТИЯ МОГУТ ДАТЬ ОСОБЫЕ БОНУСЫ.",
    "СОВЕТ: ПРОМОКОДЫ МОГУТ ОТКРЫТЬ ДОПОЛНИТЕЛЬНЫЕ НАГРАДЫ.",
    "СОВЕТ: ЗАБИРАЙ ЕЖЕДНЕВНЫЙ БОНУС, ЧТОБЫ НЕ ПРОПУСКАТЬ НАГРАДЫ."
]

func _ready() -> void:
    create_loading_screen()
    _set_progress(0.0, "ПОДГОТАВЛИВАЕМ АВТОМАТ...", "ШАГ 0 • ПОДГОТОВКА")
    await get_tree().process_frame
    _set_progress(2.0, "ЗАПУСКАЕМ ПОСЛЕДОВАТЕЛЬНУЮ ЗАГРУЗКУ...", "ШАГ 1 • СТАРТ")
    await get_tree().process_frame
    # Load the tiny Main scene as one threaded resource. Main.tscn contains
    # only a Node3D + main.gd; the script itself performs NO heavy work in _ready.
    # This avoids the fragile set_script() handoff that previously stopped at 15%.
    ResourceLoader.load_threaded_request(main_scene_path, "PackedScene", true)
    main_scene_load_started = true
    _set_progress(5.0, "ЗАГРУЖАЕМ ОСНОВУ ИГРОВОГО МОДУЛЯ...", "ШАГ 2 • ОСНОВА ИГРЫ")
    set_process(true)

func _process(delta: float) -> void:
    loading_elapsed += delta
    _update_tip()
    if handoff_started:
        handoff_elapsed += delta

    if main_instance and is_instance_valid(main_instance):
        if bool(main_instance.get("game_initialized")):
            set_process(false)
            return

    if handoff_started:
        # Give Main two completely clean engine frames, then invoke its startup
        # method directly. We do not use a property handshake or depend on
        # Main._process(), because that was the exact 15% failure point.
        if main_instance and is_instance_valid(main_instance):
            if bool(main_instance.get("game_initialized")):
                set_process(false)
                return
            handoff_wait_frames -= 1
            if handoff_wait_frames <= 0:
                handoff_started = false
                main_instance.call("begin_sequential_initialization")
                set_process(true)
        return

    if not main_scene_load_started or main_scene_attaching:
        return

    var progress := []
    var status := ResourceLoader.load_threaded_get_status(main_scene_path, progress)
    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        var raw := 0.0
        if progress.size() > 0:
            raw = clampf(float(progress[0]), 0.0, 1.0)
        var value := 5.0 + raw * 7.0
        _set_progress(value, "ЗАГРУЖАЕМ ОСНОВУ ИГРОВОГО МОДУЛЯ...", "ШАГ 2 • ОСНОВА ИГРЫ")
        return

    if status == ResourceLoader.THREAD_LOAD_LOADED:
        main_scene_attaching = true
        main_scene_load_started = false
        main_scene = ResourceLoader.load_threaded_get(main_scene_path) as PackedScene
        if main_scene == null:
            _fail("ОШИБКА ЗАГРУЗКИ ОСНОВНОЙ СЦЕНЫ")
            return

        _set_progress(12.0, "ОСНОВА ИГРОВОГО МОДУЛЯ ЗАГРУЖЕНА", "ШАГ 3 • ОСНОВА ГОТОВА")

        # Instantiate the already-loaded tiny scene. Main._ready only connects
        # to the existing loading screen and returns immediately.
        main_instance = main_scene.instantiate() as Node3D
        if main_instance == null:
            _fail("ОШИБКА СОЗДАНИЯ ИГРОВОГО МОДУЛЯ")
            return
        main_instance.name = "ClawNeonReal3D"
        add_child(main_instance)
        _set_progress(15.0, "ИГРОВОЙ МОДУЛЬ ЗАПУЩЕН", "ШАГ 5 • ПЕРЕДАЁМ УПРАВЛЕНИЕ ИГРЕ")
        main_scene_attaching = false

        # No coroutine call here. Give Main one clean engine frame, then let
        # Main's own _process start the sequential initialization.
        handoff_started = true
        handoff_elapsed = 0.0
        handoff_wait_frames = 2
        return

    if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        _fail("НЕ УДАЛОСЬ ЗАГРУЗИТЬ ОСНОВНОЙ КОД")

func _set_progress(value: float, status_text: String, stage_text: String) -> void:
    var safe := clampf(value, 0.0, 100.0)
    if loading_progress:
        loading_progress.value = safe
    if loading_percent:
        loading_percent.text = "%d%%" % int(safe)
    if loading_status:
        loading_status.text = status_text
    if loading_stage:
        loading_stage.text = stage_text

func _update_tip() -> void:
    if loading_tip and is_instance_valid(loading_tip):
        var next_tip := int(loading_elapsed / 2.5) % tips.size()
        if next_tip != loading_tip_index:
            loading_tip_index = next_tip
            loading_tip.text = tips[loading_tip_index]

func _fail(message: String) -> void:
    main_scene_load_started = false
    main_scene_attaching = false
    if loading_status:
        loading_status.text = message
    if loading_stage:
        loading_stage.text = "ПЕРЕЗАПУСТИТЕ ПРИЛОЖЕНИЕ"
    if loading_percent:
        loading_percent.text = "!"

func create_loading_screen() -> void:
    # Полноэкранный загрузочный экран в коричневой стилистике игры.
    # Внутри игрового загрузчика миниатюры нет: только типографика,
    # статус, прогресс и аккуратные декоративные элементы.
    loading_screen = Control.new()
    loading_screen.name = "LoadingScreen"
    loading_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    loading_screen.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(loading_screen)

    var bg := ColorRect.new()
    bg.color = Color("#160F0B")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    loading_screen.add_child(bg)

    var top := ColorRect.new()
    top.color = Color("#3B2618")
    top.position = Vector2(0, 0)
    top.size = Vector2(1080, 300)
    loading_screen.add_child(top)

    var bottom := ColorRect.new()
    bottom.color = Color("#21140D")
    bottom.position = Vector2(0, 1620)
    bottom.size = Vector2(1080, 300)
    loading_screen.add_child(bottom)

    # Декоративные горизонтальные полосы заполняют пространство и
    # визуально связывают верхнюю и нижнюю части экрана.
    for y in [350, 1540]:
        var line := ColorRect.new()
        line.color = Color("#76583F")
        line.position = Vector2(70, y)
        line.size = Vector2(940, 2)
        loading_screen.add_child(line)

    var card := Panel.new()
    card.position = Vector2(45, 70)
    card.size = Vector2(990, 1780)
    var card_style := StyleBoxFlat.new()
    card_style.bg_color = Color(0.09, 0.055, 0.035, 0.98)
    card_style.border_color = Color("#76583F")
    card_style.set_border_width_all(2)
    card_style.set_corner_radius_all(34)
    card.add_theme_stylebox_override("panel", card_style)
    loading_screen.add_child(card)

    var top_label := Label.new()
    top_label.text = "АРКАДНЫЙ АВТОМАТ  •  ХВАТАЙКА"
    top_label.position = Vector2(70, 120)
    top_label.size = Vector2(940, 44)
    top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    top_label.add_theme_font_size_override("font_size", 18)
    top_label.modulate = Color("#C9A982")
    loading_screen.add_child(top_label)

    var title := Label.new()
    title.text = "СИМУЛЯТОР ХВАТАЙКА"
    title.position = Vector2(60, 430)
    title.size = Vector2(960, 100)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 48)
    title.add_theme_color_override("font_color", Color("#E5C69D"))
    title.add_theme_color_override("font_shadow_color", Color("#3A2417"))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 3)
    loading_screen.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "АРКАДНЫЙ СИМУЛЯТОР • ИГРАЙ • ЛОВИ • СОБИРАЙ • ПРОКАЧИВАЙ"
    subtitle.position = Vector2(80, 535)
    subtitle.size = Vector2(920, 55)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 17)
    subtitle.modulate = Color("#BCA996")
    loading_screen.add_child(subtitle)

    var divider := ColorRect.new()
    divider.color = Color("#9A7653")
    divider.position = Vector2(270, 620)
    divider.size = Vector2(540, 3)
    loading_screen.add_child(divider)

    loading_status = Label.new()
    loading_status.text = "ЗАГРУЗКА ИГРЫ..."
    loading_status.position = Vector2(80, 700)
    loading_status.size = Vector2(920, 52)
    loading_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loading_status.add_theme_font_size_override("font_size", 22)
    loading_status.modulate = Color("#E0C6A2")
    loading_screen.add_child(loading_status)

    loading_progress = ProgressBar.new()
    loading_progress.position = Vector2(125, 785)
    loading_progress.size = Vector2(830, 28)
    loading_progress.min_value = 0.0
    loading_progress.max_value = 100.0
    loading_progress.value = 0.0
    loading_progress.show_percentage = false
    var progress_bg := StyleBoxFlat.new()
    progress_bg.bg_color = Color("#241710")
    progress_bg.corner_radius_top_left = 14
    progress_bg.corner_radius_top_right = 14
    progress_bg.corner_radius_bottom_left = 14
    progress_bg.corner_radius_bottom_right = 14
    progress_bg.border_color = Color("#4B392B")
    progress_bg.set_border_width_all(1)
    var progress_fill := StyleBoxFlat.new()
    progress_fill.bg_color = Color("#A3754D")
    progress_fill.corner_radius_top_left = 14
    progress_fill.corner_radius_top_right = 14
    progress_fill.corner_radius_bottom_left = 14
    progress_fill.corner_radius_bottom_right = 14
    loading_progress.add_theme_stylebox_override("background", progress_bg)
    loading_progress.add_theme_stylebox_override("fill", progress_fill)
    loading_screen.add_child(loading_progress)

    loading_percent = Label.new()
    loading_percent.text = "0%"
    loading_percent.position = Vector2(80, 835)
    loading_percent.size = Vector2(920, 48)
    loading_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loading_percent.add_theme_font_size_override("font_size", 24)
    loading_percent.modulate = Color("#DDB47A")
    loading_screen.add_child(loading_percent)

    # Небольшой блок состояния вместо изображения: он заполняет центральную
    # область экрана, но не мешает основному индикатору загрузки.
    var info := Label.new()
    info.text = "ПОДГОТОВКА АВТОМАТА\nЗАГРУЖАЕМ ИГРУШКИ • НАСТРАИВАЕМ МЕХАНИКУ • ПРОВЕРЯЕМ БОНУСЫ"
    info.position = Vector2(95, 930)
    info.size = Vector2(890, 120)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_font_size_override("font_size", 18)
    info.modulate = Color("#A98E76")
    loading_screen.add_child(info)

    var tips_title := Label.new()
    tips_title.text = "ПОЛЕЗНО ЗНАТЬ"
    tips_title.position = Vector2(80, 1110)
    tips_title.size = Vector2(920, 45)
    tips_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tips_title.add_theme_font_size_override("font_size", 18)
    tips_title.modulate = Color("#C9A982")
    loading_screen.add_child(tips_title)

    loading_stage = Label.new()
    loading_stage.text = "ШАГ 0 • ПОДГОТОВКА"
    loading_stage.position = Vector2(100, 880)
    loading_stage.size = Vector2(880, 40)
    loading_stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loading_stage.add_theme_font_size_override("font_size", 15)
    loading_stage.modulate = Color("#9E8975")
    loading_screen.add_child(loading_stage)

    loading_tip = Label.new()
    loading_tip.text = "СОВЕТ: ТЩАТЕЛЬНО НАВОДИ КЛЕШНЮ — РЕДКИЕ ИГРУШКИ СТОЯТ ТОГО."
    loading_tip.position = Vector2(100, 1170)
    loading_tip.size = Vector2(880, 90)
    loading_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loading_tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    loading_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    loading_tip.add_theme_font_size_override("font_size", 17)
    loading_tip.modulate = Color("#D8C3AA")
    loading_screen.add_child(loading_tip)

    var hint := Label.new()
    hint.text = "ХВАТАЙ  •  СОБИРАЙ  •  ПРОКАЧИВАЙ  •  ОТКРЫВАЙ"
    hint.position = Vector2(70, 1325)
    hint.size = Vector2(940, 55)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 20)
    hint.modulate = Color("#9A7653")
    loading_screen.add_child(hint)

    var ready := Label.new()
    ready.text = "ТВОЯ КОЛЛЕКЦИЯ ЖДЁТ"
    ready.position = Vector2(70, 1430)
    ready.size = Vector2(940, 60)
    ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ready.add_theme_font_size_override("font_size", 22)
    ready.modulate = Color("#C9A982")
    loading_screen.add_child(ready)

    var footer := Label.new()
    footer.text = "СОБИРАЙ ИГРУШКИ • ОТКРЫВАЙ СУНДУКИ • ПОЛУЧАЙ БОНУСЫ"
    footer.position = Vector2(70, 1665)
    footer.size = Vector2(940, 55)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 17)
    footer.modulate = Color("#9E8975")
    loading_screen.add_child(footer)

    var version := Label.new()
    version.text = "MOBILE EDITION  •  v1.13.6"
    version.position = Vector2(70, 1795)
    version.size = Vector2(940, 38)
    version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    version.add_theme_font_size_override("font_size", 13)
    version.modulate = Color("#5D493A")
    loading_screen.add_child(version)

