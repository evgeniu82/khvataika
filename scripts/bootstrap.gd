extends Control

# Lightweight launcher. It owns the same brown loading screen that the game
# used before the startup refactor, then loads the heavy Main scene in a worker.
var load_path := "res://scenes/Main.tscn"
var load_started := false
var main_instance: Node = null
var loading_screen: Control
var loading_progress: ProgressBar
var loading_status: Label
var loading_stage: Label
var loading_percent: Label
var loading_tip: Label
var loading_ring: Panel
var loading_tip_index: int = 0
var loading_step_index: int = 0

func _ready() -> void:
    create_loading_screen()
    if loading_progress:
        loading_progress.value = 0.0
    if loading_percent:
        loading_percent.text = "0%"
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
    if loading_progress:
        loading_progress.value = value
    if loading_percent:
        loading_percent.text = "%d%%" % int(value)
    if loading_stage:
        loading_stage.text = "ЗАГРУЖАЕМ ОСНОВНУЮ ИГРУ"
    if status == ResourceLoader.THREAD_LOAD_LOADED:
        var packed := ResourceLoader.load_threaded_get(load_path) as PackedScene
        if packed == null:
            _fail("ОШИБКА ЗАГРУЗКИ ИГРЫ")
            return
        load_started = false
        if loading_progress:
            loading_progress.value = 75.0
        if loading_percent:
            loading_percent.text = "75%"
        if loading_status:
            loading_status.text = "ПОДГОТАВЛИВАЕМ АВТОМАТ..."
        if loading_stage:
            loading_stage.text = "MAIN.TSCN ЗАГРУЖЕН"
        await get_tree().process_frame
        main_instance = packed.instantiate()
        main_instance.name = "ClawNeonReal3D"
        add_child(main_instance)
        # Main reuses this exact loading screen and continues from 75% to 100%.
    elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        _fail("НЕ УДАЛОСЬ ЗАГРУЗИТЬ ИГРУ")

func _fail(message: String) -> void:
    load_started = false
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

