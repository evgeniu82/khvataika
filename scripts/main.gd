extends Node3D

# ХВАТАЙКА — REALISTIC WOOD / METAL / GLASS EDITION
# Godot 4.7+
# Procedural commercial-style arcade scene: wood, metal, glass, realistic lighting,
# physics-based plush prizes, animated cable/claw, smooth camera and menus.

const SAVE_PATH: String = "user://claw_save.json"
const PLAY_COST: int = 0
const MACHINE_CENTER := Vector3(0.0, 3.35, 0.0)
const PRIZE_HOLE := Vector3(2.35, 3.02, 1.55)
# Стартовая/парковочная точка клешни — строго сверху над отверстием.
const CLAW_HOME := Vector3(PRIZE_HOLE.x, 8.20, PRIZE_HOLE.z)
const CLAW_MIN := Vector3(-2.55, 2.70, -1.55)
const CLAW_MAX := Vector3(2.55, 8.20, 1.55)
const TOY_SCALE := 0.04968
const TARGET_PRIZE_COUNT: int = 60
const MAX_PRIZE_CENTER_Y: float = 5.12
const GRAB_SLIP_CHANCE: float = 0.18
const CAPSULE_CHANCE: float = 0.055

const CYAN := Color("#28E8FF")
const BLUE := Color("#146BFF")
const PURPLE := Color("#8A4DFF")
const PINK := Color("#FF4FCB")
const GOLD := Color("#FFD65A")
const DARK := Color("#050A17")
const NAVY := Color("#081630")
const STEEL := Color("#34435B")

var coins: int = 120
var selected_claw: int = 0
var owned_claws: Array[bool] = [true, false, false, false, false, false, false, false, false, false]
var music_on: bool = true
var music_player: AudioStreamPlayer
var sfx_on: bool = true
var collection: Dictionary = {}
var toy_inventory_counts: Dictionary = {}
var completed_collections: Dictionary = {}
var upgrade_levels: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var player_level: int = 1
var player_xp: int = 0
var xp_to_next: int = 80
const MAX_PLAYER_LEVEL: int = 1000
const REFILL_THRESHOLD: int = 12
const REFILL_AMOUNT: int = 15
const INITIAL_PRIZE_COUNT: int = 60
var total_games: int = 0
var total_prizes_won: int = 0
var rarity_wins: Dictionary = {}
var unlocked_achievements: Dictionary = {}
var pending_new_achievements: Array[String] = []
var last_daily_bonus_date: String = ""
var daily_bonus_amount: int = 25
var best_result: String = "—"
var best_result_xp: int = 0
var current_win_streak: int = 0
var best_win_streak: int = 0
var total_xp_earned: int = 0
var highest_reward_rubles: int = 0
var perfect_grabs: int = 0
var heavy_toy_wins: int = 0
var lucky_toy_wins: int = 0
var total_chests_opened: int = 0
var total_keys_earned: int = 0
var total_daily_claims: int = 0
var total_weekly_claims: int = 0

# Дополнительные системы: повторные призы, ежедневная серия, события и партии.
var login_streak: int = 0
var last_login_claim_date: String = ""
var daily_claim_available: bool = false
var daily_claim_button: Button
var daily_login_panel: PanelContainer
var daily_days_container: GridContainer
var daily_day_buttons: Array[Button] = []
var event_button: Button
var event_panel: PanelContainer
var active_event_id: String = ""
var active_event_name: String = ""
var active_event_end_unix: int = 0
var active_event_bonus: float = 0.0
var active_event_reward_mult: float = 1.0
var next_event_check: float = 0.0
var weekly_event_id: int = 0
var weekly_event_name: String = ""
var weekly_event_desc: String = ""
var weekly_event_capture: float = 0.0
var weekly_event_reward: float = 1.0
var weekly_event_rare: float = 0.0
var weekly_event_end_unix: int = 0
var batch_type: String = "ОБЫЧНАЯ ПАРТИЯ"
var batch_index: int = 0
var sale_panel: PanelContainer
var sale_price: int = 0
var sale_name: String = ""
var sale_rarity: String = ""
var sale_available: bool = false
var language: String = "ru"
var language_option: OptionButton

# Реферальная система. Для кросс-устройственного учёта нужен сервер;
# локальная часть хранит код, обработку приглашения и награды.
var referral_code: String = ""
var referral_invites: int = 0
var referral_reward_per_friend: int = 100
var referral_welcome_reward: int = 50
var referral_used: bool = false
var referral_panel: PanelContainer
var referral_link_label: Label
var referral_invites_label: Label
var referral_status_label: Label
var referral_code_input: LineEdit

# Дополнительные игровые системы
var daily_mission_progress: int = 0
var daily_mission_target: int = 3
var daily_mission_date: String = ""
var daily_mission_claimed: bool = false
var weekly_mission_progress: int = 0
var weekly_mission_target: int = 12
var weekly_mission_key: String = ""
var weekly_mission_claimed: bool = false
var lucky_toy_index: int = 0
var lucky_toy_date: String = ""
var refill_animation_timer: float = 0.0
var waiting_idle_time: float = 0.0
var start_button: Button
var waiting_overlay: PanelContainer
var waiting_tip_label: Label
var mission_label: Label
var weekly_label: Label
var lucky_label: Label
var last_game_activity: float = 0.0
var player_name: String = "ИГРОК"
var player_avatar_index: int = 0
const AVATAR_OPTIONS: Array[String] = ["👤", "😎", "🧸", "🐼", "🐱", "🐶", "🦊", "🐸", "🤖", "👑", "⭐", "🎮"]
var bonus_keys: int = 0
var engineering_parts: int = 0
var menu_notice_count: int = 0
var daily_mission_reward: int = 80
var weekly_mission_reward: int = 350
var sound_players: Dictionary = {}
var rarity_flash_timer: float = 0.0
var rarity_flash_color: Color = Color.WHITE
var machine_upgrade_visual: float = 0.0
var collection_filter: String = "ВСЕ"
var android_touch_hint_shown: bool = false

# Единая Android-навигация для всех открытых окон.
var menu_back_button: Button
var hud_back_button: Button
var _last_nav_context: String = ""

# Оставлен только звук движения клешни.
var sfx_move: AudioStreamPlayer
var sfx_streams: Dictionary = {}
var sfx_volume_db: float = -4.0
var music_volume_db: float = -8.0
var vibration_on: bool = true
var auto_tips_on: bool = true
var notifications_on: bool = true
var notification_channel_id: String = "khvataika_game"
var notification_next_id: int = 100
var notification_permission_waiting: bool = false
var notification_pending_test: bool = false
var notification_receiver_class: String = "com.clawneon.khvataika.KhvataikaAlarmReceiver"
var notify_rewards_on: bool = true
var notify_streak_on: bool = true
var notify_events_on: bool = true
var notify_workshop_on: bool = true
var notify_chests_on: bool = true
var live_systems_panel: PanelContainer
var season_pass_panel: PanelContainer
var promo_panel: PanelContainer
var news_panel: PanelContainer
var rating_panel: PanelContainer
var return_bonus_panel: PanelContainer
var return_bonus_button: Button
var return_bonus_days: int = 0
var return_bonus_available: bool = false
var return_bonus_claimed: bool = false
var last_active_unix: int = 0
var return_bonus_amount: int = 150
var workshop_job_end_unix: int = 0
var workshop_job_active: bool = false
var workshop_job_name: String = ""
var workshop_job_reward: int = 0
var season_pass_xp: int = 0
var season_pass_level: int = 1
const SEASON_PASS_MAX_LEVEL: int = 30
var promo_codes_used: Dictionary = {}
var promo_status: String = ""
var news_items: Array[Dictionary] = [
    {"date":"08.09.2026", "title":"🆕 ХВАТАЙКА v1.8.4", "text":"Добавлен раздел «Новости»: здесь будут появляться обновления, события, новые игрушки и важные объявления."},
    {"date":"08.09.2026", "title":"🎟 НОВЫЕ ПРОМОКОДЫ", "text":"Следи за новостями — именно здесь будут публиковаться новые промокоды и условия их получения."},
    {"date":"08.09.2026", "title":"🎁 БОНУС ЗА ВОЗВРАЩЕНИЕ", "text":"Бонус теперь появляется отдельным кружком на игровом экране только тогда, когда он доступен."},
    {"date":"08.09.2026", "title":"🔔 УВЕДОМЛЕНИЯ", "text":"Система уведомлений продолжает напоминать о наградах, серии, событиях, мастерской и сундуках."}
]
var news_unread: int = 4

# Онлайн-сервер и удалённая конфигурация. Сервер необязателен: при пустом URL игра работает локально.
const DEFAULT_SERVER_URL: String = "http://135.106.209.40:8080"
const SERVER_AUTHORITATIVE: bool = true
var server_url: String = DEFAULT_SERVER_URL
var player_id: String = ""
var player_token: String = ""
var remote_action_name: String = ""
var server_settings_dirty: bool = false
var server_settings_sync_timer: float = 0.0
var blocked_overlay: PanelContainer
var news_menu_button: Button
var remote_config: Dictionary = {}
var remote_news_items: Array[Dictionary] = []
var remote_leaderboard: Array[Dictionary] = []
var remote_sync_status: String = "СЕРВЕР НЕ НАСТРОЕН"
var remote_sync_timer: float = 5.0
var remote_notification_timer: float = 12.0
var remote_notification_cursor: int = 0
var remote_device_registered: bool = false
var remote_sync_retry_count: int = 0
var remote_auth_retry_timer: float = 2.0
var remote_http: HTTPRequest
var claw_http: HTTPRequest
var cosmetic_http: HTTPRequest
var claw_http_busy: bool = false
var cosmetic_http_busy: bool = false
var remote_request_kind: String = ""
var remote_sync_pending: bool = false
var remote_action_queue: Array[Dictionary] = []
var remote_pending_promo: String = ""
var remote_pending_referral: String = ""
var pending_incoming_referral: String = ""
var remote_promo_request_active: bool = false
var online_maintenance: bool = false
var online_announcement: String = ""
var online_reward_multiplier: float = 1.0
var online_daily_bonus_amount: int = 25
var online_daily_mission_reward: int = 80
var online_weekly_mission_reward: int = 350
var online_return_bonus_base: int = 100
var online_return_bonus_per_day: int = 25
var online_return_bonus_max_days: int = 30
var online_notification_hours: Dictionary = {"rewards":12,"streak":20,"chests":18}

var energy_saving_on: bool = false
var confirm_purchases_on: bool = true
var confirm_rare_chests_on: bool = true
var fps_limit: int = 60
var joystick_sensitivity: float = 1.0
var grab_button_scale: float = 1.0
var aim_marker: MeshInstance3D
var machine_status_label: Label
var help_panel: PanelContainer

var claw: Node3D
var claw_arms: Array[Node3D] = []
var cable: MeshInstance3D
var cable_glow: MeshInstance3D
var rail_carriage: Node3D
var claw_target: Vector3 = CLAW_HOME
var claw_move_target: Vector3 = CLAW_HOME
var claw_pos: Vector3 = CLAW_HOME
var claw_yaw: float = 0.0
var drop_state: int = 0 # 0 ready, 1 down, 2 grip, 3 return, 4 deliver
var drop_time: float = 0.0
var grabbed_toy: RigidBody3D
var grabbed_index: int = -1
var pending_prize_data: Dictionary = {}
var claw_drop_target_y: float = 3.50
var current_result: String = "ГОТОВ К ИГРЕ"
var last_prize_name: String = ""
var last_prize_collection: String = ""
var last_prize_rarity: String = ""
var last_prize_xp: int = 0
var last_reward_rubles: int = 0
var camera: Camera3D
var camera_base: Vector3 = Vector3(0.0, 8.05, 12.8)
var camera_look: Vector3 = Vector3(0.0, 4.85, 0.0)
var time_alive: float = 0.0

# Графическое качество: 0 — ПЛОХО, 1 — НИЗКО, 2 — СРЕДНЕ, 3 — ВЫСОКО, 4 — УЛЬТРА.
# Настройка влияет только на рендеринг и не удаляет игровой контент.
var quality_level: int = 2
var quality_option: OptionButton
var loading_screen: Control
var startup_splash: CanvasLayer
var loading_progress: ProgressBar
var loading_status: Label
var loading_stage: Label
var loading_percent: Label
var loading_tip: Label
var loading_ring: Panel
var loading_elapsed: float = 0.0
var loading_tip_index: int = 0
var loading_step_index: int = 0
var game_initialized: bool = false
var scene_lights: Array[Light3D] = []
var reflection_probe: ReflectionProbe
var world_environment: WorldEnvironment
var event_ui_update_timer: float = 0.0
var active_event_theme: String = ""
var active_event_accent: Color = Color("#8A684C")
var active_event_glow: Color = Color("#F2DCC0")
var active_event_rare_bonus: float = 0.0
var active_event_toy_bonus: float = 0.0
var event_decor_root: Node3D

var status_label: Label
var coins_label: Label
var level_label: Label
var xp_label: Label
var xp_bar: ProgressBar
var menu_layer: Control
var hud_layer: Control
var gameplay_modal_blocker: Control
var shop_panel: PanelContainer
var shop_content: VBoxContainer
var shop_category: String = "upgrades"
var owned_claw_skins: Array[bool] = []
var owned_toy_skins: Array[bool] = []
var owned_machine_skins: Array[bool] = []
var selected_claw_skin: int = 0
var selected_toy_skin: int = 0
var selected_machine_skin: int = 0
var server_attempt_ready: bool = false
var server_attempt_success: bool = false
var server_attempt_toy_id: String = ""
var server_attempt_toy_name: String = ""
var server_attempt_reward: Dictionary = {}
var server_attempt_slip: bool = false
var server_target_prize_index: int = -1
var joystick_hold_x: float = 0.0
var joystick_hold_z: float = 0.0
var vip_panel: PanelContainer
var seasons_panel: PanelContainer
var vip_owned: Array[bool] = []
var vip_selected: int = 0
var active_season_id: String = ""

# Сундуки и мастерская.
var chests_panel: PanelContainer
var workshop_panel: PanelContainer
var chest_inventory: Dictionary = {"common": 0, "rare": 0, "epic": 0, "legendary": 0, "vip": 0}
var chest_keys: int = 0
var chest_opening: bool = false
var chest_last_reward: String = ""
var chest_exclusive_toys: Dictionary = {}
var chest_exclusive_skins: Dictionary = {}
var chest_exclusive_reward_count: int = 0
var chest_key_costs: Dictionary = {"common": 1, "rare": 2, "epic": 3, "legendary": 5, "vip": 8}
var workshop_parts: int = 0
var workshop_level: int = 1
var workshop_claw_power: int = 0
var workshop_speed: int = 0
var workshop_precision: int = 0
var workshop_luck: int = 0
# Продвинутая мастерская: инженерные модули, калибровка и чертежи.
var workshop_motor: int = 0
var workshop_servo: int = 0
var workshop_cable: int = 0
var workshop_damper: int = 0
var workshop_cooling: int = 0
var workshop_controller: int = 0
var workshop_blueprints: Dictionary = {"grip":"none", "speed":"none", "precision":"none", "luck":"none"}
var workshop_calibration: int = 0
var workshop_overclock: bool = false
var workshop_overclock_games: int = 0

var vip_specs: Array[Dictionary] = [
    {"name":"GOLDEN GRIP ELITE", "price":2500, "desc":"+8% к силе захвата", "bonus":0.08},
    {"name":"VIP BOOST", "price":3200, "desc":"+25% к наградам", "reward":0.25},
    {"name":"LUCKY PASS", "price":3800, "desc":"+10% к шансу редкого приза", "luck":0.10},
    {"name":"FREE PLAY", "price":4500, "desc":"Одна бесплатная игра каждый день", "daily":1},
    {"name":"ROYAL CLAW", "price":5500, "desc":"Эксклюзивная золотая клешня", "skin":5},
    {"name":"VIP MACHINE", "price":7000, "desc":"Эксклюзивный корпус аппарата", "machine":9},
    {"name":"MYTHIC TOYS", "price":8500, "desc":"Открывает мифическую серию игрушек", "toy":11},
    {"name":"VIP MASTER", "price":12000, "desc":"+15% к силе и +15% к наградам", "bonus":0.15, "reward":0.15}
]

var season_specs: Array[Dictionary] = [
    {"id":"winter","name":"❄️ ЗИМНИЙ СЕЗОН","months":[12,1,2],"theme":"Снег, лёд, Новый год и зимние праздники"},
    {"id":"spring","name":"🌸 ВЕСЕННИЙ СЕЗОН","months":[3,4,5],"theme":"Весна, цветы, Пасха и майские праздники"},
    {"id":"summer","name":"☀️ ЛЕТНИЙ СЕЗОН","months":[6,7,8],"theme":"Лето, каникулы, море и приключения"},
    {"id":"autumn","name":"🍂 ОСЕННИЙ СЕЗОН","months":[9,10,11],"theme":"Осень, школа, Хэллоуин и осенние события"}
]

# Большой календарь тематических событий. Международные даты сверены с календарём ООН; национальные и культурные даты используются как игровые темы.
var holiday_calendar: Array[Dictionary] = [
    {"date":"01-01","name":"🎆 Новый год","season":"winter"},{"date":"01-04","name":"⠿ Всемирный день Брайля","season":"winter"},{"date":"01-07","name":"🎄 Рождество","season":"winter"},{"date":"01-24","name":"📚 Международный день образования","season":"winter"},{"date":"01-26","name":"⚡ Международный день чистой энергии","season":"winter"},{"date":"01-27","name":"🕊️ Международный день памяти жертв Холокоста","season":"winter"},{"date":"02-02","name":"🌿 Всемирный день водно-болотных угодий","season":"winter"},{"date":"02-04","name":"🤝 Международный день человеческого братства","season":"winter"},{"date":"02-10","name":"🌾 Всемирный день зернобобовых","season":"winter"},{"date":"02-11","name":"🔬 Женщины и девочки в науке","season":"winter"},{"date":"02-13","name":"📻 Всемирный день радио","season":"winter"},{"date":"02-14","name":"❤️ День святого Валентина","season":"winter"},{"date":"02-21","name":"🗣️ Международный день родного языка","season":"winter"},{"date":"02-23","name":"⭐ День защитника Отечества","season":"winter"},{"date":"03-01","name":"🌈 День нулевой дискриминации","season":"spring"},{"date":"03-03","name":"🐾 Всемирный день дикой природы","season":"spring"},{"date":"03-08","name":"🌷 Международный женский день","season":"spring"},{"date":"03-14","name":"🥧 День числа Пи","season":"spring"},{"date":"03-20","name":"😊 Международный день счастья","season":"spring"},{"date":"03-21","name":"🌳 Международный день лесов","season":"spring"},{"date":"03-22","name":"💧 Всемирный день воды","season":"spring"},{"date":"03-27","name":"🎭 Всемирный день театра","season":"spring"},{"date":"04-01","name":"😂 День смеха","season":"spring"},{"date":"04-02","name":"🧩 Всемирный день распространения информации об аутизме","season":"spring"},{"date":"04-07","name":"🌍 Всемирный день здоровья","season":"spring"},{"date":"04-12","name":"🚀 Международный день полёта человека в космос","season":"spring"},{"date":"04-22","name":"🌎 День Земли","season":"spring"},{"date":"04-23","name":"📖 Всемирный день книги","season":"spring"},{"date":"04-30","name":"🎷 Международный день джаза","season":"spring"},{"date":"05-01","name":"🛠️ Праздник труда","season":"spring"},{"date":"05-03","name":"📰 Всемирный день свободы печати","season":"spring"},{"date":"05-09","name":"🎖️ День Победы","season":"spring"},{"date":"05-15","name":"👨‍👩‍👧 Международный день семей","season":"spring"},{"date":"05-20","name":"🐝 Всемирный день пчёл","season":"spring"},{"date":"05-21","name":"☕ Международный день чая","season":"spring"},{"date":"05-24","name":"📜 День славянской письменности и культуры","season":"spring"},{"date":"06-01","name":"🧸 День защиты детей","season":"summer"},{"date":"06-03","name":"🚲 Всемирный день велосипеда","season":"summer"},{"date":"06-05","name":"🌱 Всемирный день окружающей среды","season":"summer"},{"date":"06-08","name":"🌊 Всемирный день океанов","season":"summer"},{"date":"06-12","name":"🌟 День России","season":"summer"},{"date":"06-21","name":"🧘 Международный день йоги","season":"summer"},{"date":"06-30","name":"☄️ Международный день астероида","season":"summer"},{"date":"07-03","name":"🤝 Международный день кооперативов","season":"summer"},{"date":"07-20","name":"♟️ Международный день шахмат","season":"summer"},{"date":"07-30","name":"🤗 Международный день дружбы","season":"summer"},{"date":"08-09","name":"🌎 День коренных народов мира","season":"summer"},{"date":"08-12","name":"🎮 Международный день молодёжи","season":"summer"},{"date":"08-19","name":"❤️ Всемирный гуманитарный день","season":"summer"},{"date":"08-22","name":"🍑 День арбуза","season":"summer"},{"date":"08-31","name":"💻 День блога","season":"summer"},{"date":"09-01","name":"🎒 День знаний","season":"autumn"},{"date":"09-05","name":"❤️ Международный день благотворительности","season":"autumn"},{"date":"09-08","name":"📚 Международный день грамотности","season":"autumn"},{"date":"09-21","name":"🕊️ Международный день мира","season":"autumn"},{"date":"09-27","name":"✈️ Всемирный день туризма","season":"autumn"},{"date":"10-01","name":"🎵 Международный день музыки","season":"autumn"},{"date":"10-04","name":"🚀 Всемирная неделя космоса","season":"autumn"},{"date":"10-05","name":"🍎 Всемирный день учителя","season":"autumn"},{"date":"10-16","name":"🍎 Всемирный день продовольствия","season":"autumn"},{"date":"10-24","name":"🌐 День Организации Объединённых Наций","season":"autumn"},{"date":"10-31","name":"🎃 Хэллоуин","season":"autumn"},{"date":"11-01","name":"🌱 Всемирный день вегана","season":"autumn"},{"date":"11-04","name":"🇷🇺 День народного единства","season":"autumn"},{"date":"11-11","name":"🛍️ День холостяков","season":"autumn"},{"date":"11-17","name":"👶 Всемирный день недоношенных детей","season":"autumn"},{"date":"11-19","name":"👨 Международный мужской день","season":"autumn"},{"date":"11-20","name":"🧸 Всемирный день ребёнка","season":"autumn"},{"date":"11-26","name":"🦃 День благодарения","season":"autumn"},{"date":"11-30","name":"🎁 Giving Tuesday","season":"autumn"},{"date":"12-03","name":"♿ Международный день инвалидов","season":"winter"},{"date":"12-05","name":"🤝 Международный день добровольцев","season":"winter"},{"date":"12-10","name":"⚖️ День прав человека","season":"winter"},{"date":"12-11","name":"🏔️ Международный день гор","season":"winter"},{"date":"12-18","name":"🌍 Международный день мигрантов","season":"winter"},{"date":"12-20","name":"🤝 Международный день человеческой солидарности","season":"winter"},{"date":"12-25","name":"🎄 Рождество","season":"winter"},{"date":"12-31","name":"🎇 Канун Нового года","season":"winter"}
]

var claw_skin_specs: Array[Dictionary] = [
    {"name":"КЛАССИК", "price":0, "color":Color("#8B765E")},
    {"name":"ЛАЗУРЬ", "price":180, "color":Color("#22C8FF")},
    {"name":"НЕОН", "price":320, "color":Color("#A64DFF")},
    {"name":"РОЗОВЫЙ КРИСТАЛЛ", "price":450, "color":Color("#FF4FCB")},
    {"name":"РУБИН", "price":650, "color":Color("#FF405F")},
    {"name":"ЗОЛОТО", "price":900, "color":Color("#FFD65A")},
    {"name":"МЯТНЫЙ", "price":1100, "color":Color("#35E0B0")},
    {"name":"ЛЕД", "price":1350, "color":Color("#72F5FF")},
    {"name":"КИБЕР", "price":1650, "color":Color("#4DFF7A")},
    {"name":"КОСМОС", "price":2100, "color":Color("#6B5CFF")},
    {"name":"ВУЛКАН", "price":2600, "color":Color("#FF762E")},
    {"name":"LEGEND", "price":3500, "color":Color("#F4D06F")}
]
var toy_skin_specs: Array[Dictionary] = [
    {"name":"ОРИГИНАЛ", "price":0, "tint":Color("#FFFFFF")},
    {"name":"ПАСТЕЛЬ", "price":220, "tint":Color("#FFD6EA")},
    {"name":"НЕОН", "price":380, "tint":Color("#7CFFEA")},
    {"name":"ЗОЛОТОЙ", "price":650, "tint":Color("#FFD85A")},
    {"name":"СЕРЕБРО", "price":800, "tint":Color("#DDE8F2")},
    {"name":"КОСМОС", "price":1050, "tint":Color("#8B6CFF")},
    {"name":"ОГОНЬ", "price":1300, "tint":Color("#FF6945")},
    {"name":"ЛЕДЯНОЙ", "price":1500, "tint":Color("#62DFFF")},
    {"name":"РАДУГА", "price":1900, "tint":Color("#FF6FCF")},
    {"name":"КИБЕР", "price":2300, "tint":Color("#45F0A0")},
    {"name":"ТЁМНАЯ СЕРИЯ", "price":2800, "tint":Color("#7C7890")},
    {"name":"МИФИЧЕСКАЯ", "price":3800, "tint":Color("#FFB84D")}
]
var machine_skin_specs: Array[Dictionary] = [
    {"name":"КЛАССИКА", "price":0, "frame":Color("#8A6A4A"), "light":Color("#F2DCC0")},
    {"name":"НЕОН СИТИ", "price":500, "frame":Color("#243A78"), "light":Color("#39D9FF")},
    {"name":"РОЗОВЫЙ CLUB", "price":750, "frame":Color("#7B315D"), "light":Color("#FF5EDB")},
    {"name":"ICE MACHINE", "price":1000, "frame":Color("#3B6D8A"), "light":Color("#8DEBFF")},
    {"name":"GOLD MACHINE", "price":1400, "frame":Color("#8B6B28"), "light":Color("#FFD95A")},
    {"name":"CYBER GRID", "price":1750, "frame":Color("#174B4A"), "light":Color("#52FFB0")},
    {"name":"SPACE PORT", "price":2100, "frame":Color("#322D65"), "light":Color("#9C7CFF")},
    {"name":"FIRE BOX", "price":2450, "frame":Color("#71351F"), "light":Color("#FF7547")},
    {"name":"MIDNIGHT", "price":2800, "frame":Color("#1D2533"), "light":Color("#8A9DFF")},
    {"name":"LEGENDARY", "price":3600, "frame":Color("#6E5220"), "light":Color("#FFE58A")}
]
var collection_panel: PanelContainer
var settings_panel: PanelContainer
var achievements_panel: PanelContainer
var selected_achievement_category: String = "ВСЕ"
var achievement_category_buttons: Array[Button] = []
var profile_panel: PanelContainer
var hud_profile_button: Button
var stats_panel: PanelContainer
var result_popup: PanelContainer
var popup_name_label: Label
var popup_info_label: Label
var popup_xp_label: Label
var popup_timer: float = 0.0
var popup_achievement_label: Label
var toast_label: Label
var main_menu_controls: Array[Control] = []
var machine_lights: Array[OmniLight3D] = []
var machine: Node3D
var prize_bodies: Array[RigidBody3D] = []
var prize_data: Array[Dictionary] = []
var saved_prizes: Array = []
var sparkle_particles: GPUParticles3D

var claw_specs: Array[Dictionary] = [
    {"name":"WOOD BASIC", "price":0, "bonus":0.00, "color":CYAN},
    {"name":"STEEL GRIP", "price":120, "bonus":0.05, "color":Color("#9FB4D2")},
    {"name":"MAGNET PRO", "price":240, "bonus":0.10, "color":PURPLE},
    {"name":"ICE GRIP", "price":420, "bonus":0.15, "color":Color("#72F5FF")},
    {"name":"RUBY CLAW", "price":650, "bonus":0.20, "color":Color("#FF496F")},
    {"name":"GOLDEN GRIP", "price":900, "bonus":0.25, "color":GOLD},
    {"name":"PLASMA", "price":1250, "bonus":0.30, "color":Color("#65B8FF")},
    {"name":"CYBER TITAN", "price":1700, "bonus":0.35, "color":Color("#28C9A0")},
    {"name":"VOID HUNTER", "price":2400, "bonus":0.42, "color":Color("#A23BFF")},
    {"name":"LEGEND X", "price":3500, "bonus":0.50, "color":Color("#FF8A24")}
]

var upgrade_specs: Array[Dictionary] = [
    {"name":"СИЛА ЗАХВАТА", "base_price":180, "bonus":0.035},
    {"name":"СТАБИЛИЗАТОР", "base_price":220, "bonus":0.025},
    {"name":"ТОЧНОСТЬ", "base_price":260, "bonus":0.030},
    {"name":"УДАЧА", "base_price":300, "bonus":0.020},
    {"name":"БЫСТРЫЙ ПРИВОД", "base_price":340, "bonus":0.18},
    {"name":"УСИЛЕННЫЙ ТРОС", "base_price":380, "bonus":0.025},
    {"name":"АМОРТИЗАТОР", "base_price":420, "bonus":0.030},
    {"name":"СЕРВОМОТОР", "base_price":470, "bonus":0.22},
    {"name":"ПОДСВЕТКА ПРИЗА", "base_price":520, "bonus":0.025},
    {"name":"МАСТЕР-МОДУЛЬ", "base_price":700, "bonus":0.045}
]

var achievement_specs: Array[Dictionary] = [
    {"id":"first_win","name":"ПЕРВАЯ ИГРУШКА","desc":"Достаньте первую игрушку.","kind":"toys","value":1},
    {"id":"toys_5","name":"НАЧАЛО КОЛЛЕКЦИИ","desc":"Достаньте 5 игрушек.","kind":"toys","value":5},
    {"id":"toys_10","name":"ОХОТНИК ЗА ПРИЗАМИ","desc":"Достаньте 10 игрушек.","kind":"toys","value":10},
    {"id":"toys_25","name":"ЗАВОДНОЙ ИГРОК","desc":"Достаньте 25 игрушек.","kind":"toys","value":25},
    {"id":"toys_50","name":"ОПЫТНЫЙ ОПЕРАТОР","desc":"Достаньте 50 игрушек.","kind":"toys","value":50},
    {"id":"toys_100","name":"МАСТЕР ХВАТАЙКИ","desc":"Достаньте 100 игрушек.","kind":"toys","value":100},
    {"id":"toys_250","name":"ПРОФЕССИОНАЛ","desc":"Достаньте 250 игрушек.","kind":"toys","value":250},
    {"id":"toys_500","name":"ЛЕГЕНДА АППАРАТА","desc":"Достаньте 500 игрушек.","kind":"toys","value":500},
    {"id":"games_10","name":"ПЕРВЫЕ 10 ИГР","desc":"Сыграйте 10 раз.","kind":"games","value":10},
    {"id":"games_50","name":"НЕ ОСТАНОВИТЬ","desc":"Сыграйте 50 раз.","kind":"games","value":50},
    {"id":"games_100","name":"СТО ПОПЫТОК","desc":"Сыграйте 100 раз.","kind":"games","value":100},
    {"id":"games_500","name":"МАРАФОН","desc":"Сыграйте 500 раз.","kind":"games","value":500},
    {"id":"common_25","name":"ПРОСТЫЕ ПРИЗЫ","desc":"Получите 25 обычных игрушек.","kind":"rarity","rarity":"ОБЫЧНАЯ","value":25},
    {"id":"rare_10","name":"ОХОТА НА РЕДКИХ","desc":"Получите 10 редких игрушек.","kind":"rarity","rarity":"РЕДКАЯ","value":10},
    {"id":"epic_5","name":"ЭПИЧЕСКИЙ УСПЕХ","desc":"Получите 5 эпических игрушек.","kind":"rarity","rarity":"ЭПИЧЕСКАЯ","value":5},
    {"id":"legend_1","name":"ЛЕГЕНДАРНЫЙ ПРИЗ","desc":"Получите легендарную игрушку.","kind":"rarity","rarity":"ЛЕГЕНДАРНАЯ","value":1},
    {"id":"legend_5","name":"ЛЕГЕНДАРНЫЙ ОХОТНИК","desc":"Получите 5 легендарных игрушек.","kind":"rarity","rarity":"ЛЕГЕНДАРНАЯ","value":5},
    {"id":"collections_1","name":"СОБРАНО!","desc":"Завершите 1 коллекцию.","kind":"collections","value":1},
    {"id":"collections_2","name":"ДВА НАБОРА","desc":"Завершите 2 коллекции.","kind":"collections","value":2},
    {"id":"collections_4","name":"ПОЛОВИНА ПУТИ","desc":"Завершите 4 коллекции.","kind":"collections","value":4},
    {"id":"collections_8","name":"ХРАНИТЕЛЬ ВСЕХ КОЛЛЕКЦИЙ","desc":"Завершите все 8 коллекций.","kind":"collections","value":8},
    {"id":"level_5","name":"НОВИЧОК","desc":"Достигните 5 уровня.","kind":"level","value":5},
    {"id":"level_10","name":"УВЕРЕННЫЙ ИГРОК","desc":"Достигните 10 уровня.","kind":"level","value":10},
    {"id":"level_25","name":"ПРОДВИНУТЫЙ","desc":"Достигните 25 уровня.","kind":"level","value":25},
    {"id":"level_50","name":"ВЫСШАЯ ЛИГА","desc":"Достигните 50 уровня.","kind":"level","value":50},
    {"id":"level_100","name":"СОТЫЙ УРОВЕНЬ","desc":"Достигните 100 уровня.","kind":"level","value":100},
    {"id":"level_250","name":"МАСТЕР 250","desc":"Достигните 250 уровня.","kind":"level","value":250},
    {"id":"level_500","name":"МАСТЕР 500","desc":"Достигните 500 уровня.","kind":"level","value":500},
    {"id":"level_1000","name":"ВЕРШИНА","desc":"Достигните максимального 1000 уровня.","kind":"level","value":1000},
    {"id":"rubles_500","name":"ПЕРВЫЕ НАКОПЛЕНИЯ","desc":"Накопите 500 ₽.","kind":"rubles","value":500},
    {"id":"rubles_1000","name":"КАПИТАЛ","desc":"Накопите 1000 ₽.","kind":"rubles","value":1000},
    {"id":"rubles_5000","name":"БОЛЬШОЙ БАЛАНС","desc":"Накопите 5000 ₽.","kind":"rubles","value":5000},
    {"id":"claws_3","name":"АРСЕНАЛ","desc":"Откройте 3 разные клешни.","kind":"claws","value":3},
    {"id":"claws_6","name":"КОЛЛЕКЦИЯ КЛЕШНЕЙ","desc":"Откройте 6 разных клешней.","kind":"claws","value":6},
    {"id":"claws_10","name":"ПОЛНЫЙ АРСЕНАЛ","desc":"Откройте все 10 клешней.","kind":"claws","value":10},
    {"id":"upgrades_5","name":"ПЕРВАЯ НАСТРОЙКА","desc":"Купите 5 уровней улучшений.","kind":"upgrades","value":5},
    {"id":"upgrades_15","name":"ТЕХНИК","desc":"Купите 15 уровней улучшений.","kind":"upgrades","value":15},
    {"id":"upgrades_30","name":"ИНЖЕНЕР","desc":"Купите 30 уровней улучшений.","kind":"upgrades","value":30},
    {"id":"upgrades_50","name":"МАКСИМАЛЬНАЯ НАСТРОЙКА","desc":"Купите 50 уровней улучшений.","kind":"upgrades","value":50}
]

var toys: Array[Dictionary] = [
    {"name":"Мишка Байт", "collection":"ЛЕСНЫЕ ДРУЗЬЯ", "rarity":"ОБЫЧНАЯ", "weight":42.0, "color":Color("#B86F3E")},
    {"name":"Лисёнок Флэш", "collection":"ЛЕСНЫЕ ДРУЗЬЯ", "rarity":"ОБЫЧНАЯ", "weight":38.0, "color":Color("#FF5A2F")},
    {"name":"Заяц Сноу", "collection":"ЛЕСНЫЕ ДРУЗЬЯ", "rarity":"ОБЫЧНАЯ", "weight":36.0, "color":Color("#8C63E8")},
    {"name":"Панда Пульс", "collection":"ЛЕСНЫЕ ДРУЗЬЯ", "rarity":"РЕДКАЯ", "weight":14.0, "color":Color("#3E526B")},
    {"name":"Утёнок Дак", "collection":"МИЛЫЕ МАЛЫШИ", "rarity":"ОБЫЧНАЯ", "weight":41.0, "color":Color("#F4B72D")},
    {"name":"Кот Пиксель", "collection":"МИЛЫЕ МАЛЫШИ", "rarity":"ОБЫЧНАЯ", "weight":37.0, "color":Color("#D96A9A")},
    {"name":"Щенок Бруно", "collection":"МИЛЫЕ МАЛЫШИ", "rarity":"ОБЫЧНАЯ", "weight":35.0, "color":Color("#6FAF6A")},
    {"name":"Коала Коди", "collection":"МИЛЫЕ МАЛЫШИ", "rarity":"РЕДКАЯ", "weight":12.0, "color":Color("#6D7FA8")},
    {"name":"Лягушка Блип", "collection":"ДЖУНГЛИ", "rarity":"ОБЫЧНАЯ", "weight":34.0, "color":Color("#38B86B")},
    {"name":"Черепашка Тото", "collection":"ДЖУНГЛИ", "rarity":"ОБЫЧНАЯ", "weight":31.0, "color":Color("#4C9B69")},
    {"name":"Обезьянка Джо", "collection":"ДЖУНГЛИ", "rarity":"РЕДКАЯ", "weight":13.0, "color":Color("#B86B4F")},
    {"name":"Тигр Неон", "collection":"ДЖУНГЛИ", "rarity":"ЭПИЧЕСКАЯ", "weight":2.8, "color":Color("#FF7A2F")},
    {"name":"Акула Спарк", "collection":"ОКЕАН", "rarity":"РЕДКАЯ", "weight":11.0, "color":Color("#287BD4")},
    {"name":"Пингвин Айс", "collection":"ОКЕАН", "rarity":"РЕДКАЯ", "weight":10.0, "color":Color("#48B9E8")},
    {"name":"Морской Кот", "collection":"ОКЕАН", "rarity":"ОБЫЧНАЯ", "weight":29.0, "color":Color("#4E9FC8")},
    {"name":"Кит Блу", "collection":"ОКЕАН", "rarity":"ЭПИЧЕСКАЯ", "weight":2.5, "color":Color("#5168E8")},
    {"name":"Космо-Акула", "collection":"КОСМОС", "rarity":"ЭПИЧЕСКАЯ", "weight":3.0, "color":Color("#5C4BEA")},
    {"name":"Галакси-Кот", "collection":"КОСМОС", "rarity":"ЭПИЧЕСКАЯ", "weight":2.1, "color":Color("#B14FE0")},
    {"name":"Астро-Кот", "collection":"КОСМОС", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.12, "color":Color("#7545D8")},
    {"name":"Звёздный Панда", "collection":"КОСМОС", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.06, "color":Color("#FF8A24")},
    {"name":"Дракон Вольт", "collection":"ДРАКОНЫ", "rarity":"ЭПИЧЕСКАЯ", "weight":3.5, "color":Color("#21C879")},
    {"name":"Золотой Дракон", "collection":"ДРАКОНЫ", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.28, "color":Color("#FFC42E")},
    {"name":"Радужный Дракон", "collection":"ДРАКОНЫ", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.10, "color":Color("#FF3FAF")},
    {"name":"Неон-Мантикора", "collection":"ДРАКОНЫ", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.08, "color":Color("#28C9A0")},
    {"name":"Единорог Луна", "collection":"ВОЛШЕБСТВО", "rarity":"ЭПИЧЕСКАЯ", "weight":4.0, "color":Color("#D86BFF")},
    {"name":"Король Единорог", "collection":"ВОЛШЕБСТВО", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.20, "color":Color("#FF4FAE")},
    {"name":"Фея Старлайт", "collection":"ВОЛШЕБСТВО", "rarity":"РЕДКАЯ", "weight":7.0, "color":Color("#9A5BE8")},
    {"name":"Розовый Грифон", "collection":"ВОЛШЕБСТВО", "rarity":"ЭПИЧЕСКАЯ", "weight":1.8, "color":Color("#FF5D9E")},
    {"name":"Робо-Панда", "collection":"КИБЕР", "rarity":"ЭПИЧЕСКАЯ", "weight":2.4, "color":Color("#248BAA")},
    {"name":"Кибер-Кот", "collection":"КИБЕР", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.60, "color":GOLD},
    {"name":"Меха-Мишка", "collection":"КИБЕР", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.16, "color":Color("#6BE7FF")},
    {"name":"CLAW MASTER", "collection":"КИБЕР", "rarity":"ЛЕГЕНДАРНАЯ", "weight":0.025, "color":Color("#F39C32")}
]

func get_collection_names() -> Array[String]:
    var result: Array[String] = []
    for toy in toys:
        var name := String(toy.get("collection", ""))
        if name != "" and not result.has(name): result.append(name)
    if not result.is_empty(): return result
    return [
        "ЛЕСНЫЕ ДРУЗЬЯ", "МИЛЫЕ МАЛЫШИ", "ДЖУНГЛИ", "ОКЕАН",
        "КОСМОС", "ДРАКОНЫ", "ВОЛШЕБСТВО", "КИБЕР",
        "ДИНОЗАВРЫ", "СУПЕРГЕРОИ", "СЛАДКИЙ МИР", "ПИРАТЫ",
        "РОБОТЫ", "ФАНТАСТИКА", "СПОРТ", "МИР МОНСТРОВ"
    ]

func add_extended_collections() -> void:
    var extra_toys: Array[Dictionary] = [
        # ДИНОЗАВРЫ
        {"name":"Рекс Рокки","collection":"ДИНОЗАВРЫ","rarity":"ОБЫЧНАЯ","weight":30.0,"color":Color("#6FA45A")},
        {"name":"Трицератопс Три","collection":"ДИНОЗАВРЫ","rarity":"ОБЫЧНАЯ","weight":28.0,"color":Color("#8C6A4A")},
        {"name":"Раптор Рэй","collection":"ДИНОЗАВРЫ","rarity":"РЕДКАЯ","weight":15.0,"color":Color("#E27A42")},
        {"name":"Бронто Бум","collection":"ДИНОЗАВРЫ","rarity":"РЕДКАЯ","weight":11.0,"color":Color("#4D9A87")},
        {"name":"Мега-Тиран","collection":"ДИНОЗАВРЫ","rarity":"ЭПИЧЕСКАЯ","weight":2.2,"color":Color("#B53D58")},
        # СУПЕРГЕРОИ
        {"name":"Капитан Плюш","collection":"СУПЕРГЕРОИ","rarity":"ОБЫЧНАЯ","weight":29.0,"color":Color("#356DDB")},
        {"name":"Молния Макс","collection":"СУПЕРГЕРОИ","rarity":"ОБЫЧНАЯ","weight":27.0,"color":Color("#F2C23E")},
        {"name":"Ночной Ниндзя","collection":"СУПЕРГЕРОИ","rarity":"РЕДКАЯ","weight":13.0,"color":Color("#4B4D70")},
        {"name":"Робо-Герой","collection":"СУПЕРГЕРОИ","rarity":"ЭПИЧЕСКАЯ","weight":3.0,"color":Color("#45B7C8")},
        {"name":"Золотой Герой","collection":"СУПЕРГЕРОИ","rarity":"ЛЕГЕНДАРНАЯ","weight":0.22,"color":Color("#F5B93D")},
        # СЛАДКИЙ МИР
        {"name":"Пончик Пинки","collection":"СЛАДКИЙ МИР","rarity":"ОБЫЧНАЯ","weight":32.0,"color":Color("#F38DB4")},
        {"name":"Маршмеллоу Мими","collection":"СЛАДКИЙ МИР","rarity":"ОБЫЧНАЯ","weight":30.0,"color":Color("#F2E5D5")},
        {"name":"Кекс Куки","collection":"СЛАДКИЙ МИР","rarity":"ОБЫЧНАЯ","weight":28.0,"color":Color("#B97852")},
        {"name":"Леденец Лаки","collection":"СЛАДКИЙ МИР","rarity":"РЕДКАЯ","weight":12.0,"color":Color("#68C9E8")},
        {"name":"Шоколадный Король","collection":"СЛАДКИЙ МИР","rarity":"ЭПИЧЕСКАЯ","weight":2.0,"color":Color("#6E3F32")},
        # ПИРАТЫ
        {"name":"Капитан Бакс","collection":"ПИРАТЫ","rarity":"ОБЫЧНАЯ","weight":30.0,"color":Color("#8B6548")},
        {"name":"Попугай Пират","collection":"ПИРАТЫ","rarity":"ОБЫЧНАЯ","weight":27.0,"color":Color("#E44C55")},
        {"name":"Кракен Крош","collection":"ПИРАТЫ","rarity":"РЕДКАЯ","weight":14.0,"color":Color("#7557B5")},
        {"name":"Призрак Палубы","collection":"ПИРАТЫ","rarity":"ЭПИЧЕСКАЯ","weight":2.5,"color":Color("#B9D9D1")},
        {"name":"Золотой Капитан","collection":"ПИРАТЫ","rarity":"ЛЕГЕНДАРНАЯ","weight":0.18,"color":Color("#E8B93D")},
        # РОБОТЫ
        {"name":"Бот Биби","collection":"РОБОТЫ","rarity":"ОБЫЧНАЯ","weight":31.0,"color":Color("#6D8299")},
        {"name":"Дроид Дэн","collection":"РОБОТЫ","rarity":"ОБЫЧНАЯ","weight":28.0,"color":Color("#4FA5B7")},
        {"name":"Меха-Лис","collection":"РОБОТЫ","rarity":"РЕДКАЯ","weight":13.0,"color":Color("#D46D45")},
        {"name":"Кибер-Гигант","collection":"РОБОТЫ","rarity":"ЭПИЧЕСКАЯ","weight":2.7,"color":Color("#4C5DE7")},
        {"name":"Омега-9000","collection":"РОБОТЫ","rarity":"ЛЕГЕНДАРНАЯ","weight":0.14,"color":Color("#B7C8D8")},
        # ФАНТАСТИКА
        {"name":"Дракончик Эмбер","collection":"ФАНТАСТИКА","rarity":"ОБЫЧНАЯ","weight":25.0,"color":Color("#E36A43")},
        {"name":"Грифон Грей","collection":"ФАНТАСТИКА","rarity":"РЕДКАЯ","weight":12.0,"color":Color("#8B78C9")},
        {"name":"Феникс Файр","collection":"ФАНТАСТИКА","rarity":"ЭПИЧЕСКАЯ","weight":3.0,"color":Color("#EF6B38")},
        {"name":"Лунный Дух","collection":"ФАНТАСТИКА","rarity":"ЭПИЧЕСКАЯ","weight":1.8,"color":Color("#8AB5F2")},
        {"name":"Древний Дракон","collection":"ФАНТАСТИКА","rarity":"ЛЕГЕНДАРНАЯ","weight":0.08,"color":Color("#D7A93D")},
        # СПОРТ
        {"name":"Футбольный Боб","collection":"СПОРТ","rarity":"ОБЫЧНАЯ","weight":33.0,"color":Color("#F4F4F0")},
        {"name":"Баскет-Би","collection":"СПОРТ","rarity":"ОБЫЧНАЯ","weight":31.0,"color":Color("#E98537")},
        {"name":"Хоккейный Хаски","collection":"СПОРТ","rarity":"РЕДКАЯ","weight":13.0,"color":Color("#6A89C8")},
        {"name":"Чемпион","collection":"СПОРТ","rarity":"ЭПИЧЕСКАЯ","weight":2.4,"color":Color("#D3A33C")},
        {"name":"Олимпийский Легендар","collection":"СПОРТ","rarity":"ЛЕГЕНДАРНАЯ","weight":0.10,"color":Color("#7BC6A8")},
        # МИР МОНСТРОВ
        {"name":"Монстрик Мио","collection":"МИР МОНСТРОВ","rarity":"ОБЫЧНАЯ","weight":30.0,"color":Color("#63B76D")},
        {"name":"Пухлый Буба","collection":"МИР МОНСТРОВ","rarity":"ОБЫЧНАЯ","weight":28.0,"color":Color("#7D63B8")},
        {"name":"Зубастик Зик","collection":"МИР МОНСТРОВ","rarity":"РЕДКАЯ","weight":13.0,"color":Color("#B84F62")},
        {"name":"Теневой Монстр","collection":"МИР МОНСТРОВ","rarity":"ЭПИЧЕСКАЯ","weight":2.3,"color":Color("#4B4A67")},
        {"name":"Король Монстров","collection":"МИР МОНСТРОВ","rarity":"ЛЕГЕНДАРНАЯ","weight":0.07,"color":Color("#B7A143")}
    ]
    for toy in extra_toys:
        toys.append(toy)

func add_progressive_achievements() -> void:
    # Многоуровневые достижения: каждый следующий уровень требует больше предыдущего.
    var tiers := [
        {"kind":"toys","prefix":"toy_master","name":"ОХОТНИК","desc":"Достаньте %d игрушек.","values":[75,150,300,600,1200,2500,5000,10000]},
        {"kind":"games","prefix":"game_master","name":"МАРАФОНЕЦ","desc":"Сыграйте %d раз.","values":[1000,2500,5000,10000,20000,40000,75000,150000]},
        {"kind":"collections","prefix":"collection_master","name":"КОЛЛЕКЦИОНЕР","desc":"Завершите %d коллекций.","values":[10,12,14,16]},
        {"kind":"level","prefix":"level_master","name":"УРОВЕНЬ","desc":"Достигните %d уровня.","values":[150,300,450,600,750,850,925,975]},
        {"kind":"rarity","rarity":"РЕДКАЯ","prefix":"rare_master","name":"ОХОТНИК ЗА РЕДКИМИ","desc":"Получите %d редких игрушек.","values":[20,50,100,250,500,1000]},
        {"kind":"rarity","rarity":"ЭПИЧЕСКАЯ","prefix":"epic_master","name":"ЭПИЧЕСКИЙ КОЛЛЕКЦИОНЕР","desc":"Получите %d эпических игрушек.","values":[10,25,50,100,250,500]},
        {"kind":"rarity","rarity":"ЛЕГЕНДАРНАЯ","prefix":"legend_master","name":"ЛЕГЕНДАРНЫЙ ОХОТНИК","desc":"Получите %d легендарных игрушек.","values":[2,5,10,25,50,100]},
        {"kind":"upgrades","prefix":"upgrade_master","name":"ИНЖЕНЕР","desc":"Купите %d уровней улучшений.","values":[60,80,100,125,150,200]}
    ]
    for tier in tiers:
        var values: Array = tier["values"]
        for i in range(values.size()):
            var value: int = int(values[i])
            var id := "%s_%d" % [String(tier["prefix"]), i + 1]
            if _achievement_exists(id):
                continue
            var spec: Dictionary = {"id":id,"name":"%s %d" % [String(tier["name"]), i + 1],"desc":String(tier["desc"]) % value,"kind":String(tier["kind"]),"value":value}
            if tier.has("rarity"): spec["rarity"] = String(tier["rarity"])
            achievement_specs.append(spec)


func add_diverse_achievements() -> void:
    # Дополнительные достижения разных типов: серии, сундуки, мастерская,
    # косметика, задания, ключи, XP и особые захваты. Все цели независимы.
    var extra := [
        {"id":"streak_3","name":"ПЕРВАЯ СЕРИЯ","desc":"Выиграйте 3 игры подряд.","kind":"best_streak","value":3},
        {"id":"streak_7","name":"НЕ ОСТАНОВИТЬ","desc":"Выиграйте 7 игр подряд.","kind":"best_streak","value":7},
        {"id":"streak_15","name":"ЖЕЛЕЗНАЯ СЕРИЯ","desc":"Выиграйте 15 игр подряд.","kind":"best_streak","value":15},
        {"id":"streak_30","name":"МАШИНА ПОБЕД","desc":"Выиграйте 30 игр подряд.","kind":"best_streak","value":30},
        {"id":"streak_50","name":"НЕПОБЕДИМЫЙ","desc":"Выиграйте 50 игр подряд.","kind":"best_streak","value":50},
        {"id":"perfect_5","name":"ЧИСТЫЙ ХВАТ","desc":"Сделайте 5 идеальных захватов.","kind":"perfect","value":5},
        {"id":"perfect_25","name":"ЮВЕЛИР","desc":"Сделайте 25 идеальных захватов.","kind":"perfect","value":25},
        {"id":"perfect_100","name":"МАСТЕР ТОЧНОСТИ","desc":"Сделайте 100 идеальных захватов.","kind":"perfect","value":100},
        {"id":"heavy_10","name":"СИЛАЧ","desc":"Поймайте 10 тяжёлых игрушек.","kind":"heavy","value":10},
        {"id":"heavy_50","name":"ГРУЗЧИК","desc":"Поймайте 50 тяжёлых игрушек.","kind":"heavy","value":50},
        {"id":"heavy_200","name":"ТЯЖЁЛАЯ АРТИЛЛЕРИЯ","desc":"Поймайте 200 тяжёлых игрушек.","kind":"heavy","value":200},
        {"id":"lucky_5","name":"СЧАСТЛИВЧИК","desc":"Поймайте 5 счастливых игрушек.","kind":"lucky","value":5},
        {"id":"lucky_25","name":"ФАВОРИТ УДАЧИ","desc":"Поймайте 25 счастливых игрушек.","kind":"lucky","value":25},
        {"id":"lucky_100","name":"ЗОЛОТАЯ УДАЧА","desc":"Поймайте 100 счастливых игрушек.","kind":"lucky","value":100},
        {"id":"xp_1000","name":"ПЕРВЫЙ ТЫСЯЧНИК","desc":"Заработайте 1000 XP.","kind":"xp","value":1000},
        {"id":"xp_10000","name":"XP-МАНЬЯК","desc":"Заработайте 10 000 XP.","kind":"xp","value":10000},
        {"id":"xp_100000","name":"ЛЕГЕНДА ОПЫТА","desc":"Заработайте 100 000 XP.","kind":"xp","value":100000},
        {"id":"reward_100","name":"КРУПНЫЙ УЛОВ","desc":"Получите награду 100 ₽ или больше за игру.","kind":"max_reward","value":100},
        {"id":"reward_500","name":"БОЛЬШОЙ УЛОВ","desc":"Получите награду 500 ₽ или больше за игру.","kind":"max_reward","value":500},
        {"id":"reward_1000","name":"ДЖЕКПОТ","desc":"Получите награду 1000 ₽ или больше за игру.","kind":"max_reward","value":1000},
        {"id":"chests_1","name":"ПЕРВЫЙ СУНДУК","desc":"Откройте 1 сундук.","kind":"chests_opened","value":1},
        {"id":"chests_10","name":"ОТКРЫВАТЕЛЬ","desc":"Откройте 10 сундуков.","kind":"chests_opened","value":10},
        {"id":"chests_50","name":"ОХОТНИК ЗА СУНДУКАМИ","desc":"Откройте 50 сундуков.","kind":"chests_opened","value":50},
        {"id":"chests_250","name":"СОКРОВИЩНИК","desc":"Откройте 250 сундуков.","kind":"chests_opened","value":250},
        {"id":"keys_25","name":"СВЯЗКА КЛЮЧЕЙ","desc":"Получите 25 ключей за всё время.","kind":"keys_earned","value":25},
        {"id":"keys_100","name":"ХРАНИТЕЛЬ КЛЮЧЕЙ","desc":"Получите 100 ключей за всё время.","kind":"keys_earned","value":100},
        {"id":"exclusive_1","name":"СЕКРЕТНЫЙ ПРИЗ","desc":"Получите 1 эксклюзивную награду из сундука.","kind":"exclusive","value":1},
        {"id":"exclusive_10","name":"ОХОТНИК ЗА ЭКСКЛЮЗИВАМИ","desc":"Получите 10 эксклюзивных наград.","kind":"exclusive","value":10},
        {"id":"workshop_5","name":"ЮНЫЙ МЕХАНИК","desc":"Достигните 5 уровня мастерской.","kind":"workshop_level","value":5},
        {"id":"workshop_10","name":"ИНЖЕНЕР-МЕХАНИК","desc":"Достигните 10 уровня мастерской.","kind":"workshop_level","value":10},
        {"id":"workshop_20","name":"ГЛАВНЫЙ ИНЖЕНЕР","desc":"Достигните 20 уровня мастерской.","kind":"workshop_level","value":20},
        {"id":"parts_100","name":"ЗАПАС ДЕТАЛЕЙ","desc":"Накопите 100 деталей одновременно.","kind":"parts","value":100},
        {"id":"parts_500","name":"СКЛАД ЗАПЧАСТЕЙ","desc":"Накопите 500 деталей одновременно.","kind":"parts","value":500},
        {"id":"calibration_5","name":"ИДЕАЛЬНАЯ КАЛИБРОВКА","desc":"Прокачайте калибровку до 5 уровня.","kind":"calibration","value":5},
        {"id":"overclock_1","name":"ТУРБО-РЕЖИМ","desc":"Используйте оверклок хотя бы один раз.","kind":"overclock","value":1},
        {"id":"claw_skins_3","name":"СТИЛЬНАЯ КЛЕШНЯ","desc":"Откройте 3 скина клешни.","kind":"claw_skins","value":3},
        {"id":"claw_skins_8","name":"КОЛЛЕКЦИОНЕР КЛЕШНЕЙ","desc":"Откройте 8 скинов клешни.","kind":"claw_skins","value":8},
        {"id":"toy_skins_3","name":"МОДНИК","desc":"Откройте 3 скина игрушек.","kind":"toy_skins","value":3},
        {"id":"machine_skins_3","name":"НОВЫЙ КОРПУС","desc":"Откройте 3 скина аппарата.","kind":"machine_skins","value":3},
        {"id":"login_3","name":"ТРИ ДНЯ ПОДРЯД","desc":"Продержите серию входов 3 дня.","kind":"login_streak","value":3},
        {"id":"login_7","name":"НЕДЕЛЯ В ИГРЕ","desc":"Продержите серию входов 7 дней.","kind":"login_streak","value":7},
        {"id":"login_30","name":"МЕСЯЦ В ИГРЕ","desc":"Продержите серию входов 30 дней.","kind":"login_streak","value":30},
        {"id":"daily_10","name":"ЕЖЕДНЕВНЫЙ ГЕРОЙ","desc":"Выполните 10 ежедневных миссий.","kind":"daily_claims","value":10},
        {"id":"weekly_10","name":"НЕДЕЛЬНЫЙ МАРАФОН","desc":"Закройте 10 недельных миссий.","kind":"weekly_claims","value":10},
        {"id":"referrals_1","name":"ДРУГ ПРИВЁЛ ДРУГА","desc":"Пригласите 1 друга.","kind":"referrals","value":1},
        {"id":"referrals_10","name":"КОМАНДА","desc":"Пригласите 10 друзей.","kind":"referrals","value":10}
    ]
    for spec in extra:
        if not _achievement_exists(String(spec["id"])):
            achievement_specs.append(spec)

func _achievement_exists(id: String) -> bool:
    for spec in achievement_specs:
        if String(spec.get("id", "")) == id:
            return true
    return false

func _ready() -> void:
    # Сначала создаём собственный загрузочный экран и отдаём движку кадр.
    # Системная картинка splash отключена: Android показывает только свой
    # короткий системный фон, после чего Main сразу показывает ЕДИНСТВЕННУЮ
    # миниатюру внутри основного загрузочного экрана. Тяжёлая инициализация
    # начинается только после первого кадра.
    randomize()
    startup_splash = get_node_or_null("StartupSplash") as CanvasLayer
    # When launched through Bootstrap, reuse its single loading screen.
    # This prevents a second loading/splash layer from being created while the
    # heavy Main scene is being prepared.
    var bootstrap_loading = get_parent().get_node_or_null("LoadingScreen") if get_parent() else null
    if bootstrap_loading and is_instance_valid(bootstrap_loading):
        loading_screen = bootstrap_loading as Control
        loading_status = loading_screen.get_node_or_null("LoadingStatus") as Label
        loading_progress = loading_screen.get_node_or_null("LoadingProgress") as ProgressBar
        loading_percent = loading_screen.get_node_or_null("LoadingPercent") as Label
        loading_stage = loading_screen.get_node_or_null("LoadingStage") as Label
        loading_tip = loading_screen.get_node_or_null("LoadingTip") as Label
        loading_ring = loading_screen.get_node_or_null("LoadingRing") as Panel
    else:
        create_loading_screen()
    if startup_splash and is_instance_valid(startup_splash):
        startup_splash.visible = false
    await get_tree().process_frame

    add_extended_collections()
    add_progressive_achievements()
    add_diverse_achievements()
    owned_claw_skins.resize(claw_skin_specs.size())
    owned_toy_skins.resize(toy_skin_specs.size())
    owned_machine_skins.resize(machine_skin_specs.size())
    for i in range(owned_claw_skins.size()): owned_claw_skins[i] = (i == 0)
    for i in range(owned_toy_skins.size()): owned_toy_skins[i] = (i == 0)
    for i in range(owned_machine_skins.size()): owned_machine_skins[i] = (i == 0)
    load_save()
    ensure_player_id()
    remote_http = HTTPRequest.new()
    remote_http.name = "RemoteGameHTTP"
    remote_http.timeout = 3.0
    add_child(remote_http)
    remote_http.request_completed.connect(_on_remote_http_completed)

    # Separate HTTP channels for time-critical gameplay and cosmetic selection.
    # A regular background sync must never delay a claw drop or skin installation.
    claw_http = HTTPRequest.new()
    claw_http.name = "ClawActionHTTP"
    claw_http.timeout = 1.5
    add_child(claw_http)
    claw_http.request_completed.connect(_on_claw_http_completed)
    cosmetic_http = HTTPRequest.new()
    cosmetic_http.name = "CosmeticActionHTTP"
    cosmetic_http.timeout = 2.0
    add_child(cosmetic_http)
    cosmetic_http.request_completed.connect(_on_cosmetic_http_completed)
    # Android permission responses are delivered by MainLoop/SceneTree.
    # Without this connection, the first notification test could remain
    # waiting forever after Android shows the permission dialog.
    if get_tree().has_signal("on_request_permissions_result"):
        var permission_callable := Callable(self, "_on_notification_permission_result")
        if not get_tree().is_connected("on_request_permissions_result", permission_callable):
            get_tree().connect("on_request_permissions_result", permission_callable)
    update_return_bonus_state()
    # Сеть и Android-уведомления никогда не должны быть частью первого кадра.
    call_deferred("setup_android_notifications")
    call_deferred("register_player_remote")
    call_deferred("sync_remote_config")
    call_deferred("initialize_game_async")
    call_deferred("build_upgrade_sound_system")

func _is_android_runtime_available() -> bool:
    return OS.has_feature("android") and not Engine.is_editor_hint() and Engine.has_singleton("AndroidRuntime")

func _get_background_notification_receiver() -> Variant:
    if not _is_android_runtime_available():
        return null
    # The Java receiver is compiled into the Gradle Android template by the
    # editor plugin. Return its JavaClass so static schedule/cancel/postNow
    # methods can be called even when the Godot process is later stopped.
    var receiver_class = JavaClassWrapper.wrap(notification_receiver_class)
    var java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        print("Background notification receiver load exception: ", java_exception)
        return null
    return receiver_class

func _ensure_android_notification_channel() -> bool:
    if not _is_android_runtime_available():
        return false
    var android_runtime = Engine.get_singleton("AndroidRuntime")
    var context = android_runtime.getApplicationContext()
    if not context:
        context = android_runtime.getActivity()
    if not context:
        return false
    var NotificationChannel = JavaClassWrapper.wrap("android.app.NotificationChannel")
    var channel: Variant = NotificationChannel.NotificationChannel(notification_channel_id, "Хватайка", 3)
    channel.setDescription("Полезные уведомления игры: ежедневные награды и события")
    var manager = context.getSystemService("notification")
    if not manager:
        return false
    manager.createNotificationChannel(channel)
    return true

func _android_notification_permission_granted() -> bool:
    if not OS.has_feature("android"):
        return false
    var permission := "android.permission.POST_NOTIFICATIONS"
    var granted := OS.get_granted_permissions()
    return granted.has(permission)

func _request_android_notification_permission() -> bool:
    if not OS.has_feature("android"):
        return false
    var permission := "android.permission.POST_NOTIFICATIONS"
    if _android_notification_permission_granted():
        notification_permission_waiting = false
        return true
    notification_permission_waiting = true
    current_result = "РАЗРЕШЕНИЕ НА УВЕДОМЛЕНИЯ ЗАПРОШЕНО"
    OS.request_permission(permission)
    return false

func _on_notification_permission_result(permission: String, granted: bool) -> void:
    if permission != "android.permission.POST_NOTIFICATIONS":
        return
    notification_permission_waiting = false
    if granted:
        current_result = "УВЕДОМЛЕНИЯ РАЗРЕШЕНЫ"
        if notification_pending_test:
            notification_pending_test = false
            call_deferred("_send_pending_test_notification")
        elif notifications_on:
            call_deferred("schedule_background_notifications")
    else:
        notification_pending_test = false
        current_result = "УВЕДОМЛЕНИЯ ЗАПРЕЩЕНЫ В НАСТРОЙКАХ ANDROID"

func _send_pending_test_notification() -> void:
    var title := "🎁 Хватайка"
    var message := "ТЕСТ: уведомления работают. Это сообщение должно появиться в шторке Android."
    var sent_native := false
    if _is_android_runtime_available():
        var receiver = _get_background_notification_receiver()
        var context = Engine.get_singleton("AndroidRuntime").getApplicationContext()
        if receiver != null and context != null:
            receiver.postNow(context, title, message, 9901)
            var java_exception = JavaClassWrapper.get_exception()
            if java_exception == null:
                sent_native = true
                # Backup alarm: if Android delays/interrupts the immediate
                # post, the same test notification is scheduled a moment later.
                receiver.schedule(context, Time.get_unix_time_from_system() * 1000 + 2500, 9901, title, message, false)
                java_exception = JavaClassWrapper.get_exception()
    if not sent_native:
        notify_phone(title, message, true)
        if current_result.find("ОШИБКА") >= 0 or current_result.find("НЕ") >= 0:
            return
    current_result = "ТЕСТОВОЕ УВЕДОМЛЕНИЕ ОТПРАВЛЕНО"

func test_game_notification() -> void:
    # The test button must work immediately and must not depend on the game
    # staying alive. First make sure Android has granted notification access.
    if not OS.has_feature("android"):
        current_result = "УВЕДОМЛЕНИЯ ДОСТУПНЫ ТОЛЬКО НА ANDROID"
        return
    _ensure_android_notification_channel()
    if not _android_notification_permission_granted():
        notification_pending_test = true
        current_result = "РАЗРЕШИТЕ УВЕДОМЛЕНИЯ — ТЕСТ ОТПРАВИТСЯ АВТОМАТИЧЕСКИ"
        _request_android_notification_permission()
        return
    _send_pending_test_notification()


func setup_android_notifications() -> void:
    if not OS.has_feature("android"):
        return
    _ensure_android_notification_channel()
    if not _android_notification_permission_granted():
        _request_android_notification_permission()
        return
    if notifications_on:
        # Foreground notifications work through AndroidRuntime + NotificationManager.
        # Background scheduling is kept separately and requires the optional receiver.
        schedule_background_notifications()
    else:
        cancel_background_notifications()

func notify_phone(title: String, message: String, force: bool = false) -> void:
    if (not notifications_on and not force) or not OS.has_feature("android"):
        return
    if not _ensure_android_notification_channel():
        current_result = "НЕ УДАЛОСЬ СОЗДАТЬ КАНАЛ УВЕДОМЛЕНИЙ"
        return
    if not _android_notification_permission_granted():
        current_result = "РАЗРЕШЕНИЕ НА УВЕДОМЛЕНИЯ НЕ ВЫДАНО"
        _request_android_notification_permission()
        return
    if not Engine.has_singleton("AndroidRuntime"):
        current_result = "ANDROIDRUNTIME НЕДОСТУПЕН В ЭТОЙ СБОРКЕ"
        return

    var android_runtime = Engine.get_singleton("AndroidRuntime")
    var context = android_runtime.getApplicationContext()
    if not context:
        context = android_runtime.getActivity()
    if not context:
        current_result = "НЕ УДАЛОСЬ ПОЛУЧИТЬ ANDROID CONTEXT"
        return

    var manager = context.getSystemService("notification")
    if not manager:
        current_result = "ANDROID NOTIFICATION MANAGER НЕДОСТУПЕН"
        return

    # Android 13+: verify that the OS-level notification switch is actually enabled.
    var enabled = manager.areNotificationsEnabled()
    var java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        print("Notification permission check exception: ", java_exception)
    elif not enabled:
        current_result = "УВЕДОМЛЕНИЯ ОТКЛЮЧЕНЫ В ANDROID НА УРОВНЕ ПРИЛОЖЕНИЯ"
        return

    var Notification = JavaClassWrapper.wrap("android.app.Notification")
    var builder: Variant = Notification.Builder(context, notification_channel_id)
    var Drawable = JavaClassWrapper.wrap("android.R$drawable")
    builder.setSmallIcon(int(Drawable.ic_dialog_info))
    var resources = context.getResources()
    var large_id = int(resources.getIdentifier("khvataika_notification", "drawable", context.getPackageName()))
    if large_id != 0:
        var BitmapFactory = JavaClassWrapper.wrap("android.graphics.BitmapFactory")
        var large_bitmap = BitmapFactory.decodeResource(resources, large_id)
        if large_bitmap:
            builder.setLargeIcon(large_bitmap)
    java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        current_result = "ОШИБКА ИКОНКИ УВЕДОМЛЕНИЯ"
        print("Android notification icon exception: ", java_exception)
        return
    builder.setContentTitle(title)
    builder.setContentText(message)
    var BigTextStyle = JavaClassWrapper.wrap("android.app.Notification$BigTextStyle")
    var style = BigTextStyle.BigTextStyle()
    style.bigText(message)
    builder.setStyle(style)
    builder.setAutoCancel(true)
    builder.setCategory("game")
    builder.setPriority(0)
    java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        current_result = "ОШИБКА СОЗДАНИЯ УВЕДОМЛЕНИЯ"
        print("Android notification builder exception: ", java_exception)
        return

    var built_notification = builder.build()
    java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        current_result = "ОШИБКА СБОРКИ УВЕДОМЛЕНИЯ"
        print("Android notification build exception: ", java_exception)
        return

    manager.notify(int(notification_next_id), built_notification)
    java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        current_result = "ОШИБКА ОТПРАВКИ УВЕДОМЛЕНИЯ"
        print("Android notification notify exception: ", java_exception)
        return

    current_result = "ТЕСТОВОЕ УВЕДОМЛЕНИЕ ОТПРАВЛЕНО" if force else "УВЕДОМЛЕНИЕ ОТПРАВЛЕНО"
    notification_next_id += 1

func _next_daily_notification_timestamp(hour: int, minute: int) -> int:
    var now := Time.get_datetime_dict_from_system()
    var target := Time.get_unix_time_from_datetime_dict({
        "year": int(now.year), "month": int(now.month), "day": int(now.day),
        "hour": hour, "minute": minute, "second": 0
    })
    if target <= Time.get_unix_time_from_system():
        target += 86400
    return int(target * 1000.0)

func _schedule_background_notification(id: int, timestamp_ms: int, title: String, message: String, daily: bool) -> void:
    if not notifications_on or not _is_android_runtime_available():
        return
    var receiver = _get_background_notification_receiver()
    if receiver == null:
        current_result = "ФОНОВЫЕ УВЕДОМЛЕНИЯ НЕ СОБРАНЫ В APK"
        return
    var context = Engine.get_singleton("AndroidRuntime").getApplicationContext()
    if not context:
        current_result = "ANDROID CONTEXT НЕДОСТУПЕН ДЛЯ УВЕДОМЛЕНИЙ"
        return
    receiver.schedule(context, timestamp_ms, id, title, message, daily)
    var java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        print("Background notification schedule exception: ", java_exception)
        current_result = "ОШИБКА ПЛАНИРОВАНИЯ УВЕДОМЛЕНИЯ"

func schedule_background_notifications() -> void:
    if not _is_android_runtime_available():
        return
    cancel_background_notifications()
    if not notifications_on:
        return
    if notify_rewards_on:
        _schedule_background_notification(1101, _next_daily_notification_timestamp(int(online_notification_hours.get("rewards", 12)), 0), "🎁 Ежедневная награда", "Твой ежедневный приз уже ждёт в «Хватайке»!", true)
    if notify_streak_on:
        _schedule_background_notification(1102, _next_daily_notification_timestamp(int(online_notification_hours.get("streak", 20)), 0), "🔥 Серия входов", "Зайди в «Хватайку», чтобы не потерять серию!", true)
    if notify_events_on and active_event_end_unix > int(Time.get_unix_time_from_system()) + 3600:
        var event_reminder := active_event_end_unix - 3 * 3600
        if event_reminder > int(Time.get_unix_time_from_system()):
            _schedule_background_notification(1103, event_reminder * 1000, "🎪 Событие скоро закончится", "%s: осталось около 3 часов!" % active_event_name, false)
    if notify_workshop_on and workshop_job_active and workshop_job_end_unix > int(Time.get_unix_time_from_system()):
        _schedule_background_notification(1104, workshop_job_end_unix * 1000, "🔧 Мастерская готова", "%s завершена. Забери инженерную награду!" % workshop_job_name, false)
    if notify_chests_on and chest_keys > 0:
        _schedule_background_notification(1105, _next_daily_notification_timestamp(int(online_notification_hours.get("chests", 18)), 0), "📦 Сундук ждёт", "У тебя есть ключи и сундуки — загляни в игру!", true)
    if return_bonus_available:
        _schedule_background_notification(1106, _next_daily_notification_timestamp(11, 0), "🎁 Бонус за возвращение", "Ты давно не заходил. Забери увеличенный бонус за возвращение!", true)

func cancel_background_notifications() -> void:
    if not _is_android_runtime_available():
        return
    var receiver = _get_background_notification_receiver()
    if receiver == null:
        return
    var context = Engine.get_singleton("AndroidRuntime").getApplicationContext()
    if not context:
        return
    for notification_id in [1101, 1102, 1103, 1104, 1105, 1106]:
        receiver.cancel(context, notification_id)
    var java_exception = JavaClassWrapper.get_exception()
    if java_exception != null:
        print("Background notification cancel exception: ", java_exception)

func notify_daily_bonus_if_available() -> void:
    if not notifications_on or not notify_rewards_on:
        return
    var today := Time.get_date_string_from_system()
    if last_login_claim_date != today:
        notify_phone("🎁 Хватайка", "Ежедневный приз уже доступен. Зайди в игру и забери награду!")

func update_return_bonus_state() -> void:
    var now := int(Time.get_unix_time_from_system())
    if last_active_unix <= 0:
        last_active_unix = now
        return_bonus_available = false
    else:
        var gap := now - last_active_unix
        if gap >= 86400:
            return_bonus_days = clampi(int(floor(float(gap) / 86400.0)), 1, online_return_bonus_max_days)
            if not return_bonus_claimed:
                return_bonus_available = true
                return_bonus_amount = online_return_bonus_base + return_bonus_days * online_return_bonus_per_day
    if return_bonus_button and is_instance_valid(return_bonus_button):
        return_bonus_button.visible = return_bonus_available and hud_layer != null and hud_layer.visible

func claim_return_bonus() -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; update_ui(); return
        if _server_action("return_bonus"):
            current_result = "БОНУС ЗА ВОЗВРАЩЕНИЕ ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; update_ui()
        return
    update_return_bonus_state()
    if not return_bonus_available or return_bonus_claimed:
        current_result = "БОНУС ЗА ВОЗВРАЩЕНИЕ ПОКА НЕДОСТУПЕН"
        return
    coins += server_reward_amount(return_bonus_amount)
    return_bonus_claimed = true
    return_bonus_available = false
    if return_bonus_button and is_instance_valid(return_bonus_button):
        return_bonus_button.visible = false
    current_result = "🎁 БОНУС ЗА ВОЗВРАЩЕНИЕ • +%d ₽" % return_bonus_amount
    notify_phone("🎁 Хватайка", "Бонус за возвращение +%d ₽ уже получен!" % return_bonus_amount)
    last_active_unix = int(Time.get_unix_time_from_system())
    save_game()
    refresh_live_systems_panel()
    update_ui()

func start_workshop_job() -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; refresh_workshop_panel(); return
        if _server_action("workshop_job_start", {}):
            current_result = "ОПЕРАЦИЯ ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; refresh_workshop_panel(); update_ui()
        return
    if workshop_job_active:
        current_result = "🔧 ИНЖЕНЕРНАЯ РАБОТА УЖЕ ИДЁТ"
        return
    if workshop_parts < 60:
        current_result = "НУЖНО 60 ДЕТАЛЕЙ ДЛЯ ЗАПУСКА РАБОТЫ"
        refresh_live_systems_panel()
        return
    workshop_parts -= 60
    workshop_job_active = true
    workshop_job_name = "Калибровка узла клешни"
    workshop_job_reward = 110 + workshop_level * 8
    workshop_job_end_unix = int(Time.get_unix_time_from_system()) + 3 * 60
    current_result = "🔧 РАБОТА ЗАПУЩЕНА • 3 МИНУТЫ"
    save_game()
    schedule_background_notifications()
    refresh_workshop_panel()
    refresh_live_systems_panel()

func process_workshop_job() -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; refresh_workshop_panel(); return
        if _server_action("workshop_job_claim", {}):
            current_result = "ОПЕРАЦИЯ ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; refresh_workshop_panel(); update_ui()
        return
    if not workshop_job_active:
        return
    if int(Time.get_unix_time_from_system()) < workshop_job_end_unix:
        return
    workshop_job_active = false
    workshop_parts += workshop_job_reward
    current_result = "🔧 МАСТЕРСКАЯ ЗАВЕРШЕНА • +%d деталей" % workshop_job_reward
    if notify_workshop_on:
        notify_phone("🔧 Мастерская готова", "%s: +%d деталей" % [workshop_job_name, workshop_job_reward])
    workshop_job_name = ""
    workshop_job_reward = 0
    workshop_job_end_unix = 0
    save_game()
    refresh_workshop_panel()
    refresh_live_systems_panel()
    update_ui()

func season_pass_reward(level: int) -> Dictionary:
    var cycle := (level - 1) % 6
    match cycle:
        0: return {"type":"rubles", "value":60 + level * 8, "text":"💰 +%d ₽" % (60 + level * 8)}
        1: return {"type":"keys", "value":1 + int(level / 12), "text":"🔑 +%d ключ" % (1 + int(level / 12))}
        2: return {"type":"parts", "value":30 + level * 4, "text":"⚙ +%d деталей" % (30 + level * 4)}
        3: return {"type":"chest", "value":1, "text":"📦 +1 обычный сундук"}
        4: return {"type":"mixed", "value":1, "text":"💰 +%d ₽  •  🔑 +1 ключ" % (70 + level * 6)}
        _: return {"type":"parts_rubles", "value":1, "text":"⚙ +%d деталей  •  💰 +%d ₽" % [45 + level * 3, 50 + level * 5]}

func grant_season_pass_reward(level: int) -> String:
    var reward := season_pass_reward(level)
    var reward_type := String(reward.get("type", "rubles"))
    var value := int(reward.get("value", 0))
    match reward_type:
        "rubles":
            coins += server_reward_amount(value)
        "keys":
            chest_keys += value
            total_keys_earned += value
        "parts":
            workshop_parts += value
        "chest":
            chest_inventory["common"] = int(chest_inventory.get("common", 0)) + value
        "mixed":
            coins += server_reward_amount(70 + level * 6)
            chest_keys += 1
            total_keys_earned += 1
        "parts_rubles":
            workshop_parts += 45 + level * 3
            coins += server_reward_amount(50 + level * 5)
    if level % 5 == 0:
        chest_keys += 1
        total_keys_earned += 1
        return String(reward.get("text", "Награда")) + "  •  🎁 БОНУС +1 КЛЮЧ"
    return String(reward.get("text", "Награда"))

func add_season_pass_xp(amount: int) -> void:
    if amount <= 0 or season_pass_level >= SEASON_PASS_MAX_LEVEL:
        return
    season_pass_xp += amount
    while season_pass_xp >= 100 and season_pass_level < SEASON_PASS_MAX_LEVEL:
        season_pass_xp -= 100
        season_pass_level += 1
        var reward_text := grant_season_pass_reward(season_pass_level)
        current_result = "🎟 ПРОПУСК • УРОВЕНЬ %d • %s" % [season_pass_level, reward_text]
        if notifications_on and notify_events_on:
            notify_phone("🎟 Новый уровень пропуска", "Уровень %d: %s" % [season_pass_level, reward_text])
    save_game()
    refresh_season_pass_panel()

func server_reward_amount(value: int) -> int:
    return maxi(0, int(round(float(value) * online_reward_multiplier)))

func ensure_player_id() -> void:
    if player_id != "":
        return
    var seed_text := "%s_%s_%s" % [Time.get_unix_time_from_system(), randi(), OS.get_unique_id()]
    player_id = "%x" % seed_text.hash()
    if player_id.begins_with("-"):
        player_id = player_id.substr(1)
    save_game()

func _normalized_server_url() -> String:
    return server_url.strip_edges().trim_suffix("/")

func _server_ready() -> bool:
    return remote_http != null and _normalized_server_url() != ""

func get_server_game_state() -> Dictionary:
    return {
        "coins": coins, "player_name": player_name, "player_avatar_index": player_avatar_index,
        "bonus_keys": bonus_keys, "engineering_parts": engineering_parts, "chest_inventory": chest_inventory,
        "chest_keys": chest_keys, "chest_exclusive_toys": chest_exclusive_toys, "chest_exclusive_skins": chest_exclusive_skins,
        "chest_exclusive_reward_count": chest_exclusive_reward_count, "total_chests_opened": total_chests_opened,
        "total_keys_earned": total_keys_earned, "workshop_parts": workshop_parts, "workshop_level": workshop_level,
        "workshop_claw_power": workshop_claw_power, "workshop_speed": workshop_speed, "workshop_precision": workshop_precision,
        "workshop_luck": workshop_luck, "workshop_motor": workshop_motor, "workshop_servo": workshop_servo,
        "workshop_cable": workshop_cable, "workshop_damper": workshop_damper, "workshop_cooling": workshop_cooling,
        "workshop_controller": workshop_controller, "workshop_blueprints": workshop_blueprints,
        "workshop_calibration": workshop_calibration, "workshop_overclock": workshop_overclock,
        "workshop_overclock_games": workshop_overclock_games, "workshop_job_end_unix": workshop_job_end_unix,
        "workshop_job_active": workshop_job_active, "workshop_job_name": workshop_job_name, "workshop_job_reward": workshop_job_reward,
        "level": player_level, "xp": player_xp, "xp_to_next": xp_to_next, "games": total_games,
        "total_prizes_won": total_prizes_won, "rarity_wins": rarity_wins, "achievements": unlocked_achievements,
        "last_daily_bonus_date": last_daily_bonus_date, "login_streak": login_streak, "last_login_claim_date": last_login_claim_date,
        "best_result": best_result, "best_result_xp": best_result_xp, "current_win_streak": current_win_streak,
        "best_win_streak": best_win_streak, "total_xp_earned": total_xp_earned, "highest_reward_rubles": highest_reward_rubles,
        "perfect_grabs": perfect_grabs, "heavy_toy_wins": heavy_toy_wins, "lucky_toy_wins": lucky_toy_wins,
        "daily_mission_progress": daily_mission_progress, "daily_mission_date": daily_mission_date,
        "daily_mission_claimed": daily_mission_claimed, "weekly_mission_progress": weekly_mission_progress,
        "weekly_mission_key": weekly_mission_key, "weekly_mission_claimed": weekly_mission_claimed,
        "season_pass_xp": season_pass_xp, "season_pass_level": season_pass_level, "active_season_id": active_season_id,
        "owned_claws": owned_claws, "owned_claw_skins": owned_claw_skins, "owned_toy_skins": owned_toy_skins,
        "owned_machine_skins": owned_machine_skins, "selected_claw_skin": selected_claw_skin,
        "selected_toy_skin": selected_toy_skin, "selected_machine_skin": selected_machine_skin,
        "vip_owned": vip_owned, "vip_selected": vip_selected, "collection": collection,
        "toy_inventory_counts": toy_inventory_counts, "completed_collections": completed_collections,
        "upgrades": upgrade_levels, "claw": selected_claw, "promo_codes_used": promo_codes_used,
        "return_bonus_days": return_bonus_days, "return_bonus_available": return_bonus_available,
        "return_bonus_claimed": return_bonus_claimed, "last_active_unix": last_active_unix,
        "referral_code": referral_code, "referral_used": referral_used
    }


func _bool_array_from_variant(value: Variant, fallback: Array[bool]) -> Array[bool]:
    if value is Array:
        var result: Array[bool] = []
        for item in value:
            result.append(bool(item))
        return result
    return fallback.duplicate()

func _int_array_from_variant(value: Variant, fallback: Array[int]) -> Array[int]:
    if value is Array:
        var result: Array[int] = []
        for item in value:
            result.append(int(item))
        return result
    return fallback.duplicate()

func apply_server_game_state(data: Dictionary) -> void:
    if data.is_empty():
        return
    coins = maxi(0, int(data.get("coins", coins)))
    player_name = String(data.get("player_name", player_name)).substr(0, 20)
    player_avatar_index = clampi(int(data.get("player_avatar_index", player_avatar_index)), 0, AVATAR_OPTIONS.size() - 1)
    bonus_keys = maxi(0, int(data.get("bonus_keys", bonus_keys)))
    engineering_parts = maxi(0, int(data.get("engineering_parts", engineering_parts)))
    var ci: Variant = data.get("chest_inventory", chest_inventory)
    if ci is Dictionary:
        for k in chest_inventory.keys():
            chest_inventory[k] = maxi(0, int(ci.get(k, chest_inventory[k])))
    chest_keys = maxi(0, int(data.get("chest_keys", chest_keys)))
    var cet: Variant = data.get("chest_exclusive_toys", chest_exclusive_toys)
    if cet is Dictionary: chest_exclusive_toys = cet
    var ces: Variant = data.get("chest_exclusive_skins", chest_exclusive_skins)
    if ces is Dictionary: chest_exclusive_skins = ces
    chest_exclusive_reward_count = maxi(0, int(data.get("chest_exclusive_reward_count", chest_exclusive_reward_count)))
    total_chests_opened = maxi(0, int(data.get("total_chests_opened", total_chests_opened)))
    total_keys_earned = maxi(0, int(data.get("total_keys_earned", total_keys_earned)))
    workshop_parts = maxi(0, int(data.get("workshop_parts", workshop_parts)))
    workshop_level = maxi(1, int(data.get("workshop_level", workshop_level)))
    workshop_claw_power = clampi(int(data.get("workshop_claw_power", workshop_claw_power)), 0, 10)
    workshop_speed = clampi(int(data.get("workshop_speed", workshop_speed)), 0, 10)
    workshop_precision = clampi(int(data.get("workshop_precision", workshop_precision)), 0, 10)
    workshop_luck = clampi(int(data.get("workshop_luck", workshop_luck)), 0, 10)
    workshop_motor = clampi(int(data.get("workshop_motor", workshop_motor)), 0, 15)
    workshop_servo = clampi(int(data.get("workshop_servo", workshop_servo)), 0, 15)
    workshop_cable = clampi(int(data.get("workshop_cable", workshop_cable)), 0, 15)
    workshop_damper = clampi(int(data.get("workshop_damper", workshop_damper)), 0, 15)
    workshop_cooling = clampi(int(data.get("workshop_cooling", workshop_cooling)), 0, 15)
    workshop_controller = clampi(int(data.get("workshop_controller", workshop_controller)), 0, 15)
    var wb: Variant = data.get("workshop_blueprints", workshop_blueprints)
    if wb is Dictionary: workshop_blueprints = wb
    workshop_calibration = clampi(int(data.get("workshop_calibration", workshop_calibration)), 0, 5)
    workshop_overclock = bool(data.get("workshop_overclock", workshop_overclock))
    workshop_overclock_games = maxi(0, int(data.get("workshop_overclock_games", workshop_overclock_games)))
    workshop_job_end_unix = int(data.get("workshop_job_end_unix", workshop_job_end_unix))
    workshop_job_active = bool(data.get("workshop_job_active", workshop_job_active))
    workshop_job_name = String(data.get("workshop_job_name", workshop_job_name))
    workshop_job_reward = maxi(0, int(data.get("workshop_job_reward", workshop_job_reward)))
    player_level = maxi(1, int(data.get("level", player_level)))
    player_xp = maxi(0, int(data.get("xp", player_xp)))
    xp_to_next = maxi(xp_needed_for_level(player_level), int(data.get("xp_to_next", xp_to_next)))
    total_games = maxi(0, int(data.get("games", total_games)))
    total_prizes_won = maxi(0, int(data.get("total_prizes_won", total_prizes_won)))
    var rw: Variant = data.get("rarity_wins", rarity_wins)
    if rw is Dictionary: rarity_wins = rw
    var ach: Variant = data.get("achievements", unlocked_achievements)
    if ach is Dictionary: unlocked_achievements = ach
    last_daily_bonus_date = String(data.get("last_daily_bonus_date", last_daily_bonus_date))
    login_streak = maxi(0, int(data.get("login_streak", login_streak)))
    last_login_claim_date = String(data.get("last_login_claim_date", last_login_claim_date))
    best_result = String(data.get("best_result", best_result))
    best_result_xp = maxi(0, int(data.get("best_result_xp", best_result_xp)))
    current_win_streak = maxi(0, int(data.get("current_win_streak", current_win_streak)))
    best_win_streak = maxi(0, int(data.get("best_win_streak", best_win_streak)))
    total_xp_earned = maxi(0, int(data.get("total_xp_earned", total_xp_earned)))
    highest_reward_rubles = maxi(0, int(data.get("highest_reward_rubles", highest_reward_rubles)))
    perfect_grabs = maxi(0, int(data.get("perfect_grabs", perfect_grabs)))
    heavy_toy_wins = maxi(0, int(data.get("heavy_toy_wins", heavy_toy_wins)))
    lucky_toy_wins = maxi(0, int(data.get("lucky_toy_wins", lucky_toy_wins)))
    daily_mission_progress = maxi(0, int(data.get("daily_mission_progress", daily_mission_progress)))
    daily_mission_date = String(data.get("daily_mission_date", daily_mission_date))
    daily_mission_claimed = bool(data.get("daily_mission_claimed", daily_mission_claimed))
    weekly_mission_progress = maxi(0, int(data.get("weekly_mission_progress", weekly_mission_progress)))
    weekly_mission_key = String(data.get("weekly_mission_key", weekly_mission_key))
    weekly_mission_claimed = bool(data.get("weekly_mission_claimed", weekly_mission_claimed))
    season_pass_xp = maxi(0, int(data.get("season_pass_xp", season_pass_xp)))
    season_pass_level = clampi(int(data.get("season_pass_level", season_pass_level)), 1, SEASON_PASS_MAX_LEVEL)
    active_season_id = String(data.get("active_season_id", active_season_id))
    var arr: Variant = data.get("owned_claws", owned_claws)
    owned_claws = _bool_array_from_variant(arr, owned_claws)
    arr = data.get("owned_claw_skins", owned_claw_skins)
    owned_claw_skins = _bool_array_from_variant(arr, owned_claw_skins)
    arr = data.get("owned_toy_skins", owned_toy_skins)
    owned_toy_skins = _bool_array_from_variant(arr, owned_toy_skins)
    arr = data.get("owned_machine_skins", owned_machine_skins)
    owned_machine_skins = _bool_array_from_variant(arr, owned_machine_skins)
    selected_claw_skin = clampi(int(data.get("selected_claw_skin", selected_claw_skin)), 0, maxi(0, claw_skin_specs.size() - 1))
    selected_toy_skin = clampi(int(data.get("selected_toy_skin", selected_toy_skin)), 0, maxi(0, toy_skin_specs.size() - 1))
    selected_machine_skin = clampi(int(data.get("selected_machine_skin", selected_machine_skin)), 0, maxi(0, machine_skin_specs.size() - 1))
    arr = data.get("vip_owned", vip_owned)
    vip_owned = _bool_array_from_variant(arr, vip_owned)
    vip_selected = clampi(int(data.get("vip_selected", vip_selected)), 0, maxi(0, vip_specs.size() - 1))
    selected_claw = clampi(int(data.get("claw", selected_claw)), 0, maxi(0, claw_specs.size() - 1))
    var d: Variant = data.get("collection", collection)
    if d is Dictionary: collection = d
    d = data.get("toy_inventory_counts", toy_inventory_counts)
    if d is Dictionary: toy_inventory_counts = d
    d = data.get("completed_collections", completed_collections)
    if d is Dictionary: completed_collections = d
    arr = data.get("upgrades", upgrade_levels)
    upgrade_levels = _int_array_from_variant(arr, upgrade_levels)
    d = data.get("promo_codes_used", promo_codes_used)
    if d is Dictionary: promo_codes_used = d
    return_bonus_days = maxi(0, int(data.get("return_bonus_days", return_bonus_days)))
    return_bonus_available = bool(data.get("return_bonus_available", return_bonus_available))
    return_bonus_claimed = bool(data.get("return_bonus_claimed", return_bonus_claimed))
    last_active_unix = int(data.get("last_active_unix", last_active_unix))
    # v2 authoritative server schema mapping. Client state is presentation only;
    # the values below come from the server snapshot after every accepted action.
    var inv: Variant = data.get("inventory", {})
    if inv is Dictionary:
        chest_keys = maxi(0, int(inv.get("chest_keys", chest_keys)))
        engineering_parts = maxi(0, int(inv.get("parts", engineering_parts)))
        var server_chests: Variant = inv.get("chests", {})
        if server_chests is Dictionary:
            for ck in chest_inventory.keys():
                chest_inventory[ck] = maxi(0, int(server_chests.get(ck, chest_inventory.get(ck, 0))))
        var server_toys: Variant = inv.get("toys", {})
        if server_toys is Dictionary:
            toy_inventory_counts = server_toys.duplicate(true)
    var missions: Variant = data.get("missions", {})
    if missions is Dictionary:
        daily_mission_progress = maxi(0, int(missions.get("daily_progress", daily_mission_progress)))
        daily_mission_claimed = bool(missions.get("daily_claimed", daily_mission_claimed))
        weekly_mission_progress = maxi(0, int(missions.get("weekly_progress", weekly_mission_progress)))
        weekly_mission_claimed = bool(missions.get("weekly_claimed", weekly_mission_claimed))
        daily_mission_date = String(missions.get("daily_key", daily_mission_date))
        weekly_mission_key = String(missions.get("weekly_key", weekly_mission_key))
    var season_data: Variant = data.get("season", {})
    if season_data is Dictionary:
        season_pass_xp = maxi(0, int(season_data.get("xp", season_pass_xp)))
        season_pass_level = clampi(int(season_data.get("level", season_pass_level)), 1, SEASON_PASS_MAX_LEVEL)
    var server_settings: Variant = data.get("settings", {})
    if server_settings is Dictionary:
        if server_settings.has("language"): language = String(server_settings.get("language"))
        if server_settings.has("quality_level"): quality_level = clampi(int(server_settings.get("quality_level")), 0, 4)
        if server_settings.has("fps_limit"): fps_limit = maxi(30, int(server_settings.get("fps_limit")))
        if server_settings.has("notifications_on"): notifications_on = bool(server_settings.get("notifications_on"))
    if data.has("owned_items") and data["owned_items"] is Array:
        var owned_server: Array = data.get("owned_items")
        for i in range(owned_claws.size()): owned_claws[i] = owned_server.has("claw_%d" % (i + 1))
    if data.has("selected_claw"): selected_claw = clampi(int(data.get("selected_claw", selected_claw)), 0, claw_specs.size()-1)
    if data.has("upgrade_levels") and data["upgrade_levels"] is Array:
        upgrade_levels = _int_array_from_variant(data.get("upgrade_levels"), upgrade_levels)
    workshop_parts = maxi(0, int(data.get("workshop_parts", workshop_parts)))
    workshop_level = maxi(1, int(data.get("workshop_level", workshop_level)))
    workshop_claw_power = clampi(int(data.get("workshop_claw_power", workshop_claw_power)),0,10)
    workshop_speed = clampi(int(data.get("workshop_speed", workshop_speed)),0,10)
    workshop_precision = clampi(int(data.get("workshop_precision", workshop_precision)),0,10)
    workshop_luck = clampi(int(data.get("workshop_luck", workshop_luck)),0,10)
    workshop_motor = clampi(int(data.get("workshop_motor", workshop_motor)),0,15)
    workshop_servo = clampi(int(data.get("workshop_servo", workshop_servo)),0,15)
    workshop_cable = clampi(int(data.get("workshop_cable", workshop_cable)),0,15)
    workshop_damper = clampi(int(data.get("workshop_damper", workshop_damper)),0,15)
    workshop_cooling = clampi(int(data.get("workshop_cooling", workshop_cooling)),0,15)
    workshop_controller = clampi(int(data.get("workshop_controller", workshop_controller)),0,15)
    var server_wb: Variant = data.get("workshop_blueprints", workshop_blueprints)
    if server_wb is Dictionary: workshop_blueprints = server_wb.duplicate(true)
    workshop_calibration = clampi(int(data.get("workshop_calibration", workshop_calibration)),0,5)
    workshop_overclock = bool(data.get("workshop_overclock", workshop_overclock))
    workshop_overclock_games = maxi(0,int(data.get("workshop_overclock_games", workshop_overclock_games)))
    workshop_job_end_unix = int(data.get("workshop_job_end_unix", workshop_job_end_unix)); workshop_job_active = bool(data.get("workshop_job_active", workshop_job_active)); workshop_job_name = String(data.get("workshop_job_name", workshop_job_name)); workshop_job_reward = maxi(0,int(data.get("workshop_job_reward", workshop_job_reward)))
    player_avatar_index = clampi(int(data.get("player_avatar_index", player_avatar_index)),0,AVATAR_OPTIONS.size()-1)
    var os1: Variant = data.get("owned_claw_skins", owned_claw_skins); owned_claw_skins = _bool_array_from_variant(os1, owned_claw_skins)
    var os2: Variant = data.get("owned_toy_skins", owned_toy_skins); owned_toy_skins = _bool_array_from_variant(os2, owned_toy_skins)
    var os3: Variant = data.get("owned_machine_skins", owned_machine_skins); owned_machine_skins = _bool_array_from_variant(os3, owned_machine_skins)
    selected_claw_skin=clampi(int(data.get("selected_claw_skin",selected_claw_skin)),0,maxi(0,claw_skin_specs.size()-1)); selected_toy_skin=clampi(int(data.get("selected_toy_skin",selected_toy_skin)),0,maxi(0,toy_skin_specs.size()-1)); selected_machine_skin=clampi(int(data.get("selected_machine_skin",selected_machine_skin)),0,maxi(0,machine_skin_specs.size()-1))
    workshop_parts = engineering_parts if workshop_parts == 0 and engineering_parts > 0 else workshop_parts
    if data.has("referral_code"): referral_code = String(data.get("referral_code", referral_code))
    if data.has("referral_used"): referral_used = bool(data.get("referral_used", referral_used))
    apply_shop_visuals()
    update_ui()
    refresh_shop()
    refresh_chests_panel()
    refresh_workshop_panel()
    refresh_live_systems_panel()
    update_daily_login_ui()
    save_game()

func show_server_blocked(reason: String = "") -> void:
    if blocked_overlay and is_instance_valid(blocked_overlay):
        blocked_overlay.visible = true
        return
    blocked_overlay = PanelContainer.new()
    blocked_overlay.name = "ServerBlockedOverlay"
    blocked_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    blocked_overlay.z_index = 10000
    style_panel(blocked_overlay, Color("#140B0B"), Color("#A53A3A"), 0, 0)
    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    box.custom_minimum_size = Vector2(860, 520)
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    blocked_overlay.add_child(box)
    var title := Label.new(); title.text = "🔒  АККАУНТ ЗАБЛОКИРОВАН"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 38); box.add_child(title)
    var msg := Label.new(); msg.text = "Доступ к игре ограничен сервером.
" + (reason if reason != "" else ""); msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; msg.add_theme_font_size_override("font_size", 24); box.add_child(msg)
    var contact := Label.new(); contact.text = "Для разблокировки напишите на:
evgeniu.tsepaev19@gmail.com"; contact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; contact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; contact.add_theme_font_size_override("font_size", 22); box.add_child(contact)
    if hud_layer:
        hud_layer.add_child(blocked_overlay)
        hud_layer.visible = true
    else:
        menu_layer.add_child(blocked_overlay)
    set_main_menu_controls(false)

func _remote_headers() -> PackedStringArray:
    var h := PackedStringArray(["Content-Type: application/json"])
    if player_token != "":
        h.append("Authorization: Bearer " + player_token)
    return h

func _server_action(action_name: String, payload: Dictionary = {}) -> bool:
    if not _server_ready() or player_token == "":
        return false
    if remote_request_kind != "":
        # Приоритетные игровые действия не ждут фоновой синхронизации.
        if action_name in ["game_start", "cosmetic_buy", "daily_login", "game_finish", "workshop_upgrade", "workshop_blueprint", "workshop_calibrate"]:
            if remote_request_kind in ["config", "sync", "notifications", "rating", "register"]:
                remote_http.cancel_request()
                remote_request_kind = ""
                remote_action_name = ""
            else:
                var queued := {"name": action_name, "payload": payload.duplicate(true)}
                remote_action_queue.append(queued)
                return true
        else:
            return false
    var data := payload.duplicate(true)
    data["type"] = action_name
    data["action_id"] = "%s_%s_%s" % [action_name, player_id, str(Time.get_ticks_msec())]
    remote_action_name = action_name
    remote_request_kind = "action:" + action_name
    var err := remote_http.request(_normalized_server_url() + "/api/player/action", _remote_headers(), HTTPClient.METHOD_POST, JSON.stringify(data))
    if err != OK:
        remote_request_kind = ""
        remote_action_name = ""
        return false
    return true

func register_device_remote() -> void:
    if not _server_ready() or not _is_android_runtime_available() or remote_device_registered:
        return
    var receiver = _get_background_notification_receiver()
    var context = Engine.get_singleton("AndroidRuntime").getApplicationContext()
    if receiver != null and context != null:
        receiver.registerServer(context, _normalized_server_url(), player_id, player_token)
        var java_exception = JavaClassWrapper.get_exception()
        if java_exception == null:
            remote_device_registered = true

func poll_server_notifications() -> void:
    if not _server_ready() or player_id == "" or remote_request_kind != "":
        return
    remote_request_kind = "notifications"
    var url := _normalized_server_url() + "/api/notifications/poll?player_id=" + player_id.uri_encode() + "&cursor=" + str(remote_notification_cursor)
    var err := remote_http.request(url, _remote_headers())
    if err != OK:
        remote_request_kind = ""
        remote_sync_status = "ОШИБКА УВЕДОМЛЕНИЙ"

func register_player_remote() -> void:
    if not _server_ready():
        remote_sync_status = "СЕРВЕР НЕ НАСТРОЕН"
        return
    if remote_request_kind != "":
        remote_sync_pending = true
        return
    remote_request_kind = "register"
    var payload := {"player_id": player_id, "name": player_name}
    var headers := _remote_headers()
    var err := remote_http.request(_normalized_server_url() + "/api/player/register", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        remote_request_kind = ""
        remote_sync_status = "ОШИБКА РЕГИСТРАЦИИ"

func sync_remote_config() -> void:
    if not _server_ready():
        remote_sync_status = "СЕРВЕР НЕ НАСТРОЕН"
        return
    if remote_request_kind != "":
        remote_sync_pending = true
        return
    remote_request_kind = "config"
    var url := _normalized_server_url() + "/api/config?player_id=" + player_id.uri_encode() + "&name=" + player_name.uri_encode()
    var err := remote_http.request(url)
    if err != OK:
        remote_request_kind = ""
        remote_sync_status = "ОШИБКА ПОДКЛЮЧЕНИЯ"

func sync_player_to_server() -> void:
    if not _server_ready():
        return
    if remote_request_kind != "":
        remote_sync_pending = true
        return
    var payload := {
        "player_id": player_id,
            "player_token": player_token,
        "name": player_name,
        "score": int(get_player_online_score()),
        "level": player_level,
        "coins": coins,
        "games": total_games,
        "prizes": total_prizes_won,
        "best_streak": best_win_streak,
        "referral_code": referral_code,
        "referral_invites": referral_invites,
        "game_state": get_server_game_state()
    }
    remote_request_kind = "sync"
    var headers := _remote_headers()
    var err := remote_http.request(_normalized_server_url() + "/api/player/sync", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        remote_request_kind = ""
        remote_sync_status = "ОШИБКА СИНХРОНИЗАЦИИ"

func get_player_online_score() -> int:
    return total_games * 12 + total_prizes_won * 35 + player_level * 180 + best_win_streak * 25

func request_global_rating() -> void:
    if not _server_ready():
        return
    remote_request_kind = "rating"
    var err := remote_http.request(_normalized_server_url() + "/api/rating?player_id=" + player_id.uri_encode())
    if err != OK:
        remote_sync_status = "ОШИБКА РЕЙТИНГА"

func apply_referral_remote(code: String) -> void:
    if not _server_ready() or player_token == "":
        referral_status_label.text = "Сервер недоступен. Попробуйте позже."
        return
    if remote_request_kind != "":
        referral_status_label.text = "Подключаемся к серверу…"
        remote_sync_pending = true
        return
    remote_pending_referral = code.strip_edges().to_upper()
    remote_request_kind = "action:referral_apply"
    var payload := {"type":"referral_apply", "action_id":"ref_%s_%s" % [player_id, str(Time.get_ticks_msec())], "referral_code":remote_pending_referral}
    var err := remote_http.request(_normalized_server_url() + "/api/player/action", _remote_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        remote_request_kind = ""
        referral_status_label.text = "Сервер недоступен. Попробуйте позже."

func redeem_promo_code_remote(code: String) -> void:
    if remote_promo_request_active or not _server_ready() or player_token == "":
        return
    if remote_request_kind != "":
        return
    remote_promo_request_active = true
    remote_pending_promo = code.strip_edges().to_upper()
    remote_request_kind = "action:promo_redeem"
    var payload := {"type":"promo_redeem", "action_id":"promo_%s_%s" % [player_id, str(Time.get_ticks_msec())], "code":remote_pending_promo}
    var err := remote_http.request(_normalized_server_url() + "/api/player/action", _remote_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        remote_promo_request_active = false
        remote_request_kind = ""
        promo_status = "СЕРВЕР НЕДОСТУПЕН"
        refresh_promo_panel()

func _apply_remote_catalog(catalog: Dictionary) -> void:
    var remote_toys: Variant = catalog.get("toys", [])
    if remote_toys is Array and not remote_toys.is_empty():
        var mapped: Array[Dictionary] = []
        for raw_toy in remote_toys:
            if raw_toy is Dictionary and bool(raw_toy.get("enabled", true)):
                var toy_dict: Dictionary = raw_toy
                mapped.append({"name":String(toy_dict.get("name", "Игрушка")), "collection":String(toy_dict.get("collection", "Базовая")), "rarity":String(toy_dict.get("rarity", "ОБЫЧНАЯ")), "weight":float(toy_dict.get("weight", 10.0)), "color":Color.WHITE, "id":String(toy_dict.get("id", ""))})
        if not mapped.is_empty():
            toys = mapped
    var remote_shop: Variant = catalog.get("shop", [])
    if remote_shop is Array:
        for raw_item in remote_shop:
            if not (raw_item is Dictionary):
                continue
            var item: Dictionary = raw_item
            var item_id := String(item.get("id", ""))
            var item_name := String(item.get("name", ""))
            var item_price := int(item.get("price", 0))
            var effect: Dictionary = item.get("effect", {}) if item.get("effect", {}) is Dictionary else {}
            if item_id.begins_with("claw_") and not item_id.begins_with("claw_skin_"):
                var ci := int(item_id.trim_prefix("claw_")) - 1
                if ci >= 0 and ci < claw_specs.size():
                    claw_specs[ci]["name"] = item_name
                    claw_specs[ci]["price"] = item_price
                    claw_specs[ci]["bonus"] = float(effect.get("capture_bonus", claw_specs[ci]["bonus"]))
            elif item_id.begins_with("upgrade_"):
                var ui := int(item_id.trim_prefix("upgrade_")) - 1
                if ui >= 0 and ui < upgrade_specs.size():
                    upgrade_specs[ui]["name"] = item_name
                    upgrade_specs[ui]["base_price"] = item_price
            elif item_id.begins_with("claw_skin_"):
                var si := int(item_id.trim_prefix("claw_skin_"))
                if si >= 0 and si < claw_skin_specs.size():
                    claw_skin_specs[si]["name"] = item_name
                    claw_skin_specs[si]["price"] = item_price
            elif item_id.begins_with("toy_skin_"):
                var ti := int(item_id.trim_prefix("toy_skin_"))
                if ti >= 0 and ti < toy_skin_specs.size():
                    toy_skin_specs[ti]["name"] = item_name
                    toy_skin_specs[ti]["price"] = item_price
            elif item_id.begins_with("machine_skin_"):
                var mi := int(item_id.trim_prefix("machine_skin_"))
                if mi >= 0 and mi < machine_skin_specs.size():
                    machine_skin_specs[mi]["name"] = item_name
                    machine_skin_specs[mi]["price"] = item_price
    var remote_ach: Variant = catalog.get("achievements", [])
    if remote_ach is Array and not remote_ach.is_empty():
        var aa: Array[Dictionary] = []
        for raw_achievement in remote_ach:
            if raw_achievement is Dictionary and bool(raw_achievement.get("enabled", true)):
                var achievement: Dictionary = raw_achievement
                aa.append({"id":String(achievement.get("id", "")), "name":String(achievement.get("name", "Достижение")), "desc":String(achievement.get("description", achievement.get("desc", ""))), "kind":String(achievement.get("kind", "level")), "value":int(achievement.get("value", 1)), "rarity":String(achievement.get("rarity", ""))})
        if not aa.is_empty():
            achievement_specs = aa

func _apply_remote_config(config: Dictionary) -> void:
    remote_config = config
    var server_catalog: Variant = config.get("catalog", {})
    if server_catalog is Dictionary: _apply_remote_catalog(server_catalog)
    online_maintenance = bool(config.get("maintenance_mode", false))
    online_announcement = String(config.get("global_announcement", ""))
    online_reward_multiplier = clampf(float(config.get("global_reward_multiplier", 1.0)), 0.1, 10.0)
    online_daily_bonus_amount = maxi(1, int(config.get("daily_bonus_amount", daily_bonus_amount)))
    online_daily_mission_reward = maxi(1, int(config.get("daily_mission_reward", daily_mission_reward)))
    online_weekly_mission_reward = maxi(1, int(config.get("weekly_mission_reward", weekly_mission_reward)))
    online_return_bonus_base = maxi(0, int(config.get("return_bonus_base", 100)))
    online_return_bonus_per_day = maxi(0, int(config.get("return_bonus_per_day", 25)))
    online_return_bonus_max_days = clampi(int(config.get("return_bonus_max_days", 30)), 1, 90)
    daily_bonus_amount = online_daily_bonus_amount
    daily_mission_reward = online_daily_mission_reward
    weekly_mission_reward = online_weekly_mission_reward
    var notif: Variant = config.get("notification_hours", {})
    if notif is Dictionary:
        online_notification_hours = notif
    var server_seasons: Variant = config.get("season_definitions", [])
    if server_seasons is Array and not server_seasons.is_empty():
        var season_list: Array[Dictionary] = []
        for raw_season in server_seasons:
            if raw_season is Dictionary: season_list.append(raw_season)
        if not season_list.is_empty(): season_specs = season_list
    var server_holidays: Variant = config.get("holiday_calendar", [])
    if server_holidays is Array and not server_holidays.is_empty():
        var holiday_list: Array[Dictionary] = []
        for raw_holiday in server_holidays:
            if raw_holiday is Dictionary: holiday_list.append(raw_holiday)
        if not holiday_list.is_empty(): holiday_calendar = holiday_list
    var remote_news: Variant = config.get("news", [])
    if remote_news is Array:
        remote_news_items.clear()
        for item in remote_news:
            if item is Dictionary:
                remote_news_items.append(item)
        if not remote_news_items.is_empty():
            news_items = remote_news_items.duplicate(true)
            news_unread = maxi(0, int(config.get("unread_news", remote_news_items.size())))
    var event: Variant = config.get("active_event", {})
    if event is Dictionary and not event.is_empty():
        active_event_id = String(event.get("id", active_event_id))
        active_event_name = String(event.get("name", active_event_name))
        active_event_end_unix = int(event.get("end_unix", active_event_end_unix))
        active_event_bonus = float(event.get("bonus", active_event_bonus))
        active_event_reward_mult = float(event.get("reward_mult", active_event_reward_mult))
    remote_sync_status = "ПОДКЛЮЧЕНО"
    cancel_background_notifications()
    if notifications_on:
        schedule_background_notifications()
    register_device_remote()
    refresh_news_panel(news_panel)
    refresh_rating_panel()
    refresh_shop()
    refresh_achievements_panel()
    refresh_vip_panel()
    update_ui()

func _on_claw_http_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    claw_http_busy = false
    var text := body.get_string_from_utf8().strip_edges()
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or text == "":
        server_attempt_ready = false
        server_attempt_success = false
        server_attempt_toy_id = ""
        server_attempt_toy_name = ""
        server_attempt_reward = {}
        # The physical cycle may already be running; it will safely return home.
        if drop_state == 1 or drop_state == 2:
            claw_move_target = CLAW_HOME
            claw_target = CLAW_HOME
            drop_state = 8
            drop_time = 0.0
            current_result = "СЕРВЕР НЕ ОТВЕТИЛ — КЛЕШНЬ ВОЗВРАЩАЕТСЯ"
        update_ui()
        return
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary) or not bool(parsed.get("ok", false)):
        server_attempt_ready = false
        server_attempt_success = false
        server_attempt_toy_id = ""
        server_attempt_toy_name = ""
        server_attempt_reward = {}
        if drop_state == 1 or drop_state == 2:
            claw_move_target = CLAW_HOME
            claw_target = CLAW_HOME
            drop_state = 8
            drop_time = 0.0
            current_result = String(parsed.get("message", "Сервер отклонил попытку")) if parsed is Dictionary else "Сервер вернул ошибку"
        update_ui()
        return
    var data: Dictionary = parsed
    if data.has("token") and String(data.get("token", "")) != "":
        player_token = String(data.get("token"))
    if data.has("game_state") and data["game_state"] is Dictionary:
        apply_server_game_state(data["game_state"])
    var start_attempt: Variant = data.get("attempt", {})
    server_attempt_ready = start_attempt is Dictionary
    if server_attempt_ready:
        server_attempt_success = bool(start_attempt.get("success", false))
        server_attempt_toy_id = String(start_attempt.get("toy_id", ""))
        server_attempt_toy_name = String(start_attempt.get("toy_name", ""))
        var reward: Variant = start_attempt.get("reward", {})
        server_attempt_reward = reward.duplicate(true) if reward is Dictionary else {}
        server_attempt_slip = bool(start_attempt.get("slip", false))
    update_ui()

func _on_cosmetic_http_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    cosmetic_http_busy = false
    var text := body.get_string_from_utf8().strip_edges()
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or text == "":
        current_result = "НЕ УДАЛОСЬ УСТАНОВИТЬ СКИН — ПРОВЕРЬТЕ СЕРВЕР"
        update_ui()
        return
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary) or not bool(parsed.get("ok", false)):
        current_result = String(parsed.get("message", "Сервер отклонил установку скина")) if parsed is Dictionary else "Сервер вернул ошибку"
        update_ui()
        return
    var data: Dictionary = parsed
    if data.has("game_state") and data["game_state"] is Dictionary:
        apply_server_game_state(data["game_state"])
    var item: Variant = data.get("item", {})
    if item is Dictionary:
        var effect: Variant = item.get("effect", {})
        var category := String(item.get("category", ""))
        if effect is Dictionary and effect.has("skin_index"):
            var idx := int(effect.get("skin_index", 0))
            if category == "claw_skins":
                selected_claw_skin = clampi(idx, 0, maxi(0, claw_skin_specs.size() - 1))
                if selected_claw_skin < owned_claw_skins.size(): owned_claw_skins[selected_claw_skin] = true
            elif category == "toy_skins":
                selected_toy_skin = clampi(idx, 0, maxi(0, toy_skin_specs.size() - 1))
                if selected_toy_skin < owned_toy_skins.size(): owned_toy_skins[selected_toy_skin] = true
            elif category == "machine_skins":
                selected_machine_skin = clampi(idx, 0, maxi(0, machine_skin_specs.size() - 1))
                if selected_machine_skin < owned_machine_skins.size(): owned_machine_skins[selected_machine_skin] = true
        apply_shop_visuals()
        if category == "toy_skins": build_prizes()
        current_result = "УСТАНОВЛЕН СКИН: %s" % String(item.get("name", "ГОТОВО"))
    refresh_shop()
    refresh_vip_panel()
    save_game()
    update_ui()

func _abort_server_claw_attempt(message: String) -> void:
    server_attempt_ready = false
    server_attempt_success = false
    server_attempt_toy_id = ""
    server_attempt_toy_name = ""
    server_attempt_reward = {}
    server_attempt_slip = false
    if drop_state != 0:
        claw_move_target = CLAW_HOME
        claw_target = CLAW_HOME
        drop_state = 8
        drop_time = 0.0
    current_result = message
    update_ui()

func _on_remote_http_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    var kind := remote_request_kind
    remote_request_kind = ""
    var body_text := body.get_string_from_utf8().strip_edges()
    var data: Dictionary = {}

    # Never try to parse a transport error, empty body or HTML error page as JSON.
    # This prevents the recurring "Parse JSON failed" noise and, more importantly,
    # keeps the game state machine alive when the server is temporarily unavailable.
    if result != HTTPRequest.RESULT_SUCCESS:
        remote_sync_retry_count = mini(remote_sync_retry_count + 1, 10)
        remote_sync_status = "СЕРВЕР НЕДОСТУПЕН • ПОВТОРНОЕ ПОДКЛЮЧЕНИЕ"
        if kind.begins_with("action:"):
            remote_action_name = ""
            if kind == "action:promo_redeem":
                remote_promo_request_active = false
            if kind == "action:game_start":
                _abort_server_claw_attempt("Сервер временно недоступен. Повторяем подключение…")
                return
            current_result = "Сервер временно недоступен. Повторяем подключение…"
            update_ui()
        return

    if response_code < 200 or response_code >= 300:
        if response_code == 401 and kind != "register":
            # Session expired/server restarted: obtain a fresh player token automatically.
            player_token = ""
            remote_device_registered = false
            remote_sync_retry_count = 0
            remote_sync_status = "СЕАНС ИГРОКА ИСТЁК • ПЕРЕПОДКЛЮЧЕНИЕ"
            if kind.begins_with("action:"):
                remote_action_name = ""
                if kind == "action:promo_redeem":
                    remote_promo_request_active = false
                current_result = "Переподключаемся к серверу…"
            remote_auth_retry_timer = 0.5
            call_deferred("register_player_remote")
            update_ui()
            return
        remote_sync_retry_count = mini(remote_sync_retry_count + 1, 10)
        remote_sync_status = "ОШИБКА СЕРВЕРА • HTTP %d" % response_code
        if kind.begins_with("action:"):
            remote_action_name = ""
            if kind == "action:promo_redeem":
                remote_promo_request_active = false
            if kind == "action:game_start":
                _abort_server_claw_attempt("Сервер отклонил попытку захвата (HTTP %d)" % response_code)
                return
            current_result = "Сервер отклонил запрос (HTTP %d)" % response_code
            update_ui()
        return

    if body_text != "":
        var parsed: Variant = JSON.parse_string(body_text)
        if parsed is Dictionary:
            data = parsed
        else:
            remote_sync_status = "ОШИБКА ФОРМАТА ОТВЕТА СЕРВЕРА"
            if kind.begins_with("action:"):
                remote_action_name = ""
                if kind == "action:promo_redeem":
                    remote_promo_request_active = false
                if kind == "action:game_start":
                    _abort_server_claw_attempt("Сервер вернул некорректный ответ")
                    return
                current_result = "Сервер вернул некорректный ответ"
                update_ui()
            return
    else:
        remote_sync_status = "ПУСТОЙ ОТВЕТ СЕРВЕРА"
        return
    if data.has("token") and String(data.get("token", "")) != "":
        player_token = String(data.get("token"))
        save_game()
    if kind.begins_with("action:"):
        remote_action_name = ""
        if kind == "action:settings_update": server_settings_dirty = false
        if kind == "action:promo_redeem": remote_promo_request_active = false
        if bool(data.get("ok", false)) and data.has("game_state") and data["game_state"] is Dictionary:
            apply_server_game_state(data["game_state"])
        if bool(data.get("ok", false)) and data.has("achievements") and data["achievements"] is Array:
            pending_new_achievements.clear()
            for achievement in data["achievements"]:
                if achievement is Dictionary:
                    var ach_name := String(achievement.get("name", "Достижение"))
                    pending_new_achievements.append(ach_name)
            if not pending_new_achievements.is_empty():
                current_result = "🏆 НОВЫЕ ДОСТИЖЕНИЯ: " + " • ".join(pending_new_achievements)
        if not bool(data.get("ok", false)):
            current_result = String(data.get("message", "Сервер отклонил действие"))
        else:
            match kind:
                "action:daily_login":
                    # После успешного получения серверной награды этот день
                    # сразу становится закрытым в интерфейсе.
                    daily_claim_available = false
                    play_upgrade_sound("coin")
                    setup_login_streak()
                    update_daily_login_ui()
                "action:game_start":
                    server_attempt_ready = false
                    server_attempt_success = false
                    server_attempt_toy_id = ""
                    server_attempt_toy_name = ""
                    server_attempt_reward = {}
                    server_attempt_slip = false
                    var start_attempt: Variant = data.get("attempt", {})
                    if start_attempt is Dictionary:
                        server_attempt_ready = true
                        server_attempt_success = bool(start_attempt.get("success", false))
                        server_attempt_toy_id = String(start_attempt.get("toy_id", ""))
                        server_attempt_toy_name = String(start_attempt.get("toy_name", ""))
                        var start_reward: Variant = start_attempt.get("reward", {})
                        if start_reward is Dictionary:
                            server_attempt_reward = start_reward.duplicate(true)

                    # game_start приходит асинхронно. Если сервер ответил уже после
                    # выхода из drop_claw(), обязательно запускаем физическую
                    # последовательность опускания клешни здесь.
                    if server_attempt_ready and drop_state == 0:
                        claw_target = claw_pos
                        claw_move_target = claw_pos
                        claw_drop_target_y = find_top_layer_drop_y()
                        drop_state = 1
                        drop_time = 0.0
                        current_result = "КЛЕШНЬ ОПУСКАЕТСЯ..."
                    else:
                        current_result = "КЛЕШНЬ ГОТОВА К ПОПЫТКЕ"
                "action:game_finish":
                    var sr: Dictionary = data.get("prize", {}) if data.get("prize", null) is Dictionary else {}
                    if bool(data.get("success", false)) and not sr.is_empty():
                        last_prize_name = String(sr.get("name", last_prize_name))
                        last_prize_rarity = String(sr.get("rarity", last_prize_rarity))
                        last_reward_rubles = int((data.get("reward", {}) as Dictionary).get("amount", last_reward_rubles)) if data.get("reward", null) is Dictionary else last_reward_rubles
                        if bool(data.get("duplicate", false)):
                            sale_name = last_prize_name
                            sale_rarity = last_prize_rarity
                            sale_price = maxi(3, int(round(float(rarity_reward(last_prize_rarity)) * 0.65)))
                            sale_available = true
                            show_sale_offer()
                "action:promo_redeem":
                    promo_status = "Промокод успешно активирован"
                    refresh_promo_panel()
                "action:referral_apply":
                    referral_status_label.text = "Реферальный бонус зачислен сервером"
                    refresh_referral_panel()
                "action:shop_buy":
                    var bought: Variant = data.get("item", {})
                    if bought is Dictionary and String(bought.get("category", "")) == "claws":
                        selected_claw = clampi(int((bought.get("effect", {}) as Dictionary).get("claw_index", selected_claw)), 0, claw_specs.size()-1)
                    apply_shop_visuals()
                    refresh_shop()
                    current_result = "ПОКУПКА ПОДТВЕРЖДЕНА СЕРВЕРОМ"
                "action:cosmetic_buy":
                    # Не полагаемся только на общий game_state: серверный ответ
                    # содержит точный выбранный косметический индекс. Применяем его
                    # сразу, затем обновляем визуал и текст магазина.
                    var cosmetic_item: Variant = data.get("item", {})
                    if cosmetic_item is Dictionary:
                        var cosmetic_effect: Variant = cosmetic_item.get("effect", {})
                        var cosmetic_category := String(cosmetic_item.get("category", ""))
                        if cosmetic_effect is Dictionary and cosmetic_effect.has("skin_index"):
                            var cosmetic_index := int(cosmetic_effect.get("skin_index", 0))
                            if cosmetic_category == "claw_skins":
                                selected_claw_skin = clampi(cosmetic_index, 0, maxi(0, claw_skin_specs.size() - 1))
                                if selected_claw_skin < owned_claw_skins.size(): owned_claw_skins[selected_claw_skin] = true
                            elif cosmetic_category == "toy_skins":
                                selected_toy_skin = clampi(cosmetic_index, 0, maxi(0, toy_skin_specs.size() - 1))
                                if selected_toy_skin < owned_toy_skins.size(): owned_toy_skins[selected_toy_skin] = true
                            elif cosmetic_category == "machine_skins":
                                selected_machine_skin = clampi(cosmetic_index, 0, maxi(0, machine_skin_specs.size() - 1))
                                if selected_machine_skin < owned_machine_skins.size(): owned_machine_skins[selected_machine_skin] = true
                        apply_shop_visuals()
                        if cosmetic_category == "toy_skins":
                            build_prizes()
                        refresh_shop()
                        refresh_vip_panel()
                        current_result = "УСТАНОВЛЕН СКИН: %s" % String(cosmetic_item.get("name", "ГОТОВО"))
                    else:
                        apply_shop_visuals()
                        refresh_shop()
                        refresh_vip_panel()
                        current_result = "СКИН УСТАНОВЛЕН / ПОКУПКА ПОДТВЕРЖДЕНА СЕРВЕРОМ"
                "action:chest_open": current_result = "СУНДУК ОТКРЫТ СЕРВЕРОМ"
                # daily_login обработан выше: здесь не дублируем match-ветку.
                "action:claim_daily", "action:claim_daily_mission", "action:claim_weekly_mission": current_result = "НАГРАДА ЗАЧИСЛЕНА СЕРВЕРОМ"
                "action:settings_update":
                    apply_quality_settings()
                    apply_language()
                    update_quality_info()
            update_ui()
        return
    if data.has("game_state") and data["game_state"] is Dictionary:
        apply_server_game_state(data["game_state"])
    if kind == "notifications":
        var items: Variant = data.get("notifications", [])
        if items is Array:
            for item in items:
                if item is Dictionary:
                    var nid := int(item.get("id", 0))
                    remote_notification_cursor = maxi(remote_notification_cursor, nid)
                    if notifications_on:
                        notify_phone(String(item.get("title", "Хватайка")), String(item.get("message", "Зайди в игру!")))
        remote_sync_status = "ПОДКЛЮЧЕНО"
        return
    if data.has("player") and data["player"] is Dictionary:
        var server_player: Dictionary = data["player"]
        if server_player.has("player_id") and String(server_player.get("player_id", "")) != "":
            player_id = String(server_player.get("player_id", player_id))
        if server_player.has("referral_code") and String(server_player.get("referral_code", "")) != "":
            referral_code = String(server_player.get("referral_code", referral_code))
        if server_player.has("referral_invites"):
            referral_invites = maxi(0, int(server_player.get("referral_invites", referral_invites)))
        if kind == "sync" and server_player.has("coins"):
            coins = maxi(0, int(server_player.get("coins", coins)))
        save_game()
    if data.has("config") and data["config"] is Dictionary:
        _apply_remote_config(data["config"])
    if data.has("leaderboard") and data["leaderboard"] is Array:
        remote_leaderboard.clear()
        for row in data["leaderboard"]:
            if row is Dictionary:
                remote_leaderboard.append(row)
        refresh_rating_panel()
    if kind == "register" or kind == "sync" or kind == "config" or kind == "rating":
        remote_sync_status = "АККАУНТ ЗАРЕГИСТРИРОВАН • СЕРВЕР ПОДКЛЮЧЕН"
        remote_sync_retry_count = 0
        remote_auth_retry_timer = 10.0
    if kind == "register":
        remote_sync_pending = false
        call_deferred("sync_remote_config")
    elif kind == "config":
        remote_sync_pending = false
        if pending_incoming_referral != "":
            var incoming_code := pending_incoming_referral
            pending_incoming_referral = ""
            call_deferred("apply_referral_remote", incoming_code)
        else:
            call_deferred("sync_player_to_server")
    elif remote_sync_pending:
        remote_sync_pending = false
        call_deferred("sync_player_to_server")

func redeem_promo_code(code: String) -> void:
    var normalized := code.strip_edges().to_upper()
    if normalized == "":
        promo_status = "Введите промокод"
    elif _server_ready():
        redeem_promo_code_remote(normalized)
        return
    elif promo_codes_used.has(normalized):
        promo_status = "Этот промокод уже использован"
    else:
        var reward := 0
        match normalized:
            "KHVA2026": reward = 250
            "STARTER": reward = 100
            "TOYS60": reward = 160
            "CLAWPRO": reward = 220
            _:
                promo_status = "Промокод не найден"
                refresh_live_systems_panel()
                return
        promo_codes_used[normalized] = true
        coins += reward
        promo_status = "Промокод принят • +%d ₽" % reward
        current_result = "🎟 ПРОМОКОД • +%d ₽" % reward
        save_game()
        update_ui()
    refresh_live_systems_panel()

func get_local_leaderboard() -> Array[Dictionary]:
    var score := total_games * 12 + total_prizes_won * 35 + player_level * 180 + best_win_streak * 25
    var rows: Array[Dictionary] = [
        {"name":"NEONFOX","score":score + 4200}, {"name":"CLAWMASTER","score":score + 3100},
        {"name":"TOYHUNTER","score":score + 2050}, {"name":player_name,"score":score},
        {"name":"MEGAGRAB","score":maxi(100, score - 700)}, {"name":"PIXELBEAR","score":maxi(80, score - 1200)}
    ]
    rows.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["score"]) > int(b["score"]))
    return rows

func refresh_live_systems_panel() -> void:
    if not live_systems_panel:
        return
    var info := live_systems_panel.get_node_or_null("ScrollContainer/SystemsContent/SystemsInfo") as Label
    if info:
        var workshop_text := "готово" if not workshop_job_active else "%s • %s" % [workshop_job_name, _format_countdown(maxi(0, workshop_job_end_unix - int(Time.get_unix_time_from_system())))]
        var return_text := "ДОСТУПЕН +%d ₽" % return_bonus_amount if return_bonus_available else "ожидается после периода отсутствия"
        info.text = "Уведомления: %s\nМастерская: %s\nВозвращение: %s\nСезонный пропуск: %d/%d XP • уровень %d/%d" % ["ВКЛ" if notifications_on else "ВЫКЛ", workshop_text, return_text, season_pass_xp, 100, season_pass_level, SEASON_PASS_MAX_LEVEL]
    var leaderboard := live_systems_panel.get_node_or_null("ScrollContainer/SystemsContent/Leaderboard") as VBoxContainer
    if leaderboard:
        for c in leaderboard.get_children(): c.queue_free()
        var rows := get_local_leaderboard()
        for i in range(rows.size()):
            var row := Label.new()
            row.text = "%d. %s   •   %d" % [i + 1, String(rows[i]["name"]), int(rows[i]["score"])]
            row.add_theme_font_size_override("font_size", 17)
            row.modulate = GOLD if String(rows[i]["name"]) == player_name else Color("#E0D4C6")
            leaderboard.add_child(row)
    var status := live_systems_panel.get_node_or_null("ScrollContainer/SystemsContent/PromoStatus") as Label
    if status:
        status.text = promo_status

func _format_countdown(seconds: int) -> String:
    var m := int(seconds / 60)
    var s := seconds % 60
    return "%02d:%02d" % [m, s]


func build_info_menu_panel(panel_name: String, panel_size: Vector2) -> PanelContainer:
    var p := PanelContainer.new()
    p.name = panel_name
    p.position = Vector2(55, 80)
    p.size = panel_size
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)
    return p

func add_panel_title(parent: VBoxContainer, title_text: String) -> void:
    var h := Label.new()
    h.text = title_text
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    h.add_theme_font_size_override("font_size", 32)
    h.modulate = Color("#E1C29A")
    parent.add_child(h)

func build_season_pass_panel() -> PanelContainer:
    var p := build_info_menu_panel("SeasonPassPanel", Vector2(970, 1120))
    var scroll := ScrollContainer.new()
    scroll.name = "ScrollContainer"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.add_theme_constant_override("scroll_bar_width", 14)
    p.add_child(scroll)

    var v := VBoxContainer.new()
    v.name = "SeasonPassContent"
    v.custom_minimum_size = Vector2(900, 0)
    v.add_theme_constant_override("separation", 10)
    scroll.add_child(v)

    var info := Label.new()
    info.name = "SeasonPassInfo"
    info.text = "Уровень 1/30   •   XP 0/100"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 21)
    info.modulate = Color("#E1C29A")
    v.add_child(info)

    var intro := Label.new()
    intro.name = "SeasonPassIntro"
    intro.text = "🎟 СЕЗОННЫЙ ПРОПУСК • 30 УРОВНЕЙ • НАГРАДЫ ЗА ПРОГРЕСС"
    intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.add_theme_font_size_override("font_size", 17)
    intro.modulate = Color("#D8C3AA")
    v.add_child(intro)

    var progress := ProgressBar.new()
    progress.name = "SeasonPassProgress"
    progress.custom_minimum_size = Vector2(0, 24)
    progress.show_percentage = false
    progress.add_theme_stylebox_override("background", make_style(Color("#17110D"), Color("#4B392B"), 10, 1))
    progress.add_theme_stylebox_override("fill", make_style(Color("#9A7653"), Color("#D2A875"), 10, 1))
    v.add_child(progress)

    var tracks := Label.new()
    tracks.name = "SeasonPassTracks"
    tracks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tracks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tracks.add_theme_font_size_override("font_size", 15)
    tracks.modulate = Color("#D8C3AA")
    v.add_child(tracks)

    var levels := GridContainer.new()
    levels.name = "SeasonLevels"
    levels.columns = 2
    levels.add_theme_constant_override("h_separation", 10)
    levels.add_theme_constant_override("v_separation", 8)
    v.add_child(levels)

    for i in range(1, SEASON_PASS_MAX_LEVEL + 1):
        var card := PanelContainer.new()
        card.name = "SeasonLevel%02d" % i
        card.custom_minimum_size = Vector2(420, 96)
        var card_style := StyleBoxFlat.new()
        card_style.bg_color = Color("#241B16")
        card_style.border_color = Color("#5D4634")
        card_style.set_border_width_all(1)
        card_style.set_corner_radius_all(10)
        card.add_theme_stylebox_override("panel", card_style)
        levels.add_child(card)

        var box := VBoxContainer.new()
        box.name = "RewardBox"
        box.add_theme_constant_override("separation", 2)
        card.add_child(box)

        var level_label := Label.new()
        level_label.name = "Level"
        level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        level_label.add_theme_font_size_override("font_size", 16)
        level_label.modulate = Color("#E1C29A")
        box.add_child(level_label)

        var reward_label := Label.new()
        reward_label.name = "Reward"
        reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        reward_label.add_theme_font_size_override("font_size", 15)
        reward_label.modulate = Color("#F0D9BB")
        box.add_child(reward_label)

        var state_label := Label.new()
        state_label.name = "State"
        state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        state_label.add_theme_font_size_override("font_size", 12)
        box.add_child(state_label)

    var note := Label.new()
    note.name = "SeasonPassNote"
    note.text = "💡 XP дают победы, задания и активности. Каждый 5-й уровень даёт дополнительный ключ. Редкие и комбинированные награды встречаются чаще на высоких уровнях."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 14)
    note.modulate = Color("#BCA996")
    v.add_child(note)

    var close := Button.new()
    close.text = "←  НАЗАД"
    close.custom_minimum_size = Vector2(0, 70)
    style_button(close, Color("#9A7653"))
    close.pressed.connect(close_gameplay_overlay)
    v.add_child(close)
    return p

func refresh_season_pass_panel() -> void:
    if not season_pass_panel:
        return
    var info := season_pass_panel.get_node_or_null("ScrollContainer/SeasonPassContent/SeasonPassInfo") as Label
    if info:
        info.text = "Уровень %d/%d   •   XP %d/100" % [season_pass_level, SEASON_PASS_MAX_LEVEL, season_pass_xp]
    var progress := season_pass_panel.get_node_or_null("ScrollContainer/SeasonPassContent/SeasonPassProgress") as ProgressBar
    if progress:
        progress.value = float(season_pass_xp)
    var tracks := season_pass_panel.get_node_or_null("ScrollContainer/SeasonPassContent/SeasonPassTracks") as Label
    if tracks:
        tracks.text = "БЕСПЛАТНАЯ ЛИНИЯ  •  💰 рубли  🔑 ключи  ⚙ детали  📦 сундуки  •  🎁 бонус на каждом 5-м уровне"
    var levels := season_pass_panel.get_node_or_null("ScrollContainer/SeasonPassContent/SeasonLevels") as GridContainer
    if levels:
        for i in range(levels.get_child_count()):
            var card := levels.get_child(i) as PanelContainer
            if not card:
                continue
            var lvl := i + 1
            var reward := season_pass_reward(lvl)
            var box := card.get_node_or_null("RewardBox") as VBoxContainer
            if not box:
                continue
            var level_label := box.get_node_or_null("Level") as Label
            var reward_label := box.get_node_or_null("Reward") as Label
            var state_label := box.get_node_or_null("State") as Label
            if level_label:
                level_label.text = "УРОВЕНЬ %02d" % lvl
            if reward_label:
                var reward_text := String(reward.get("text", "Награда"))
                if lvl % 5 == 0:
                    reward_text += "  🎁 +1 КЛЮЧ"
                reward_label.text = reward_text
            if state_label:
                if lvl < season_pass_level:
                    state_label.text = "✓ ПОЛУЧЕНО"
                    state_label.modulate = Color("#86C98A")
                elif lvl == season_pass_level:
                    state_label.text = "★ ТЕКУЩИЙ УРОВЕНЬ"
                    state_label.modulate = Color("#DDB47A")
                else:
                    state_label.text = "🔒 НУЖНО XP: %d" % ((lvl - season_pass_level) * 100 - season_pass_xp)
                    state_label.modulate = Color("#A99682")

func build_promo_panel() -> PanelContainer:
    var p:=build_info_menu_panel("PromoPanel",Vector2(970,620))
    var v:=VBoxContainer.new(); v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); v.add_theme_constant_override("separation",14); p.add_child(v)
    add_panel_title(v,"🎟  ПРОМОКОДЫ")
    var info:=Label.new(); info.text="Введите специальный код и получите игровую награду."; info.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.add_theme_font_size_override("font_size",18); info.modulate=Color("#D8C3AA"); v.add_child(info)
    var code:=LineEdit.new(); code.name="PromoCode"; code.placeholder_text="Введите промокод"; code.custom_minimum_size=Vector2(0,62); code.add_theme_font_size_override("font_size",20); v.add_child(code)
    var redeem:=Button.new(); redeem.text="АКТИВИРОВАТЬ КОД"; redeem.custom_minimum_size=Vector2(0,70); style_button(redeem,Color("#76583F")); redeem.add_theme_font_size_override("font_size",20); redeem.pressed.connect(func(): redeem_promo_code(code.text)); v.add_child(redeem)
    var status:=Label.new(); status.name="PromoStatus"; status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status.add_theme_font_size_override("font_size",18); status.modulate=Color("#D8C3AA"); v.add_child(status)
    var hint:=Label.new(); hint.text="Доступные коды выдаются в новостях и событиях игры."; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; hint.add_theme_font_size_override("font_size",15); hint.modulate=Color("#BCA996"); v.add_child(hint)
    var close:=Button.new(); close.text="←  НАЗАД"; close.custom_minimum_size=Vector2(0,72); style_button(close,Color("#9A7653")); close.pressed.connect(show_main_menu); v.add_child(close)
    return p

func refresh_promo_panel() -> void:
    if not promo_panel:return
    var status:=promo_panel.get_node_or_null("PromoStatus") as Label
    if status: status.text=promo_status

func build_news_panel() -> PanelContainer:
    var p:=build_info_menu_panel("NewsPanel",Vector2(970,900))
    var scroll:=ScrollContainer.new(); scroll.name="ScrollContainer"; scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(scroll)
    var v:=VBoxContainer.new(); v.name="NewsContent"; v.custom_minimum_size=Vector2(900,0); v.add_theme_constant_override("separation",12); scroll.add_child(v)
    add_panel_title(v,"📰  НОВОСТИ")
    var intro:=Label.new(); intro.text="Здесь будут появляться новости игры, события, новые функции, игрушки и новые промокоды."; intro.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; intro.add_theme_font_size_override("font_size",18); intro.modulate=Color("#D8C3AA"); v.add_child(intro)
    var list:=VBoxContainer.new(); list.name="NewsList"; list.add_theme_constant_override("separation",10); v.add_child(list)
    var close:=Button.new(); close.text="←  НАЗАД"; close.custom_minimum_size=Vector2(0,74); style_button(close,Color("#9A7653")); close.pressed.connect(show_main_menu); v.add_child(close)
    refresh_news_panel(p)
    return p

func refresh_news_panel(panel: PanelContainer = null) -> void:
    var target:=panel if panel != null else news_panel
    if target == null: return
    var list:=target.get_node_or_null("ScrollContainer/NewsContent/NewsList") as VBoxContainer
    if list == null: return
    for child in list.get_children(): child.queue_free()
    for item in news_items:
        var card:=PanelContainer.new()
        card.custom_minimum_size=Vector2(0,145)
        style_panel(card,Color("#241B16"),Color("#76583F"),18,2)
        var cv:=VBoxContainer.new(); cv.add_theme_constant_override("separation",5); card.add_child(cv)
        var title:=Label.new(); title.text="%s  •  %s" % [String(item.get("date","")),String(item.get("title",""))]; title.add_theme_font_size_override("font_size",21); title.modulate=Color("#E1C29A"); cv.add_child(title)
        var body:=Label.new(); body.text=String(item.get("text","")); body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.add_theme_font_size_override("font_size",17); body.modulate=Color("#D8C3AA"); cv.add_child(body)
        var read_button:=Button.new(); read_button.text="ПРОЧИТАНО"; read_button.custom_minimum_size=Vector2(0,48); style_button(read_button,Color("#76583F")); var news_id:=String(item.get("id","")); read_button.pressed.connect(func():
            if _server_ready() and player_token != "":
                _server_action("news_read", {"news_id":news_id})
            news_unread = maxi(0, news_unread - 1)
            read_button.disabled = true
        ); cv.add_child(read_button)
        list.add_child(card)
    # Индикатор снимается только после серверного подтверждения прочтения.

func build_rating_panel() -> PanelContainer:
    var p:=build_info_menu_panel("RatingPanel",Vector2(970,900))
    var scroll:=ScrollContainer.new(); scroll.name="ScrollContainer"; scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.add_child(scroll)
    var v:=VBoxContainer.new(); v.name="RatingContent"; v.custom_minimum_size=Vector2(900,0); v.add_theme_constant_override("separation",9); scroll.add_child(v)
    add_panel_title(v,"🏆  РЕЙТИНГ")
    var note:=Label.new(); note.text="🌐 ОБЩИЙ ОНЛАЙН-РЕЙТИНГ • данные игроков загружаются с сервера"; note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; note.add_theme_font_size_override("font_size",16); note.modulate=Color("#BCA996"); v.add_child(note)
    var list:=VBoxContainer.new(); list.name="Leaderboard"; list.add_theme_constant_override("separation",7); v.add_child(list)
    var close:=Button.new(); close.text="←  НАЗАД"; close.custom_minimum_size=Vector2(0,74); style_button(close,Color("#9A7653")); close.pressed.connect(show_main_menu); v.add_child(close)
    return p

func refresh_rating_panel() -> void:
    if not rating_panel:return
    var list:=rating_panel.get_node_or_null("ScrollContainer/RatingContent/Leaderboard") as VBoxContainer
    if not list:return
    for c in list.get_children():c.queue_free()
    var rows: Array = remote_leaderboard
    if rows.is_empty():
        var empty := Label.new()
        empty.text = "⏳ ПОДКЛЮЧАЕМСЯ К ОНЛАЙН-РЕЙТИНГУ…" if remote_sync_status != "ОШИБКА СЕРВЕРА" else "⚠ НЕТ СВЯЗИ С СЕРВЕРОМ
Попробуйте открыть рейтинг ещё раз."
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.add_theme_font_size_override("font_size", 19)
        empty.modulate = Color("#BCA996")
        list.add_child(empty)
        return
    for i in range(rows.size()):
        var row:=Label.new(); row.text="%d.  %s   •   %d" % [i+1,String(rows[i]["name"]),int(rows[i]["score"])] ; row.add_theme_font_size_override("font_size",20); row.modulate=GOLD if String(rows[i]["name"])==player_name else Color("#E0D4C6"); list.add_child(row)

func build_return_bonus_panel() -> PanelContainer:
    var p:=build_info_menu_panel("ReturnBonusPanel",Vector2(970,620))
    var v:=VBoxContainer.new(); v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); v.add_theme_constant_override("separation",14); p.add_child(v)
    add_panel_title(v,"🎁  БОНУС ЗА ВОЗВРАЩЕНИЕ")
    var info:=Label.new(); info.name="ReturnBonusInfo"; info.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.add_theme_font_size_override("font_size",20); info.modulate=Color("#D8C3AA"); v.add_child(info)
    var claim:=Button.new(); claim.name="ClaimButton"; claim.custom_minimum_size=Vector2(0,78); style_button(claim,Color("#76583F")); claim.add_theme_font_size_override("font_size",20); claim.pressed.connect(claim_return_bonus); v.add_child(claim)
    var close:=Button.new(); close.text="←  НАЗАД"; close.custom_minimum_size=Vector2(0,72); style_button(close,Color("#9A7653")); close.pressed.connect(show_main_menu); v.add_child(close)
    return p

func refresh_return_bonus_panel() -> void:
    if not return_bonus_panel:return
    update_return_bonus_state()
    var info:=return_bonus_panel.get_node_or_null("ReturnBonusInfo") as Label
    var claim:=return_bonus_panel.get_node_or_null("ClaimButton") as Button
    if return_bonus_available:
        if info: info.text="Ты отсутствовал %d дн.\nДоступная награда: +%d ₽" % [return_bonus_days,return_bonus_amount]
        if claim: claim.text="🎁  ЗАБРАТЬ +%d ₽" % return_bonus_amount; claim.disabled=false
    else:
        if info: info.text="Бонус станет доступен после периода отсутствия.\nЗа более долгий перерыв награда увеличивается."
        if claim: claim.text="БОНУС ЕЩЁ НЕ ДОСТУПЕН"; claim.disabled=true

func build_live_systems_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.name = "LiveSystemsPanel"
    p.position = Vector2(35, 150)
    p.size = Vector2(1010, 1600)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)
    var scroll := ScrollContainer.new()
    scroll.name = "ScrollContainer"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    p.add_child(scroll)
    var v := VBoxContainer.new()
    v.name = "SystemsContent"
    v.custom_minimum_size = Vector2(900, 0)
    v.add_theme_constant_override("separation", 10)
    scroll.add_child(v)
    var title := Label.new(); title.text = "🚀  ЦЕНТР ИГРОВЫХ СИСТЕМ"; title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",30); title.modulate=Color("#E1C29A"); v.add_child(title)
    var info := Label.new(); info.name="SystemsInfo"; info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; info.add_theme_font_size_override("font_size",18); info.modulate=Color("#D8C3AA"); v.add_child(info)
    var ntitle := Label.new(); ntitle.text="🔔 УМНЫЕ УВЕДОМЛЕНИЯ"; ntitle.add_theme_font_size_override("font_size",21); ntitle.modulate=GOLD; v.add_child(ntitle)
    for item in [["notify_rewards_on","🎁 Награды"],["notify_streak_on","🔥 Серия входов"],["notify_events_on","🎪 События и сезон"],["notify_workshop_on","🔧 Мастерская"],["notify_chests_on","📦 Сундуки"]]:
        var cb := CheckButton.new(); cb.text=String(item[1]); cb.button_pressed=bool(get(String(item[0]))); cb.add_theme_font_size_override("font_size",18); cb.toggled.connect(func(on: bool, key: String=String(item[0])): set(key,on); save_game(); cancel_background_notifications(); schedule_background_notifications(); refresh_live_systems_panel()); v.add_child(cb)
    var return_title := Label.new(); return_title.text="🎁 БОНУС ЗА ВОЗВРАЩЕНИЕ"; return_title.add_theme_font_size_override("font_size",21); return_title.modulate=GOLD; v.add_child(return_title)
    var return_btn := Button.new(); return_btn.name="ReturnBonusButton"; return_btn.custom_minimum_size=Vector2(0,70); style_button(return_btn,Color("#76583F")); return_btn.add_theme_font_size_override("font_size",18); return_btn.pressed.connect(claim_return_bonus); v.add_child(return_btn)
    var job_title := Label.new(); job_title.text="🔧 ФОНОВАЯ РАБОТА МАСТЕРСКОЙ"; job_title.add_theme_font_size_override("font_size",21); job_title.modulate=GOLD; v.add_child(job_title)
    var job_btn := Button.new(); job_btn.name="WorkshopJobButton"; job_btn.custom_minimum_size=Vector2(0,70); style_button(job_btn,Color("#76583F")); job_btn.add_theme_font_size_override("font_size",18); job_btn.pressed.connect(start_workshop_job); v.add_child(job_btn)
    var season_pass_info := Label.new(); season_pass_info.name="SeasonPassInfo"; season_pass_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; season_pass_info.add_theme_font_size_override("font_size",18); season_pass_info.modulate=Color("#E0D4C6"); v.add_child(season_pass_info)
    var promo_title := Label.new(); promo_title.text="🎟 ПРОМОКОДЫ"; promo_title.add_theme_font_size_override("font_size",21); promo_title.modulate=GOLD; v.add_child(promo_title)
    var code := LineEdit.new(); code.name="PromoCode"; code.placeholder_text="Введите код"; code.custom_minimum_size=Vector2(0,56); code.add_theme_font_size_override("font_size",18); v.add_child(code)
    var redeem := Button.new(); redeem.text="АКТИВИРОВАТЬ КОД"; redeem.custom_minimum_size=Vector2(0,64); style_button(redeem,Color("#76583F")); redeem.add_theme_font_size_override("font_size",18); redeem.pressed.connect(func(): redeem_promo_code(code.text)); v.add_child(redeem)
    var ps := Label.new(); ps.name="PromoStatus"; ps.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; ps.add_theme_font_size_override("font_size",16); ps.modulate=Color("#D8C3AA"); v.add_child(ps)
    var lb_title := Label.new(); lb_title.text="🏆 РЕЙТИНГ"; lb_title.add_theme_font_size_override("font_size",21); lb_title.modulate=GOLD; v.add_child(lb_title)
    var lb_note := Label.new(); lb_note.text="Локальный предпросмотр. Для настоящего общего рейтинга всех игроков нужен сервер."; lb_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; lb_note.add_theme_font_size_override("font_size",14); lb_note.modulate=Color("#BCA996"); v.add_child(lb_note)
    var lb := VBoxContainer.new(); lb.name="Leaderboard"; lb.add_theme_constant_override("separation",5); v.add_child(lb)
    var cloud := Label.new(); cloud.text="☁ ОБЛАЧНОЕ СОХРАНЕНИЕ\nАрхитектура сохранения готова к подключению серверного API. Сейчас прогресс хранится локально, чтобы не создавать фиктивную синхронизацию."; cloud.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; cloud.add_theme_font_size_override("font_size",16); cloud.modulate=Color("#D8C3AA"); v.add_child(cloud)
    var close := Button.new(); close.text="←  НАЗАД"; close.custom_minimum_size=Vector2(0,74); style_button(close,Color("#9A7653")); close.pressed.connect(close_gameplay_overlay); v.add_child(close)
    refresh_live_systems_panel()
    return p

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

func set_loading_status(text: String) -> void:
    # Меняет только описание текущей операции. Процент не двигается, пока
    # операция действительно не завершена.
    if loading_status:
        loading_status.text = text
    if loading_stage:
        loading_stage.text = "ВЫПОЛНЯЕТСЯ • %s" % text
    await get_tree().process_frame

func set_loading_progress(value: float, text: String) -> void:
    # Процент показывает только ЗАВЕРШЁННУЮ операцию. Пока операция выполняется,
    # индикатор остаётся на предыдущем подтверждённом значении.
    var safe_value := clampf(value, 0.0, 100.0)
    loading_step_index += 1
    if loading_progress:
        loading_progress.value = safe_value
    if loading_percent:
        loading_percent.text = "%d%%" % int(safe_value)
    if loading_status:
        loading_status.text = text
    if loading_stage:
        loading_stage.text = "ШАГ %d • %s" % [loading_step_index, text]
    await get_tree().process_frame

func initialize_game_async() -> void:
    # Реальный последовательный загрузчик: процент продвигается только после
    # фактического завершения соответствующей операции. Между тяжёлыми этапами
    # обязательно отдаём кадр движку, чтобы загрузочный экран оставался живым.
    await get_tree().process_frame

    await set_loading_status("ЗАГРУЖАЕМ ПРОФИЛЬ И РЕФЕРАЛЬНЫЕ ДАННЫЕ...")
    ensure_referral_code()
    process_incoming_referral()
    await set_loading_progress(5.0, "ПРОФИЛЬ ПОДГОТОВЛЕН")
    await set_loading_status("СОЗДАЁМ ИГРОВОЙ МИР И ПРИМЕНЯЕМ КАЧЕСТВО...")
    build_world()
    apply_quality_settings()
    await set_loading_progress(15.0, "МИР СОЗДАН")
    await set_loading_status("СОЗДАЁМ АВТОМАТ И АКТИВИРУЕМ СОБЫТИЕ...")
    build_machine()
    activate_calendar_event()
    await set_loading_progress(30.0, "АВТОМАТ СОЗДАН")
    await set_loading_status("СОЗДАЁМ РЕЛЬСЫ, КЛЕШНЮ И ПРИЦЕЛ...")
    build_overhead_rails()
    await get_tree().process_frame
    build_claw()
    await get_tree().process_frame
    build_aim_marker()
    await get_tree().process_frame
    await set_loading_progress(43.0, "МЕХАНИКА КЛЕШНИ ПОДГОТОВЛЕНА")
    await set_loading_status("ЗАГРУЖАЕМ И СОЗДАЁМ ИГРУШКИ...")
    await build_prizes_async()
    await get_tree().process_frame
    await set_loading_progress(62.0, "ИГРУШКИ ЗАГРУЖЕНЫ")

    # В проекте GPUParticles3D сейчас намеренно отключены. Поэтому не делаем
    # фиктивный тяжёлый этап: здесь только фиксируем реальное состояние эффектов.
    await set_loading_status("ПРОВЕРЯЕМ ВИЗУАЛЬНЫЕ ЭФФЕКТЫ И ОСВЕЩЕНИЕ...")
    sparkle_particles = null
    await get_tree().process_frame
    await set_loading_progress(72.0, "ВИЗУАЛЬНЫЕ ЭФФЕКТЫ ПРОВЕРЕНЫ")
    await get_tree().process_frame

    await build_ui()

    await set_loading_status("ЗАГРУЖАЕМ ЗВУКОВЫЕ РЕСУРСЫ...")
    build_audio()
    await get_tree().process_frame
    await set_loading_progress(97.0, "ЗВУК ПОДГОТОВЛЕН")
    await set_loading_status("ПРИМЕНЯЕМ ВИЗУАЛЬНЫЕ НАСТРОЙКИ МАГАЗИНА...")
    apply_shop_visuals()
    await get_tree().process_frame
    await set_loading_progress(98.0, "НАСТРОЙКИ МАГАЗИНА ПРИМЕНЕНЫ")
    await set_loading_status("ПОДГОТАВЛИВАЕМ БОНУСЫ, СОХРАНЕНИЕ И СОБЫТИЯ...")
    setup_daily_systems()
    await get_tree().process_frame
    setup_login_streak()
    await get_tree().process_frame
    setup_events()
    await get_tree().process_frame
    update_ui()
    await get_tree().process_frame
    apply_quality_settings()
    await get_tree().process_frame
    await set_loading_progress(99.0, "БОНУСЫ И СОХРАНЕНИЕ ПОДГОТОВЛЕНЫ")

    # До этой точки НИ ОДНО пользовательское меню и сам игровой экран не
    # должны быть видимы. Всё подготавливаем скрытым под загрузчиком.
    await set_loading_status("ФИНАЛЬНАЯ ПРОВЕРКА И ПОДГОТОВКА ИГРОВОГО ЭКРАНА...")
    close_all_panels()
    if menu_layer and is_instance_valid(menu_layer):
        menu_layer.visible = false
    set_main_menu_controls(false)
    if hud_layer and is_instance_valid(hud_layer):
        hud_layer.visible = false
    set_gameplay_3d_visible(false)
    current_result = "ГОТОВ К ИГРЕ"
    update_ui()
    await get_tree().process_frame

    # КРИТИЧЕСКИЙ ПОРЯДОК ПЕРЕХОДА:
    # 1) сначала показываем на загрузочном экране настоящий 100%;
    # 2) отдаём движку кадр, чтобы пользователь реально увидел 100%;
    # 3) только после этого убираем загрузчик и показываем игровой экран.
    await set_loading_progress(100.0, "ГОТОВО — ИГРОВОЙ ЭКРАН ПОДГОТОВЛЕН")
    await get_tree().process_frame

    game_initialized = true
    register_game_activity()
    if loading_screen and is_instance_valid(loading_screen):
        loading_screen.visible = false

    if hud_layer and is_instance_valid(hud_layer):
        hud_layer.visible = true
    set_gameplay_3d_visible(true)
    update_ui()
    await get_tree().process_frame

    # Удаляем загрузчик уже после фактического переключения на игру.
    if loading_screen and is_instance_valid(loading_screen):
        loading_screen.queue_free()
    loading_screen = null


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
        last_active_unix = int(Time.get_unix_time_from_system())
        save_game()
        if what == NOTIFICATION_APPLICATION_PAUSED:
            notify_daily_bonus_if_available()
    elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
        if _visible_navigation_context() != "":
            _on_android_back_pressed()

func make_fur_mat(color: Color) -> ShaderMaterial:
    # Процедурный материал мягкого плюша: матовая ткань, мелкая неоднородность
    # и лёгкий "ворс" по краям без тяжёлых внешних 3D-моделей.
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color;
uniform float fuzz = 0.035;
uniform float skin_style = 0.0;

float hash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

void vertex() {
    float n = hash13(VERTEX * 48.0 + NORMAL * 7.0);
    float edge = pow(1.0 - max(dot(NORMAL, vec3(0.0, 0.0, 1.0)), 0.0), 2.0);
    VERTEX += NORMAL * ((n - 0.5) * fuzz + edge * fuzz * 0.45);
}

void fragment() {
    vec3 q = vec3(UV * 8.0, 0.0);
    float n1 = hash13(q);
    float n2 = hash13(q * 2.17 + 11.0);
    float fabric = mix(n1, n2, 0.35);
    float shade = 0.90 + fabric * 0.12;
    vec3 c = base_color.rgb;
    float st = mod(floor(skin_style + 0.5), 12.0);
    if (st == 1.0) {
        float stripes = step(0.52, fract(UV.y * 7.0));
        c = mix(c, vec3(0.98, 0.98, 1.0), stripes * 0.45);
    } else if (st == 2.0) {
        vec2 p = fract(UV * 6.0) - 0.5;
        float dots = 1.0 - step(0.16, length(p));
        c = mix(c, vec3(0.08, 0.02, 0.20), dots * 0.72);
    } else if (st == 3.0) {
        c = mix(c, vec3(1.0, 0.68, 0.08), 0.32);
        METALLIC = 0.35;
        ROUGHNESS = 0.48;
    } else if (st == 4.0) {
        c = mix(c, vec3(0.82, 0.90, 1.0), 0.48);
        METALLIC = 0.42;
        ROUGHNESS = 0.34;
    } else if (st == 5.0) {
        float stars = step(0.965, hash13(vec3(floor(UV * 18.0), 0.0)));
        c = mix(c, vec3(0.08, 0.02, 0.25), 0.55);
        c += vec3(0.35, 0.55, 1.0) * stars;
    } else if (st == 6.0) {
        float fire = clamp(UV.y + 0.20 * sin(UV.x * 18.0), 0.0, 1.0);
        c = mix(vec3(0.95, 0.08, 0.015), vec3(1.0, 0.72, 0.03), fire);
    } else if (st == 7.0) {
        c = mix(c, vec3(0.55, 0.95, 1.0), 0.42);
        c += vec3(0.18, 0.35, 0.48) * (1.0 - UV.y);
    } else if (st == 8.0) {
        c = 0.5 + 0.5 * cos(vec3(0.0, 2.1, 4.2) + UV.x * 8.0 + UV.y * 5.0);
    } else if (st == 9.0) {
        float gx = step(0.88, fract(UV.x * 12.0));
        float gy = step(0.88, fract(UV.y * 12.0));
        c = mix(c, vec3(0.03, 0.18, 0.08), 0.58);
        c += vec3(0.10, 1.0, 0.40) * max(gx, gy) * 0.65;
    } else if (st == 10.0) {
        c = mix(c, vec3(0.025, 0.03, 0.05), 0.78);
        c += vec3(0.16, 0.20, 0.28) * fabric;
    } else if (st == 11.0) {
        c = mix(c, vec3(1.0, 0.48, 0.05), 0.38);
        c += vec3(0.75, 0.22, 0.95) * pow(max(0.0, sin(UV.x * 14.0 + UV.y * 11.0)), 8.0) * 0.55;
        METALLIC = 0.22;
    }
    ALBEDO = c * shade;
    if (st == 2.0 || st == 5.0 || st == 8.0 || st == 9.0 || st == 11.0) EMISSION = c * 0.10;
    if (st != 0.0 && st != 1.0 && st != 2.0 && st != 6.0 && st != 7.0 && st != 10.0) ROUGHNESS = min(ROUGHNESS, 0.72);
    SPECULAR = 0.12;
}
"""
    shader.set_code(shader.code)
    var mat := ShaderMaterial.new()
    mat.shader = shader
    mat.set_shader_parameter("base_color", color)
    mat.set_shader_parameter("fuzz", 0.035)
    return mat

func make_mat(color: Color, metallic: float = 0.0, roughness: float = 0.5, emission_strength: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    if emission_strength > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emission_strength
    return m

func make_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, node_name: String = "Box") -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = material
    n.position = pos
    parent.add_child(n)
    return n

func make_static_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, node_name: String = "StaticBox") -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name + "Collision"
    body.position = pos
    parent.add_child(body)
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.name = node_name
    visual.mesh = mesh
    visual.material_override = material
    body.add_child(visual)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    return body

func make_collision_box(parent: Node3D, size: Vector3, pos: Vector3, node_name: String = "CollisionBox") -> StaticBody3D:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    parent.add_child(body)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    return body

func make_sphere(parent: Node3D, radius: float, pos: Vector3, material: Material, node_name: String = "Sphere") -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = node_name
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 32
    mesh.rings = 18
    n.mesh = mesh
    n.material_override = material
    n.position = pos
    parent.add_child(n)
    return n

func make_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, node_name: String = "Cylinder") -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = node_name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 32
    n.mesh = mesh
    n.material_override = material
    n.position = pos
    parent.add_child(n)
    return n

func make_tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material, node_name: String = "Tube") -> MeshInstance3D:
    var n := make_cylinder(parent, radius, a.distance_to(b), (a + b) * 0.5, material, node_name)
    n.look_at(b, Vector3.UP)
    n.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    return n

func build_world() -> void:
    var env_node := WorldEnvironment.new()
    world_environment = env_node
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#17110D")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#C7B39A")
    env.ambient_light_energy = 0.65
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = false
    env_node.environment = env
    add_child(env_node)

    camera = Camera3D.new()
    camera.name = "CinematicCamera"
    camera.position = camera_base
    camera.fov = 56.0
    add_child(camera)
    camera.look_at(camera_look, Vector3.UP)

    var reflection: ReflectionProbe = ReflectionProbe.new()
    reflection_probe = reflection
    reflection.position = Vector3(0.0, 5.2, 0.0)
    reflection.size = Vector3(9.0, 8.0, 6.0)
    reflection.origin_offset = Vector3(0.0, 1.0, 0.0)
    reflection.intensity = 1.25
    add_child(reflection)

    var floor_mat := make_mat(Color("#2A211B"), 0.55, 0.30)
    make_box(self, Vector3(24, 0.3, 22), Vector3(0, -0.3, 0), floor_mat, "PolishedFloor")
    make_box(self, Vector3(24, 9, 0.2), Vector3(0, 4.2, -7.8), make_mat(Color("#24211E"), 0.05, 0.72), "BackWall")
    make_box(self, Vector3(0.12, 9, 22), Vector3(-11.8, 4.2, 0), make_mat(Color("#302B27"), 0.12, 0.62), "LeftWall")
    make_box(self, Vector3(0.12, 9, 22), Vector3(11.8, 4.2, 0), make_mat(Color("#302B27"), 0.12, 0.62), "RightWall")

    for z in [-5.5, -2.0, 1.5, 5.0]:
        make_box(self, Vector3(21.0, 0.025, 0.035), Vector3(0, -0.13, z), make_mat(Color("#4B3525"), 0.10, 0.45), "FloorInlay")

    var key := OmniLight3D.new()
    key.position = Vector3(0, 9.5, 8.0)
    key.light_energy = 8.5
    key.omni_range = 23.0
    key.light_color = Color("#FFE9CE")
    add_child(key)
    scene_lights.append(key)

    var fill := OmniLight3D.new()
    fill.position = Vector3(-7, 5, 3)
    fill.light_energy = 2.5
    fill.omni_range = 12.0
    fill.light_color = Color("#E7D2B7")
    add_child(fill)
    scene_lights.append(fill)

    var fill2 := OmniLight3D.new()
    fill2.position = Vector3(7, 5, 2)
    fill2.light_energy = 3.8
    fill2.omni_range = 15.0
    fill2.light_color = Color("#F2E4D0")
    add_child(fill2)
    scene_lights.append(fill2)


func build_machine() -> void:
    machine = Node3D.new()
    machine.name = "PremiumClawMachine"
    add_child(machine)

    var base_mat := make_mat(Color("#4A3022"), 0.18, 0.38)
    var dark_mat := make_mat(Color("#241B16"), 0.45, 0.34)
    var chrome := make_mat(Color("#7C817F"), 0.92, 0.20)
    var chrome_dark := make_mat(Color("#414744"), 0.88, 0.26)
    var wood_dark := make_mat(Color("#352116"), 0.05, 0.50)
    var wood_mid := make_mat(Color("#74482C"), 0.03, 0.48)
    var wood_light := make_mat(Color("#A36A3D"), 0.02, 0.50)

    make_box(machine, Vector3(7.8, 0.9, 5.4), Vector3(0, 0.25, 0.25), base_mat, "HeavyBase")
    make_box(machine, Vector3(7.35, 1.85, 5.10), Vector3(0, 1.62, 0.25), dark_mat, "ServiceCabinet")
    make_box(machine, Vector3(7.5, 0.25, 5.2), Vector3(0, 2.63, 0.22), chrome_dark, "ControlCounter")

    # Высокая деревянная рама корпуса — как у дорогого физического автомата.
    make_box(machine, Vector3(0.42, 8.45, 0.42), Vector3(-3.55, 6.12, 2.35), wood_mid, "WoodFrontLeft")
    make_box(machine, Vector3(0.42, 8.45, 0.42), Vector3(3.55, 6.12, 2.35), wood_mid, "WoodFrontRight")
    make_box(machine, Vector3(7.25, 0.42, 0.42), Vector3(0, 10.20, 2.35), wood_light, "WoodTopFront")
    make_box(machine, Vector3(7.25, 0.38, 0.38), Vector3(0, 2.98, 2.35), wood_dark, "WoodLowerFront")
    make_box(machine, Vector3(0.34, 7.2, 0.34), Vector3(-3.58, 5.95, -2.35), wood_dark, "WoodBackLeft")
    make_box(machine, Vector3(0.34, 7.2, 0.34), Vector3(3.58, 5.95, -2.35), wood_dark, "WoodBackRight")

    # Glass panels with low roughness, metallic frames and reflection probe support.
    var glass := StandardMaterial3D.new()
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.albedo_color = Color(0.82, 0.90, 0.95, 0.10)
    glass.metallic = 0.08
    glass.roughness = 0.12
    make_box(machine, Vector3(6.9, 8.10, 0.08), Vector3(0, 6.20, 2.18), glass, "FrontGlass")
    make_box(machine, Vector3(6.9, 8.10, 0.08), Vector3(0, 6.20, -2.18), glass, "BackGlass")
    make_box(machine, Vector3(0.08, 8.10, 4.35), Vector3(-3.45, 6.20, 0), glass, "LeftGlass")
    make_box(machine, Vector3(0.08, 8.10, 4.35), Vector3(3.45, 6.20, 0), glass, "RightGlass")

    # Усиленные невидимые физические стенки прямо внутри стекла.
    # Они толще самого стекла, имеют большой запас по высоте и закрывают
    # все четыре стороны камеры, поэтому быстрые RigidBody игрушки не могут
    # протуннелировать сквозь стекло.
    make_collision_box(machine, Vector3(0.34, 7.85, 4.18), Vector3(-3.18, 6.45, 0.0), "LeftGlassCollision")
    make_collision_box(machine, Vector3(0.34, 7.85, 4.18), Vector3(3.18, 6.45, 0.0), "RightGlassCollision")
    make_collision_box(machine, Vector3(6.35, 7.85, 0.34), Vector3(0.0, 6.45, -1.90), "BackGlassCollision")
    make_collision_box(machine, Vector3(6.35, 7.85, 0.34), Vector3(0.0, 6.45, 1.90), "FrontGlassCollision")

    for x in [-3.55, 3.55]:
        for z in [-2.32, 2.32]:
            make_box(machine, Vector3(0.3, 6.1, 0.3), Vector3(x, 6.05, z), chrome, "ChromePost")
            make_sphere(machine, 0.08, Vector3(x, 8.05, z), chrome, "FrameBolt")

    # Top marquee, bevel-like layered geometry and glowing logo.
    make_box(machine, Vector3(8.3, 1.15, 5.75), Vector3(0, 10.05, 0.22), base_mat, "MarqueeHousing")
    make_box(machine, Vector3(6.95, 0.42, 0.12), Vector3(0, 10.12, 2.70), wood_light, "MarqueeTrim")
    make_box(machine, Vector3(6.65, 0.035, 0.08), Vector3(0, 9.88, 2.72), chrome, "MarqueeAccent")
    make_box(machine, Vector3(6.65, 0.30, 0.12), Vector3(0, 10.09, 2.78), make_mat(Color("#0B1631"), 0.7, 0.14), "MarqueeFace")
    var logo := Label3D.new()
    logo.text = "ХВАТАЙКА"
    logo.font_size = 72
    logo.outline_size = 12
    logo.modulate = Color.WHITE
    logo.position = Vector3(0, 10.10, 2.73)
    logo.pixel_size = 0.0036
    machine.add_child(logo)

    # Interior LED bars.
    for x in [-3.0, 0.0, 3.0]:
        make_box(machine, Vector3(0.07, 0.05, 4.4), Vector3(x, 9.60, 0), make_mat(Color("#E6D7C2"), 0.0, 0.55), "CeilingLight")
    # Пол камеры разделён вокруг отверстия: под игрушками есть реальная физическая опора,
    # а в зоне выдачи нет пола — игрушка действительно проваливается в шахту.
    var prize_floor_mat := make_mat(Color("#3B3027"), 0.35, 0.42)
    var hole_left := PRIZE_HOLE.x - 0.78
    var hole_right := 3.45
    var back_depth := PRIZE_HOLE.z - 0.48 - (-2.125)
    var front_depth := 2.125 - (PRIZE_HOLE.z + 0.48)
    var left_width := hole_left - (-3.45)
    make_static_box(machine, Vector3(left_width, 0.22, 4.25), Vector3((-3.45 + hole_left) * 0.5, 3.02, 0), prize_floor_mat, "PrizePlatformLeft")
    if back_depth > 0.05:
        make_static_box(machine, Vector3(hole_right - hole_left, 0.22, back_depth), Vector3((hole_left + hole_right) * 0.5, 3.02, (-2.125 + PRIZE_HOLE.z - 0.48) * 0.5), prize_floor_mat, "PrizePlatformBack")
    if front_depth > 0.05:
        make_static_box(machine, Vector3(hole_right - hole_left, 0.22, front_depth), Vector3((hole_left + hole_right) * 0.5, 3.02, (PRIZE_HOLE.z + 0.48 + 2.125) * 0.5), prize_floor_mat, "PrizePlatformFront")
    make_static_box(machine, Vector3(0.55, 0.22, 4.25), Vector3(3.175, 3.02, 0), prize_floor_mat, "PrizePlatformRight")
    make_box(machine, Vector3(6.3, 0.08, 0.08), Vector3(0, 3.15, 2.10), chrome, "FrontFloorTrim")

    # Большое видимое внутреннее отверстие выдачи: игрушка реально направляется сюда.
    make_box(machine, Vector3(1.55, 0.12, 1.30), Vector3(PRIZE_HOLE.x, 3.15, PRIZE_HOLE.z), chrome_dark, "PrizeHoleFrame")
    make_box(machine, Vector3(1.18, 0.16, 0.96), Vector3(PRIZE_HOLE.x, 3.06, PRIZE_HOLE.z), make_mat(Color("#010205"), 0.25, 0.12), "PrizeHole")
    make_box(machine, Vector3(0.96, 0.55, 0.78), Vector3(PRIZE_HOLE.x, 2.76, PRIZE_HOLE.z), make_mat(Color("#0B0907"), 0.15, 0.22), "PrizeHoleDepth")
    make_box(machine, Vector3(1.02, 0.055, 0.055), Vector3(PRIZE_HOLE.x, 3.15, PRIZE_HOLE.z - 0.48), chrome, "PrizeHoleTrim")

    # Высокое прозрачное пластиковое ограждение вокруг отверстия.
    # Визуальные панели прозрачные, а внутри них есть невидимые коллайдеры,
    # поэтому обычные игрушки не смогут случайно скатиться в шахту.
    var hole_guard_mat := StandardMaterial3D.new()
    hole_guard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    hole_guard_mat.albedo_color = Color(0.78, 0.86, 0.90, 0.30)
    hole_guard_mat.metallic = 0.0
    hole_guard_mat.roughness = 0.10
    hole_guard_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var guard_h := 2.45
    var guard_t := 0.12
    var guard_y := 3.02 + guard_h * 0.5
    var guard_w := 1.70
    var guard_d := 1.44
    var opening_w := 1.18
    var opening_d := 0.96
    make_box(machine, Vector3(guard_t, guard_h, guard_d), Vector3(PRIZE_HOLE.x - (opening_w * 0.5 + guard_t * 0.5), guard_y, PRIZE_HOLE.z), hole_guard_mat, "PrizeHoleGuardLeft")
    make_box(machine, Vector3(guard_t, guard_h, guard_d), Vector3(PRIZE_HOLE.x + (opening_w * 0.5 + guard_t * 0.5), guard_y, PRIZE_HOLE.z), hole_guard_mat, "PrizeHoleGuardRight")
    make_box(machine, Vector3(guard_w, guard_h, guard_t), Vector3(PRIZE_HOLE.x, guard_y, PRIZE_HOLE.z - (opening_d * 0.5 + guard_t * 0.5)), hole_guard_mat, "PrizeHoleGuardBack")
    make_box(machine, Vector3(guard_w, guard_h, guard_t), Vector3(PRIZE_HOLE.x, guard_y, PRIZE_HOLE.z + (opening_d * 0.5 + guard_t * 0.5)), hole_guard_mat, "PrizeHoleGuardFront")
    make_collision_box(machine, Vector3(guard_t, guard_h, guard_d), Vector3(PRIZE_HOLE.x - (opening_w * 0.5 + guard_t * 0.5), guard_y, PRIZE_HOLE.z), "PrizeHoleGuardCollisionLeft")
    make_collision_box(machine, Vector3(guard_t, guard_h, guard_d), Vector3(PRIZE_HOLE.x + (opening_w * 0.5 + guard_t * 0.5), guard_y, PRIZE_HOLE.z), "PrizeHoleGuardCollisionRight")
    make_collision_box(machine, Vector3(guard_w, guard_h, guard_t), Vector3(PRIZE_HOLE.x, guard_y, PRIZE_HOLE.z - (opening_d * 0.5 + guard_t * 0.5)), "PrizeHoleGuardCollisionBack")
    make_collision_box(machine, Vector3(guard_w, guard_h, guard_t), Vector3(PRIZE_HOLE.x, guard_y, PRIZE_HOLE.z + (opening_d * 0.5 + guard_t * 0.5)), "PrizeHoleGuardCollisionFront")

    # Delivery chute, flap and neutral mechanical details.
    make_box(machine, Vector3(1.55, 0.42, 1.05), Vector3(PRIZE_HOLE.x, 2.55, PRIZE_HOLE.z), make_mat(Color("#17120E"), 0.75, 0.20), "PrizeChute")
    make_box(machine, Vector3(1.18, 0.09, 0.07), Vector3(PRIZE_HOLE.x, 2.80, PRIZE_HOLE.z + 0.54), make_mat(Color("#E8E0D6"), 0.55, 0.22), "ChuteTrim")
    make_box(machine, Vector3(1.20, 0.10, 0.55), Vector3(PRIZE_HOLE.x, 2.43, PRIZE_HOLE.z + 0.15), chrome_dark, "ChuteFlap")

    # Control deck.
    make_box(machine, Vector3(7.15, 0.27, 1.08), Vector3(0, 2.48, 3.30), dark_mat, "ControlDeck")
    make_box(machine, Vector3(2.0, 0.13, 0.72), Vector3(-2.0, 2.68, 3.30), chrome_dark, "JoystickPlate")
    make_cylinder(machine, 0.075, 0.65, Vector3(-2.0, 2.98, 3.30), chrome, "JoystickStem")
    make_sphere(machine, 0.22, Vector3(-2.0, 3.32, 3.30), make_mat(Color("#8A5A36"), 0.15, 0.32), "JoystickBall")
    make_box(machine, Vector3(1.28, 0.13, 0.72), Vector3(1.35, 2.68, 3.30), chrome_dark, "ButtonPlate")
    var grab_mat := make_mat(Color("#8E3A2E"), 0.20, 0.28, 0.55)
    make_cylinder(machine, 0.27, 0.18, Vector3(1.35, 2.86, 3.30), grab_mat, "GrabButton")
    var grab_light := OmniLight3D.new()
    grab_light.position = Vector3(1.35, 2.94, 3.18)
    grab_light.light_energy = 0.38
    grab_light.omni_range = 1.8
    grab_light.light_color = Color("#D85A45")
    add_child(grab_light)
    machine_lights.append(grab_light)
    scene_lights.append(grab_light)
    var grab3d := Label3D.new()
    grab3d.text = "GRAB"
    grab3d.font_size = 32
    grab3d.outline_size = 8
    grab3d.position = Vector3(1.35, 3.10, 3.27)
    grab3d.pixel_size = 0.0028
    machine.add_child(grab3d)

    # Внутри больше нет горизонтальных направляющих/неоновых полос.
    # Камера освещается только мягкими физическими светильниками.
    for x in [-2.8, 2.8]:
        make_box(machine, Vector3(0.95, 0.08, 0.34), Vector3(x, 1.18, 3.02), chrome_dark, "Vent")
        for k in range(5):
            make_box(machine, Vector3(0.055, 0.05, 0.25), Vector3(x - 0.30 + float(k) * 0.15, 1.19, 3.18), chrome, "VentSlot")

    # Lighting inside the cabinet: four small warm corner lights.
    for pos in [Vector3(-3.05, 8.65, 1.55), Vector3(3.05, 8.65, 1.55), Vector3(-3.05, 3.75, 1.55), Vector3(3.05, 3.75, 1.55)]:
        var corner_light := OmniLight3D.new()
        corner_light.position = pos
        corner_light.light_energy = 0.55
        corner_light.omni_range = 3.4
        corner_light.light_color = Color("#F2DCC0")
        add_child(corner_light)
        machine_lights.append(corner_light)
        scene_lights.append(corner_light)

func build_overhead_rails() -> void:
    var rails := Node3D.new()
    rails.name = "OverheadMetalRails"
    add_child(rails)
    var rail_mat := make_mat(Color("#70716D"), 0.95, 0.20)
    var dark_rail := make_mat(Color("#3E403D"), 0.92, 0.24)
    # Две продольные металлические направляющие в верхней части аппарата.
    for z in [-1.15, 1.15]:
        make_cylinder(rails, 0.065, 6.0, Vector3(0, 9.08, z), rail_mat, "X_Rail")
        rails.get_child(rails.get_child_count() - 1).rotation.z = PI * 0.5
    # Поперечная каретка, по которой движется узел клешни по глубине.
    make_cylinder(rails, 0.075, 2.55, Vector3(0, 9.08, 0), dark_rail, "Z_Carriage")
    rails.get_child(rails.get_child_count() - 1).rotation.x = PI * 0.5
    rail_carriage = Node3D.new()
    rail_carriage.name = "MovingCarriage"
    rail_carriage.position = Vector3(claw_pos.x, 8.98, claw_pos.z)
    rails.add_child(rail_carriage)
    make_box(rail_carriage, Vector3(0.52, 0.18, 0.52), Vector3.ZERO, dark_rail, "CarriageBlock")

func build_claw() -> void:
    claw = Node3D.new()
    claw.name = "CinematicClaw"
    add_child(claw)
    claw.position = claw_pos

    var metal := make_mat(Color("#666A66"), 0.95, 0.16)
    var dark := make_mat(Color("#2D2925"), 0.9, 0.22)
    var claw_color: Color = Color("#8B765E")
    var glow := make_mat(claw_color, 0.45, 0.26)
    claw.scale = Vector3(0.984, 0.984, 0.984)

    make_box(claw, Vector3(0.52, 0.30, 0.52), Vector3(0, 0.22, 0), dark, "MotorHousing")
    make_cylinder(claw, 0.20, 0.10, Vector3(0, -0.04, 0), metal, "RotaryHub")
    make_sphere(claw, 0.17, Vector3(0, -0.12, 0), metal, "Hub")
    cable = make_cylinder(claw, 0.035, 2.0, Vector3(0, 1.45, 0), make_mat(Color("#3B3C39"), 0.9, 0.22), "Cable")
    cable_glow = null

    # Настоящая трёхкогтевая конструкция: три одинаковых полукруглых
    # металлических когтя, расположенных через 120 градусов.
    for i in range(3):
        var arm := Node3D.new()
        arm.name = "Finger_%d" % i
        claw.add_child(arm)
        arm.rotation.y = float(i) * TAU / 3.0
        var p0 := Vector3(0, -0.18, 0.00)
        var p1 := Vector3(0, -0.40, 0.25)
        var p2 := Vector3(0, -0.66, 0.43)
        var p3 := Vector3(0, -0.88, 0.39)
        var p4 := Vector3(0, -1.04, 0.18)
        var p5 := Vector3(0, -1.08, -0.02)
        make_tube(arm, p0, p1, 0.085, metal, "FingerSegment01")
        make_tube(arm, p1, p2, 0.080, metal, "FingerSegment02")
        make_tube(arm, p2, p3, 0.075, metal, "FingerSegment03")
        make_tube(arm, p3, p4, 0.070, metal, "FingerSegment04")
        make_tube(arm, p4, p5, 0.065, metal, "FingerTip")
        make_sphere(arm, 0.082, p5, metal, "GripPad")
        claw_arms.append(arm)

func build_aim_marker() -> void:
    aim_marker = MeshInstance3D.new()
    aim_marker.name = "ClawAimMarker"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.34
    mesh.bottom_radius = 0.34
    mesh.height = 0.018
    mesh.radial_segments = 32
    aim_marker.mesh = mesh
    aim_marker.material_override = make_mat(Color(0.95, 0.72, 0.30, 0.38), 0.0, 0.35, 1.2)
    aim_marker.position = Vector3(claw_pos.x, 3.08, claw_pos.z)
    add_child(aim_marker)

func build_prizes() -> void:
    for body in prize_bodies:
        if body and is_instance_valid(body):
            body.queue_free()
    prize_bodies.clear()
    prize_data.clear()

    if saved_prizes.is_empty():
        spawn_random_prizes(INITIAL_PRIZE_COUNT)
        return

    for saved in saved_prizes:
        if not (saved is Dictionary):
            continue
        var source_index: int = clampi(int(saved.get("source_index", 0)), 0, toys.size() - 1)
        var pos_data: Variant = saved.get("position", [0.0, 3.5, 0.0])
        var rot_data: Variant = saved.get("rotation", [0.0, 0.0, 0.0])
        var pos := Vector3(float(pos_data[0]), float(pos_data[1]), float(pos_data[2])) if pos_data is Array and pos_data.size() >= 3 else Vector3(0, 3.5, 0)
        var rot := Vector3(float(rot_data[0]), float(rot_data[1]), float(rot_data[2])) if rot_data is Array and rot_data.size() >= 3 else Vector3.ZERO
        var kind := String(saved.get("kind", "toy"))
        if kind == "capsule":
            var capsule := make_coin_capsule(pos)
            capsule.rotation = rot
            prize_bodies.append(capsule)
            prize_data.append({"kind":"capsule", "name":"Капсула с монетами", "rarity":"БОНУС", "collection":"МОНЕТНЫЙ БОНУС", "reward_min":3, "reward_max":12})
        else:
            var variant: int = int(saved.get("variant", 0))
            var size_factor: float = clampf(float(saved.get("size_factor", 1.0)), 0.90, 1.12)
            var variant_color: Color = get_toy_variant_color(toys[source_index]["color"], variant)
            var body := make_physics_toy(source_index, toys[source_index], pos, variant_color, size_factor)
            body.rotation = rot
            prize_bodies.append(body)
            prize_data.append({"kind":"toy", "index":source_index, "name":toys[source_index]["name"], "rarity":toys[source_index]["rarity"], "collection":toys[source_index]["collection"], "weight":float(toys[source_index].get("weight", 38.0)), "slippery":bool(body.get_meta("slippery", false)), "variant":variant, "size_factor":size_factor})

    if prize_bodies.is_empty():
        spawn_random_prizes(INITIAL_PRIZE_COUNT)
    elif prize_bodies.size() < TARGET_PRIZE_COUNT:
        spawn_random_prizes(TARGET_PRIZE_COUNT - prize_bodies.size())

func build_prizes_async() -> void:
    # Реальная последовательная загрузка игрушек. Каждая игрушка создаётся
    # отдельно, после чего загрузчик обновляет фактический прогресс и отдаёт
    # кадр движку. Поэтому на экране всегда видно, сколько объектов уже создано.
    for body in prize_bodies:
        if body and is_instance_valid(body):
            body.queue_free()
    prize_bodies.clear()
    prize_data.clear()

    var total_to_build := INITIAL_PRIZE_COUNT
    if not saved_prizes.is_empty():
        total_to_build = saved_prizes.size()
    total_to_build = maxi(total_to_build, 1)

    if saved_prizes.is_empty():
        for i in range(INITIAL_PRIZE_COUNT):
            await set_loading_status("ЗАГРУЖАЕМ И СОЗДАЁМ ИГРУШКУ %d ИЗ %d..." % [i + 1, INITIAL_PRIZE_COUNT])
            spawn_one_random_prize(i)
            var toy_progress := 43.0 + (19.0 * float(i + 1) / float(INITIAL_PRIZE_COUNT))
            await set_loading_progress(toy_progress, "ИГРУШКА %d ИЗ %d СОЗДАНА" % [i + 1, INITIAL_PRIZE_COUNT])
        return

    var valid_saved_count := 0
    for saved in saved_prizes:
        if saved is Dictionary:
            valid_saved_count += 1
    if valid_saved_count <= 0:
        valid_saved_count = INITIAL_PRIZE_COUNT

    var loaded_count := 0
    for saved in saved_prizes:
        if not (saved is Dictionary):
            continue
        loaded_count += 1
        await set_loading_status("ВОССТАНАВЛИВАЕМ ИГРУШКУ %d ИЗ %d..." % [loaded_count, valid_saved_count])
        var source_index: int = clampi(int(saved.get("source_index", 0)), 0, toys.size() - 1)
        var pos_data: Variant = saved.get("position", [0.0, 3.5, 0.0])
        var rot_data: Variant = saved.get("rotation", [0.0, 0.0, 0.0])
        var pos := Vector3(float(pos_data[0]), float(pos_data[1]), float(pos_data[2])) if pos_data is Array and pos_data.size() >= 3 else Vector3(0, 3.5, 0)
        var rot := Vector3(float(rot_data[0]), float(rot_data[1]), float(rot_data[2])) if rot_data is Array and rot_data.size() >= 3 else Vector3.ZERO
        var kind := String(saved.get("kind", "toy"))
        if kind == "capsule":
            var capsule := make_coin_capsule(pos)
            capsule.rotation = rot
            prize_bodies.append(capsule)
            prize_data.append({"kind":"capsule", "name":"Капсула с монетами", "rarity":"БОНУС", "collection":"МОНЕТНЫЙ БОНУС", "reward_min":3, "reward_max":12})
        else:
            var variant: int = int(saved.get("variant", 0))
            var size_factor: float = clampf(float(saved.get("size_factor", 1.0)), 0.90, 1.12)
            var variant_color: Color = get_toy_variant_color(toys[source_index]["color"], variant)
            var body := make_physics_toy(source_index, toys[source_index], pos, variant_color, size_factor)
            body.rotation = rot
            prize_bodies.append(body)
            prize_data.append({"kind":"toy", "index":source_index, "name":toys[source_index]["name"], "rarity":toys[source_index]["rarity"], "collection":toys[source_index]["collection"], "weight":float(toys[source_index].get("weight", 38.0)), "slippery":bool(body.get_meta("slippery", false)), "variant":variant, "size_factor":size_factor})
        var saved_progress := 43.0 + (19.0 * float(loaded_count) / float(valid_saved_count))
        await set_loading_progress(saved_progress, "ИГРУШКА %d ИЗ %d ВОССТАНОВЛЕНА" % [loaded_count, valid_saved_count])

    if prize_bodies.is_empty():
        for i in range(INITIAL_PRIZE_COUNT):
            await set_loading_status("ДОПОЛНЯЕМ ИГРУШКИ: %d ИЗ %d..." % [i + 1, INITIAL_PRIZE_COUNT])
            spawn_one_random_prize(i)
            var fallback_progress := 43.0 + (19.0 * float(i + 1) / float(INITIAL_PRIZE_COUNT))
            await set_loading_progress(fallback_progress, "ИГРУШКА %d ИЗ %d СОЗДАНА" % [i + 1, INITIAL_PRIZE_COUNT])
    elif prize_bodies.size() < TARGET_PRIZE_COUNT:
        var missing := TARGET_PRIZE_COUNT - prize_bodies.size()
        for i in range(missing):
            await set_loading_status("ДОЗАГРУЖАЕМ ИГРУШКИ: %d ИЗ %d..." % [i + 1, missing])
            spawn_one_random_prize(i)
            var refill_progress := 43.0 + (19.0 * float(i + 1) / float(missing))
            await set_loading_progress(refill_progress, "ДОПОЛНИТЕЛЬНАЯ ИГРУШКА %d ИЗ %d ГОТОВА" % [i + 1, missing])

func spawn_one_random_prize(n: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var x: float = rng.randf_range(-2.65, 2.65)
    var z: float = rng.randf_range(-1.62, 1.62)
    var layer: int = n % 8
    var y: float = minf(3.20 + float(layer) * 0.26 + rng.randf_range(-0.04, 0.05), MAX_PRIZE_CENTER_Y)
    if rng.randf() < CAPSULE_CHANCE:
        var capsule := make_coin_capsule(Vector3(x, y, z))
        capsule.rotation = Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-PI, PI), rng.randf_range(-0.25, 0.25))
        prize_bodies.append(capsule)
        prize_data.append({"kind":"capsule", "name":"Капсула с монетами", "rarity":"БОНУС", "collection":"МОНЕТНЫЙ БОНУС", "reward_min":3, "reward_max":12})
        return
    var source_index := rng.randi_range(0, toys.size() - 1)
    var variant := rng.randi_range(0, 3)
    var variant_color := get_toy_variant_color(toys[source_index]["color"], variant)
    var size_factor := rng.randf_range(0.90, 1.12)
    var body := make_physics_toy(source_index, toys[source_index], Vector3(x, y, z), variant_color, size_factor)
    body.rotation = Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-PI, PI), rng.randf_range(-0.25, 0.25))
    prize_bodies.append(body)
    prize_data.append({"kind":"toy", "index":source_index, "name":toys[source_index]["name"], "rarity":toys[source_index]["rarity"], "collection":toys[source_index]["collection"], "weight":float(toys[source_index].get("weight", 38.0)), "slippery":bool(body.get_meta("slippery", false)), "variant":variant, "size_factor":size_factor})

func get_thematic_toy_indices() -> Array[int]:
    var result: Array[int] = []
    var dt := Time.get_datetime_dict_from_system()
    var month := int(dt.get("month", 1)); var day := int(dt.get("day", 1))
    for i in range(toys.size()):
        var collection := String(toys[i].get("collection", ""))
        var name := String(toys[i].get("name", ""))
        var wanted := false
        if month == 10 and day == 31:
            wanted = collection in ["ДЖУНГЛИ", "КОСМОС", "ДРАКОНЫ", "КИБЕР"] or "Тигр" in name or "Акула" in name
        elif month == 12 or (month == 1 and day <= 7) or active_event_theme == "winter":
            wanted = collection in ["ОКЕАН", "КОСМОС"] or "Сноу" in name or "Айс" in name or "Золотой" in name
        elif month == 2 and day == 14:
            wanted = collection == "ВОЛШЕБСТВО" or "Розовый" in name or "Единорог" in name
        elif month == 6 and day == 1:
            wanted = collection == "МИЛЫЕ МАЛЫШИ" or collection == "ЛЕСНЫЕ ДРУЗЬЯ"
        elif month >= 3 and month <= 5:
            wanted = collection == "ВОЛШЕБСТВО" or collection == "ДЖУНГЛИ"
        elif month >= 6 and month <= 8:
            wanted = collection == "ОКЕАН" or collection == "КОСМОС"
        elif month >= 9 and month <= 11:
            wanted = collection == "ЛЕСНЫЕ ДРУЗЬЯ" or collection == "ДРАКОНЫ" or collection == "КИБЕР"
        if wanted:
            result.append(i)
    return result

func event_allows_toy(index: int, rng: RandomNumberGenerator) -> bool:
    if index < 0 or index >= toys.size() or active_event_toy_bonus <= 0.0:
        return false
    var themed := get_thematic_toy_indices()
    if themed.is_empty() or not themed.has(index):
        return false
    return rng.randf() < active_event_toy_bonus

func event_rarity_weight_bonus(rarity: String) -> float:
    if rarity == "ЛЕГЕНДАРНАЯ": return active_event_rare_bonus
    if rarity == "ЭПИЧЕСКАЯ": return active_event_rare_bonus * 0.55
    if rarity == "РЕДКАЯ": return active_event_rare_bonus * 0.25
    return 0.0

func spawn_random_prizes(count: int, animate_refill: bool = false) -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var bag: Array[int] = []
    for i in range(toys.size()):
        bag.append(i)
    bag.shuffle()
    var bag_pos := 0
    var last_index := -1
    var last_variant := -1
    for n in range(count):
        var x: float = rng.randf_range(-2.65, 2.65)
        var z: float = rng.randf_range(-1.62, 1.62)
        var layer: int = n % 8
        var y: float = 3.20 + float(layer) * 0.26 + rng.randf_range(-0.04, 0.05)
        y = minf(y, MAX_PRIZE_CENTER_Y)
        var is_capsule: bool = rng.randf() < CAPSULE_CHANCE
        if is_capsule:
            var target_pos := Vector3(x, y, z)
            var spawn_pos := target_pos
            if animate_refill:
                spawn_pos = Vector3(x, 6.65 + rng.randf_range(0.0, 0.45), z)
            var capsule := make_coin_capsule(spawn_pos)
            capsule.rotation = Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-PI, PI), rng.randf_range(-0.25, 0.25))
            if animate_refill:
                capsule.freeze = true
                capsule.set_meta("refill_target", target_pos)
                capsule.set_meta("refill_active", true)
                capsule.set_meta("refill_delay", float(n) * 0.10)
            prize_bodies.append(capsule)
            prize_data.append({"kind":"capsule", "name":"Капсула с монетами", "rarity":"БОНУС", "collection":"МОНЕТНЫЙ БОНУС", "reward_min":3, "reward_max":12})
        else:
            if bag_pos >= bag.size():
                bag.shuffle()
                bag_pos = 0
            var candidates: Array[int] = []
            for candidate in bag:
                if batch_allowed(candidate):
                    candidates.append(candidate)
            if candidates.is_empty():
                candidates = bag.duplicate()
            var source_index: int = candidates[rng.randi_range(0, candidates.size() - 1)]
            var themed_indices := get_thematic_toy_indices()
            if not themed_indices.is_empty() and rng.randf() < active_event_toy_bonus:
                var themed_candidates: Array[int] = []
                for ti in themed_indices:
                    if batch_allowed(ti): themed_candidates.append(ti)
                if not themed_candidates.is_empty():
                    source_index = themed_candidates[rng.randi_range(0, themed_candidates.size() - 1)]
            bag_pos += 1
            # Не ставим одну и ту же игрушку подряд.
            if source_index == last_index and candidates.size() > 1:
                source_index = candidates[rng.randi_range(0, candidates.size() - 1)]
                if source_index == last_index:
                    for candidate in candidates:
                        if candidate != last_index:
                            source_index = candidate
                            break
            var previous_index := last_index
            last_index = source_index
            var variant: int = rng.randi_range(0, 3)
            if source_index == previous_index and variant == last_variant:
                variant = (variant + 1) % 4
            last_variant = variant
            var variant_color: Color = get_toy_variant_color(toys[source_index]["color"], variant)
            var size_factor: float = rng.randf_range(0.90, 1.12)
            var target_pos := Vector3(x, y, z)
            var spawn_pos := target_pos
            if animate_refill:
                spawn_pos = Vector3(x, 6.65 + rng.randf_range(0.0, 0.45), z)
            var body := make_physics_toy(source_index, toys[source_index], spawn_pos, variant_color, size_factor)
            body.rotation = Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-PI, PI), rng.randf_range(-0.25, 0.25))
            if animate_refill:
                body.freeze = true
                body.set_meta("refill_target", target_pos)
                body.set_meta("refill_active", true)
                body.set_meta("refill_delay", float(n) * 0.10)
            prize_bodies.append(body)
            prize_data.append({"kind":"toy", "index":source_index, "name":toys[source_index]["name"], "rarity":toys[source_index]["rarity"], "collection":toys[source_index]["collection"], "weight":float(toys[source_index].get("weight", 38.0)), "slippery":bool(body.get_meta("slippery", false)), "variant":variant, "size_factor":size_factor})

func make_coin_capsule(pos: Vector3) -> RigidBody3D:
    var body := RigidBody3D.new()
    body.name = "CoinCapsule"
    body.position = safe_prize_position(pos)
    body.collision_layer = 1
    body.collision_mask = 1
    body.continuous_cd = true
    body.mass = 0.22
    body.linear_damp = 2.8
    body.angular_damp = 3.2
    var physics := PhysicsMaterial.new()
    physics.friction = 0.72
    physics.bounce = 0.05
    body.physics_material_override = physics
    add_child(body)

    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.31
    shape.shape = sphere
    body.add_child(shape)

    var capsule_mat := StandardMaterial3D.new()
    capsule_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    capsule_mat.albedo_color = Color(0.86, 0.94, 0.98, 0.28)
    capsule_mat.metallic = 0.05
    capsule_mat.roughness = 0.08
    capsule_mat.refraction_enabled = true
    capsule_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    make_sphere(body, 0.36, Vector3(0, 0.36, 0), capsule_mat, "TransparentCapsule")
    var coin_mat := make_mat(Color("#C69B55"), 0.75, 0.18)
    var coin := make_cylinder(body, 0.13, 0.055, Vector3(0, 0.36, 0.23), coin_mat, "CoinInside")
    coin.rotation.x = PI * 0.5
    make_cylinder(body, 0.105, 0.025, Vector3(0, 0.36, 0.25), make_mat(Color("#E5C67B"), 0.70, 0.16), "CoinMark")
    return body

func advance_batch() -> void:
    batch_index += 1
    var batches := ["ОБЫЧНАЯ ПАРТИЯ", "ЛЕСНАЯ ПАРТИЯ", "ОКЕАНСКАЯ ПАРТИЯ", "КОСМИЧЕСКАЯ ПАРТИЯ", "ВОЛШЕБНАЯ ПАРТИЯ", "КИБЕР-ПАРТИЯ"]
    if randf() < 0.18:
        batch_type = "🔥 ОСОБАЯ ПАРТИЯ"
    else:
        batch_type = batches[batch_index % batches.size()]

func batch_allowed(source_index: int) -> bool:
    var cname := String(toys[source_index].get("collection", ""))
    if batch_type == "ЛЕСНАЯ ПАРТИЯ": return cname == "ЛЕСНЫЕ ДРУЗЬЯ" or cname == "МИЛЫЕ МАЛЫШИ"
    if batch_type == "ОКЕАНСКАЯ ПАРТИЯ": return cname == "ОКЕАН"
    if batch_type == "КОСМИЧЕСКАЯ ПАРТИЯ": return cname == "КОСМОС"
    if batch_type == "ВОЛШЕБНАЯ ПАРТИЯ": return cname == "ВОЛШЕБСТВО"
    if batch_type == "КИБЕР-ПАРТИЯ": return cname == "КИБЕР"
    if batch_type == "🔥 ОСОБАЯ ПАРТИЯ": return String(toys[source_index].get("rarity", "")) in ["РЕДКАЯ", "ЭПИЧЕСКАЯ", "ЛЕГЕНДАРНАЯ"]
    return true

func refill_prizes_if_needed() -> void:
    if prize_bodies.size() <= REFILL_THRESHOLD:
        var amount: int = REFILL_AMOUNT if prize_bodies.size() > 0 else INITIAL_PRIZE_COUNT
        spawn_random_prizes(amount, true)
        current_result = "🎁 ПОПОЛНЕНИЕ • НОВАЯ ПАРТИЯ ЗАГРУЖАЕТСЯ"
        refill_animation_timer = 3.8
        update_ui()


func safe_prize_position(pos: Vector3) -> Vector3:
    var result := pos
    # Никогда не восстанавливаем сохранённую игрушку за физическими стенками.
    result.x = clampf(result.x, -2.95, 2.95)
    result.z = clampf(result.z, -1.66, 1.66)
    result.y = clampf(result.y, 3.22, MAX_PRIZE_CENTER_Y)
    if absf(result.x - PRIZE_HOLE.x) < 0.82 and absf(result.z - PRIZE_HOLE.z) < 0.52 and result.y < 4.0:
        result.x = randf_range(-2.5, 1.15)
        result.z = randf_range(-1.45, 1.0)
        result.y = clampf(result.y, 3.22, MAX_PRIZE_CENTER_Y)
    return result

func make_physics_toy(index: int, data: Dictionary, pos: Vector3, visual_color: Color = Color(-1, -1, -1, -1), size_factor: float = 1.0) -> RigidBody3D:
    var body := RigidBody3D.new()
    body.name = "Prize_%02d" % index
    body.position = safe_prize_position(pos)
    body.freeze = false
    body.lock_rotation = false
    body.collision_layer = 1
    body.collision_mask = 1
    body.continuous_cd = true
    # Вес влияет на физику и шанс удержания. Значения в каталоге игрушек
    # используются как "условный вес" и нормализуются в безопасный диапазон.
    var toy_weight: float = float(data.get("weight", 38.0))
    body.mass = clampf(toy_weight / 55.0, 0.20, 1.15)
    body.set_meta("toy_weight", toy_weight)
    body.set_meta("slippery", randf() < (0.10 if String(data.get("rarity", "")) == "ОБЫЧНАЯ" else 0.18))
    body.scale = Vector3(TOY_SCALE * size_factor, TOY_SCALE * size_factor, TOY_SCALE * size_factor)
    body.linear_damp = 2.4
    body.angular_damp = 3.0
    var toy_physics := PhysicsMaterial.new()
    toy_physics.friction = 0.82
    toy_physics.bounce = 0.02
    body.physics_material_override = toy_physics
    add_child(body)

    var shape := CollisionShape3D.new()
    var sphere_shape := SphereShape3D.new()
    sphere_shape.radius = 0.27
    shape.shape = sphere_shape
    shape.position = Vector3(0, 0.55, 0)
    body.add_child(shape)

    var render_color: Color = data["color"] if visual_color.a < 0.0 else visual_color
    make_toy_visual(body, index, String(data["rarity"]), render_color)
    body.rotation.y = randf_range(-0.5, 0.5)
    return body

func plush_piece(root: Node3D, pos: Vector3, scale: Vector3, mat: Material, name: String) -> MeshInstance3D:
    var n := make_sphere(root, 0.5, pos, mat, name)
    n.scale = scale
    return n

func plush_face(root: Node3D, face_y: float, face_z: float, white: Material, dark: Material, pink: Material) -> void:
    make_sphere(root, 0.075, Vector3(-0.16, face_y, face_z), dark, "EyeL")
    make_sphere(root, 0.075, Vector3(0.16, face_y, face_z), dark, "EyeR")
    make_sphere(root, 0.030, Vector3(-0.135, face_y + 0.025, face_z + 0.055), white, "EyeSparkL")
    make_sphere(root, 0.030, Vector3(0.185, face_y + 0.025, face_z + 0.055), white, "EyeSparkR")
    make_sphere(root, 0.055, Vector3(0, face_y - 0.17, face_z + 0.045), pink, "Nose")

func add_bear(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    plush_piece(root, Vector3(0,0.55,0), Vector3(1.12,1.02,0.88), mat, "RoundBody")
    plush_piece(root, Vector3(0,1.22,0), Vector3(0.78,0.78,0.76), mat, "RoundHead")
    plush_piece(root, Vector3(-0.48,1.58,0), Vector3(0.32,0.32,0.30), mat, "EarL")
    plush_piece(root, Vector3(0.48,1.58,0), Vector3(0.32,0.32,0.30), mat, "EarR")
    plush_piece(root, Vector3(-0.62,0.52,0.08), Vector3(0.38,0.58,0.34), mat, "ArmL")
    plush_piece(root, Vector3(0.62,0.52,0.08), Vector3(0.38,0.58,0.34), mat, "ArmR")
    plush_piece(root, Vector3(-0.34,0.08,0.12), Vector3(0.42,0.28,0.50), mat, "FootL")
    plush_piece(root, Vector3(0.34,0.08,0.12), Vector3(0.42,0.28,0.50), mat, "FootR")
    plush_piece(root, Vector3(0,1.05,0.58), Vector3(0.36,0.25,0.16), white, "Muzzle")
    plush_face(root,1.34,0.67,white,dark,pink)

func add_fox(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root, mat, dark, white, pink)
    make_box(root, Vector3(0.22,0.34,0.16), Vector3(-0.34,1.72,0.02), mat, "FoxEarL")
    make_box(root, Vector3(0.22,0.34,0.16), Vector3(0.34,1.72,0.02), mat, "FoxEarR")
    plush_piece(root,Vector3(0,1.10,0.62),Vector3(0.46,0.30,0.18),white,"WhiteCheeks")
    make_sphere(root,0.07,Vector3(0,1.26,0.78),dark,"FoxNose")
    var tail := plush_piece(root,Vector3(0.68,0.62,-0.34),Vector3(0.55,0.42,0.72),mat,"BigTail")
    tail.rotation_degrees.y=28.0
    plush_piece(root,Vector3(0.96,0.86,-0.55),Vector3(0.25,0.30,0.30),white,"TailTip")

func add_bunny(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    make_box(root,Vector3(0.24,0.90,0.22),Vector3(-0.30,1.95,0),mat,"LongEarL")
    make_box(root,Vector3(0.24,0.90,0.22),Vector3(0.30,1.95,0),mat,"LongEarR")
    make_box(root,Vector3(0.12,0.58,0.25),Vector3(-0.30,1.95,0.14),pink,"EarInnerL")
    make_box(root,Vector3(0.12,0.58,0.25),Vector3(0.30,1.95,0.14),pink,"EarInnerR")

func add_panda(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    # Панда не белая: графитовая плюшевая основа с тёмными пятнами.
    var panda_mat := make_fur_mat(Color("#465B72"))
    add_bear(root,panda_mat,dark,white,pink)
    plush_piece(root,Vector3(-0.25,1.38,0.64),Vector3(0.18,0.25,0.08),dark,"EyePatchL")
    plush_piece(root,Vector3(0.25,1.38,0.64),Vector3(0.18,0.25,0.08),dark,"EyePatchR")

func add_cat(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    make_box(root,Vector3(0.34,0.44,0.30),Vector3(-0.34,1.75,0),mat,"CatEarL")
    make_box(root,Vector3(0.34,0.44,0.30),Vector3(0.34,1.75,0),mat,"CatEarR")
    for x in [-0.42,0.42]:
        make_tube(root,Vector3(x,1.16,0.70),Vector3(x*1.35,1.12,0.72),0.018,dark,"Whisker")

func add_dog(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    plush_piece(root,Vector3(-0.48,1.45,-0.03),Vector3(0.25,0.52,0.24),mat,"FloppyEarL")
    plush_piece(root,Vector3(0.48,1.45,-0.03),Vector3(0.25,0.52,0.24),mat,"FloppyEarR")
    plush_piece(root,Vector3(0,1.06,0.65),Vector3(0.32,0.23,0.18),white,"DogMuzzle")

func add_koala(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    plush_piece(root,Vector3(-0.52,1.48,0),Vector3(0.40,0.40,0.20),mat,"BigEarL")
    plush_piece(root,Vector3(0.52,1.48,0),Vector3(0.40,0.40,0.20),mat,"BigEarR")
    make_sphere(root,0.10,Vector3(0,1.20,0.69),dark,"KoalaNose")

func add_frog(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    plush_piece(root,Vector3(0,0.55,0),Vector3(1.25,0.90,0.92),mat,"FrogBody")
    plush_piece(root,Vector3(0,1.10,0.02),Vector3(0.78,0.65,0.75),mat,"FrogHead")
    for x in [-0.34,0.34]:
        plush_piece(root,Vector3(x,1.52,0.02),Vector3(0.25,0.25,0.25),mat,"EyeBump")
        make_sphere(root,0.07,Vector3(x,1.55,0.25),dark,"FrogEye")
    plush_face(root,1.18,0.64,white,dark,pink)
    make_box(root,Vector3(0.70,0.08,0.05),Vector3(0,0.91,0.70),pink,"Smile")

func add_turtle(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    plush_piece(root,Vector3(0,0.62,0),Vector3(1.25,0.72,1.08),mat,"Shell")
    plush_piece(root,Vector3(0,0.82,0.42),Vector3(0.50,0.40,0.42),white,"Head")
    for pos in [Vector3(-0.72,0.35,0.35),Vector3(0.72,0.35,0.35),Vector3(-0.72,0.35,-0.35),Vector3(0.72,0.35,-0.35)]:
        plush_piece(root,pos,Vector3(0.36,0.22,0.30),mat,"Flipper")
    make_sphere(root,0.06,Vector3(-0.16,0.93,0.76),dark,"EyeL")
    make_sphere(root,0.06,Vector3(0.16,0.93,0.76),dark,"EyeR")

func add_monkey(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    plush_piece(root,Vector3(-0.48,1.35,0),Vector3(0.28,0.34,0.18),pink,"EarL")
    plush_piece(root,Vector3(0.48,1.35,0),Vector3(0.28,0.34,0.18),pink,"EarR")
    var tail := plush_piece(root,Vector3(0.82,0.72,-0.30),Vector3(0.18,0.80,0.18),mat,"Tail")
    tail.rotation_degrees.z=55.0

func add_tiger(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    for x in [-0.28,0,0.28]:
        make_box(root,Vector3(0.08,0.46,0.05),Vector3(x,1.28,0.70),dark,"TigerStripe")
    make_box(root,Vector3(0.05,0.48,0.05),Vector3(-0.48,0.55,0.32),dark,"LegStripeL")
    make_box(root,Vector3(0.05,0.48,0.05),Vector3(0.48,0.55,0.32),dark,"LegStripeR")

func add_shark(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    plush_piece(root,Vector3(0,0.62,0),Vector3(1.35,0.72,0.75),mat,"SharkBody")
    plush_piece(root,Vector3(0,0.92,0.52),Vector3(0.72,0.46,0.48),mat,"SharkHead")
    make_box(root,Vector3(0.30,0.45,0.10),Vector3(0,1.52,0),mat,"DorsalFin")
    make_box(root,Vector3(0.75,0.22,0.10),Vector3(0,0.75,-0.60),mat,"TailFin")
    plush_piece(root,Vector3(0,0.67,0.77),Vector3(0.68,0.22,0.16),white,"SharkBelly")
    plush_face(root,1.03,0.86,white,dark,pink)

func add_penguin(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    plush_piece(root,Vector3(0,0.62,0),Vector3(0.90,1.20,0.78),dark,"PenguinBody")
    plush_piece(root,Vector3(0,1.38,0.28),Vector3(0.62,0.58,0.50),white,"BellyHead")
    make_sphere(root,0.09,Vector3(0,1.28,0.76),pink,"Beak")
    for x in [-0.60,0.60]:
        plush_piece(root,Vector3(x,0.72,0),Vector3(0.30,0.58,0.24),dark,"Flipper")

func add_whale(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    plush_piece(root,Vector3(0,0.62,0),Vector3(1.45,0.75,1.00),mat,"WhaleBody")
    plush_piece(root,Vector3(0,0.92,0.58),Vector3(0.72,0.45,0.45),mat,"WhaleHead")
    make_box(root,Vector3(0.35,0.30,0.18),Vector3(-0.45,1.30,0),mat,"FinL")
    make_box(root,Vector3(0.35,0.30,0.18),Vector3(0.45,1.30,0),mat,"FinR")
    make_sphere(root,0.10,Vector3(0,1.43,0.05),white,"Spout")
    plush_face(root,1.08,0.88,white,dark,pink)

func add_dragon(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material, legendary: bool=false) -> void:
    add_bear(root,mat,dark,white,pink)
    make_box(root,Vector3(0.18,0.48,0.18),Vector3(-0.30,1.75,0),mat,"HornL")
    make_box(root,Vector3(0.18,0.48,0.18),Vector3(0.30,1.75,0),mat,"HornR")
    make_box(root,Vector3(0.52,0.60,0.10),Vector3(-0.50,1.10,-0.08),mat,"WingL")
    make_box(root,Vector3(0.52,0.60,0.10),Vector3(0.50,1.10,-0.08),mat,"WingR")
    var tail := plush_piece(root,Vector3(0,0.35,-0.62),Vector3(0.22,0.45,0.65),mat,"DragonTail")
    tail.rotation_degrees.x=-20.0
    if legendary:
        make_sphere(root,0.10,Vector3(0,1.93,0.02),make_mat(Color("#C69B55"),0.45,0.22),"LegendGem")

func add_unicorn(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material, king: bool=false) -> void:
    add_bear(root,mat,dark,white,pink)
    var horn := make_cylinder(root,0.10,0.58,Vector3(0,1.88,0.05),make_mat(Color("#C69B55"),0.50,0.20),"UnicornHorn")
    horn.rotation_degrees.z=0.0
    for x in [-0.34,0.34]:
        make_box(root,Vector3(0.18,0.40,0.16),Vector3(x,1.72,-0.02),pink,"UnicornEar")
    if king:
        make_box(root,Vector3(0.80,0.18,0.25),Vector3(0,1.78,0),make_mat(Color("#B88645"),0.50,0.22),"Crown")

func add_fairy(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    make_box(root,Vector3(0.72,0.72,0.08),Vector3(-0.55,1.22,-0.05),make_mat(Color("#8B7C9B"),0.15,0.32),"WingL")
    make_box(root,Vector3(0.72,0.72,0.08),Vector3(0.55,1.22,-0.05),make_mat(Color("#9B7E8F"),0.15,0.32),"WingR")
    make_sphere(root,0.09,Vector3(0,1.92,0),make_mat(Color("#C6A45D"),0.35,0.28),"FairyStar")

func add_griffin(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    make_box(root,Vector3(0.70,0.58,0.08),Vector3(-0.55,1.18,-0.04),mat,"GriffinWingL")
    make_box(root,Vector3(0.70,0.58,0.08),Vector3(0.55,1.18,-0.04),mat,"GriffinWingR")
    make_box(root,Vector3(0.22,0.32,0.18),Vector3(0,1.74,0.05),make_mat(Color("#B88645"),0.45,0.22),"Beak")

func add_robot(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material, master: bool=false) -> void:
    var metal := make_mat(Color("#A8B9CA"),0.72,0.20)
    var darkmetal := make_mat(Color("#27344A"),0.88,0.16)
    make_box(root,Vector3(1.15,1.20,0.92),Vector3(0,0.72,0),metal,"RobotBody")
    make_box(root,Vector3(0.90,0.76,0.78),Vector3(0,1.60,0),darkmetal,"RobotHead")
    for x in [-0.22,0.22]:
        make_sphere(root,0.085,Vector3(x,1.64,0.42),make_mat(Color("#6B7880"),0.65,0.20),"RobotEye")
    make_box(root,Vector3(0.12,0.36,0.12),Vector3(-0.70,0.72,0),metal,"RobotArmL")
    make_box(root,Vector3(0.12,0.36,0.12),Vector3(0.70,0.72,0),metal,"RobotArmR")
    make_cylinder(root,0.08,0.42,Vector3(0,2.10,0),make_mat(Color("#6B7880"),0.65,0.20),"Antenna")
    if master:
        make_box(root,Vector3(0.62,0.16,0.20),Vector3(0,1.98,0),make_mat(Color("#B58A43"),0.65,0.20),"MasterBadge")

func add_space_cat(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_cat(root,mat,dark,white,pink)
    var helmet := make_sphere(root,0.66,Vector3(0,1.20,0),make_mat(Color(0.30,0.34,0.36,0.30),0.35,0.18),"SpaceHelmet")
    helmet.scale=Vector3(1.02,1.05,0.72)
    make_box(root,Vector3(0.22,0.10,0.10),Vector3(-0.42,1.10,0.25),make_mat(Color("#6B7880"),0.65,0.22),"SpaceBadge")

func add_duck(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    plush_piece(root,Vector3(0,0.58,0),Vector3(1.05,0.82,0.90),mat,"DuckBody")
    plush_piece(root,Vector3(0,1.20,0.10),Vector3(0.72,0.62,0.68),mat,"DuckHead")
    plush_piece(root,Vector3(-0.18,1.36,0.60),Vector3(0.09,0.09,0.08),dark,"DuckEyeL")
    plush_piece(root,Vector3(0.18,1.36,0.60),Vector3(0.09,0.09,0.08),dark,"DuckEyeR")
    make_box(root,Vector3(0.38,0.18,0.20),Vector3(0,1.19,0.72),make_fur_mat(Color("#E88C2E")),"DuckBeak")
    plush_piece(root,Vector3(-0.62,0.55,0.04),Vector3(0.38,0.22,0.58),mat,"DuckWingL")
    plush_piece(root,Vector3(0.62,0.55,0.04),Vector3(0.38,0.22,0.58),mat,"DuckWingR")

func add_cyber_cat(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_cat(root,mat,dark,white,pink)
    var metal := make_mat(Color("#71879B"),0.72,0.22)
    make_box(root,Vector3(0.52,0.14,0.18),Vector3(0,0.76,0.64),metal,"CyberChest")
    for x in [-0.26,0.26]:
        make_sphere(root,0.055,Vector3(x,1.36,0.73),make_mat(Color("#D5B45A"),0.65,0.18),"CyberEye")

func add_mecha_bear(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    var metal := make_mat(Color("#8B98A5"),0.75,0.20)
    make_box(root,Vector3(0.70,0.20,0.72),Vector3(0,0.70,0.48),metal,"MechaChest")
    for x in [-0.50,0.50]:
        make_cylinder(root,0.10,0.32,Vector3(x,0.60,0.04),metal,"MechaArm")
    make_sphere(root,0.06,Vector3(-0.17,1.34,0.66),make_mat(Color("#D5B45A"),0.7,0.18),"MechaEyeL")
    make_sphere(root,0.06,Vector3(0.17,1.34,0.66),make_mat(Color("#D5B45A"),0.7,0.18),"MechaEyeR")

func add_space_shark(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_shark(root,mat,dark,white,pink)
    var helmet := make_sphere(root,0.72,Vector3(0,1.02,0.05),make_mat(Color(0.55,0.68,0.76,0.25),0.25,0.12),"SpaceSharkHelmet")
    helmet.scale=Vector3(1.12,0.82,0.72)
    make_box(root,Vector3(0.55,0.08,0.08),Vector3(0,1.00,0.67),make_mat(Color("#C6A45D"),0.5,0.2),"SpaceBadge")

func add_star_panda(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_panda(root,mat,dark,white,pink)
    var star := make_mat(Color("#D9B85A"),0.65,0.18)
    for x in [-0.18,0.0,0.18]:
        make_sphere(root,0.055,Vector3(x,0.86,0.64),star,"StarMark")

func add_fairy_plush(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    var wing := make_fur_mat(Color("#B99AE8"))
    make_sphere(root,0.34,Vector3(-0.55,1.10,-0.10),wing,"FairyWingL")
    make_sphere(root,0.34,Vector3(0.55,1.10,-0.10),wing,"FairyWingR")
    make_cylinder(root,0.08,0.48,Vector3(0,1.92,0),make_mat(Color("#D5B45A"),0.55,0.2),"FairyWand")

func add_griffin_plush(root: Node3D, mat: Material, dark: Material, white: Material, pink: Material) -> void:
    add_bear(root,mat,dark,white,pink)
    var wingmat := make_fur_mat(Color("#D68A9C"))
    make_box(root,Vector3(0.72,0.58,0.12),Vector3(-0.58,1.15,-0.08),wingmat,"GriffinWingL")
    make_box(root,Vector3(0.72,0.58,0.12),Vector3(0.58,1.15,-0.08),wingmat,"GriffinWingR")
    make_box(root,Vector3(0.24,0.30,0.20),Vector3(0,1.72,0.12),make_fur_mat(Color("#D4A33D")),"GriffinBeak")

func get_toy_variant_color(base: Color, variant: int) -> Color:
    match variant:
        1:
            return base.lightened(0.18)
        2:
            return base.darkened(0.18)
        3:
            return base.lerp(Color("#FF78B7"), 0.22)
        _:
            return base

func make_toy_visual(root: Node3D, index: int, rarity: String, color: Color) -> void:
    # Все призы сделаны как единая линейка мягких коллекционных игрушек:
    # крупные мягкие формы, вышитое лицо, характерные детали каждой коллекции.
    var body_mat := make_fur_mat(color)
    var white := make_fur_mat(Color("#E2B66B"))
    var dark := make_mat(Color("#172033"), 0.03, 0.48)
    var pink := make_fur_mat(Color("#FF789F"))

    match index:
        0: add_bear(root,body_mat,dark,white,pink)
        1: add_fox(root,body_mat,dark,white,pink)
        2: add_bunny(root,body_mat,dark,white,pink)
        3: add_panda(root,body_mat,dark,white,pink)
        4: add_duck(root,body_mat,dark,white,pink)
        5: add_cat(root,body_mat,dark,white,pink)
        6: add_dog(root,body_mat,dark,white,pink)
        7: add_koala(root,body_mat,dark,white,pink)
        8: add_frog(root,body_mat,dark,white,pink)
        9: add_turtle(root,body_mat,dark,white,pink)
        10: add_monkey(root,body_mat,dark,white,pink)
        11: add_tiger(root,body_mat,dark,white,pink)
        12: add_shark(root,body_mat,dark,white,pink)
        13: add_penguin(root,body_mat,dark,white,pink)
        14: add_cat(root,body_mat,dark,white,pink)
        15: add_whale(root,body_mat,dark,white,pink)
        16: add_space_shark(root,body_mat,dark,white,pink)
        17: add_space_cat(root,body_mat,dark,white,pink)
        18: add_space_cat(root,body_mat,dark,white,pink)
        19: add_star_panda(root,body_mat,dark,white,pink)
        20: add_dragon(root,body_mat,dark,white,pink,false)
        21: add_dragon(root,body_mat,dark,white,pink,true)
        22: add_dragon(root,body_mat,dark,white,pink,true)
        23: add_dragon(root,body_mat,dark,white,pink,true)
        24: add_unicorn(root,body_mat,dark,white,pink,false)
        25: add_unicorn(root,body_mat,dark,white,pink,true)
        26: add_fairy_plush(root,body_mat,dark,white,pink)
        27: add_griffin_plush(root,body_mat,dark,white,pink)
        28: add_robot(root,body_mat,dark,white,pink,false)
        29: add_cyber_cat(root,body_mat,dark,white,pink)
        30: add_mecha_bear(root,body_mat,dark,white,pink)
        31: add_robot(root,body_mat,dark,white,pink,true)

    # Мягкая тканевая "сигнатура" коллекции: маленькая нашивка на груди.
    if rarity == "ЛЕГЕНДАРНАЯ":
        var badge_color = make_mat(Color("#C6A45D"),0.40,0.24)
        plush_piece(root,Vector3(0,0.72,0.58),Vector3(0.16,0.16,0.06),badge_color,"LegendBadge")
        make_sphere(root,0.075,Vector3(0,1.98,0),badge_color,"LegendSpark")
    elif rarity == "ЭПИЧЕСКАЯ":
        var badge_color = make_mat(Color("#8A6E8D"),0.25,0.28)
        plush_piece(root,Vector3(0,0.72,0.58),Vector3(0.15,0.15,0.06),badge_color,"EpicBadge")


func build_particles() -> void:
    # Неоновые частицы отключены: стиль автомата — дерево, металл и стекло.
    sparkle_particles = null

func make_style(bg: Color, border: Color, radius: int = 18, border_width: int = 2) -> StyleBoxFlat:
    var st := StyleBoxFlat.new()
    st.bg_color = bg
    st.border_color = border
    st.set_border_width_all(border_width)
    st.set_corner_radius_all(radius)
    st.content_margin_left = 24.0
    st.content_margin_right = 24.0
    st.content_margin_top = 14.0
    st.content_margin_bottom = 14.0
    return st

func style_button(b: Button, accent: Color = Color("#A8754A"), large: bool = false) -> void:
    if not b.has_meta("ui_sfx_bound"):
        b.set_meta("ui_sfx_bound", true)
        b.pressed.connect(func(): play_ui_sound("button"))
    b.add_theme_color_override("font_color", Color.WHITE)
    b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.add_theme_color_override("font_pressed_color", Color.WHITE)
    b.add_theme_color_override("font_focus_color", Color.WHITE)
    b.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#6E4B33"), 18, 2))
    b.add_theme_stylebox_override("hover", make_style(Color("#3A2A20"), Color("#A3754D"), 18, 3))
    b.add_theme_stylebox_override("pressed", make_style(Color("#4A3022"), Color("#B98B5C"), 18, 3))
    b.add_theme_stylebox_override("focus", make_style(Color("#30231B"), Color("#8D6342"), 18, 2))
    b.add_theme_font_size_override("font_size", 30 if large else 22)

func style_panel(p: PanelContainer, bg: Color = Color("#1D1612"), border: Color = Color("#76583F"), radius: int = 26, border_width: int = 3) -> void:
    p.add_theme_stylebox_override("panel", make_style(bg, border, radius, border_width))

func decorate_main_menu_button(b: Button) -> void:
    # Единый стиль главного меню с безопасной областью касания для Android.
    # Функция намеренно не меняет текст и не добавляет новые пункты.
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.focus_mode = Control.FOCUS_ALL
    b.clip_text = true
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.add_theme_font_size_override("font_size", 24)
    b.add_theme_color_override("font_color", Color("#F1E5D6"))
    b.add_theme_color_override("font_hover_color", Color("#FFF4E5"))
    b.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))
    b.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#6E4B33"), 18, 2))
    b.add_theme_stylebox_override("hover", make_style(Color("#3A2A20"), Color("#A3754D"), 18, 3))
    b.add_theme_stylebox_override("pressed", make_style(Color("#4A3022"), Color("#C19A70"), 18, 3))
    b.add_theme_stylebox_override("focus", make_style(Color("#30231B"), Color("#8D6342"), 18, 2))
    b.add_theme_constant_override("outline_size", 0)

func add_neon_header(parent: Control, title_text: String, subtitle_text: String = "") -> void:
    var title := Label.new()
    title.text = title_text
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 40)
    title.modulate = Color("#E1C29A")
    title.custom_minimum_size = Vector2(0, 62)
    parent.add_child(title)
    if subtitle_text != "":
        var sub := Label.new()
        sub.text = subtitle_text
        sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sub.add_theme_font_size_override("font_size", 17)
        sub.modulate = Color("#9FB8D9")
        parent.add_child(sub)

func build_ui() -> void:
    await set_loading_status("СОЗДАНИЕ ГЛАВНОГО МЕНЮ...")
    menu_layer = Control.new()
    menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # Главное меню создаётся во время загрузки, но НЕ должно быть видно до её
    # полного завершения. Иначе пользователь может увидеть меню поверх
    # незавершённой инициализации.
    menu_layer.visible = false
    add_child(menu_layer)

    var backdrop := ColorRect.new()
    backdrop.color = Color(0.035, 0.027, 0.022, 0.99)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(backdrop)

    # Мобильная компоновка главного меню: крупная кнопка игры и сетка 2x3.
    # Новых пунктов не добавляем — только меняем расположение существующих.
    var top_panel := Panel.new()
    top_panel.position = Vector2(55, 70)
    top_panel.size = Vector2(970, 170)
    top_panel.add_theme_stylebox_override("panel", make_style(Color("#1C1511"), Color("#76583F"), 30, 3))
    menu_layer.add_child(top_panel)

    var brand := Label.new()
    brand.name = "MainMenuTitle"
    brand.text = "ХВАТАЙКА"
    brand.position = Vector2(24, 22)
    brand.size = Vector2(922, 78)
    brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    brand.add_theme_font_size_override("font_size", 56)
    brand.modulate = Color("#E1C29A")
    top_panel.add_child(brand)
    main_menu_controls.append(brand)

    var subtitle := Label.new()
    subtitle.text = "СИМУЛЯТОР АРКАДНОЙ ХВАТАЙКИ"
    subtitle.position = Vector2(24, 105)
    subtitle.size = Vector2(922, 38)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.modulate = Color("#9E846D")
    top_panel.add_child(subtitle)
    main_menu_controls.append(subtitle)

    var play := make_menu_button("▶  ИГРАТЬ", Vector2(75, 265), Vector2(930, 92), Color("#A8754A"), true)
    play.pressed.connect(start_game)
    start_button = play
    menu_layer.add_child(play); main_menu_controls.append(play)
    decorate_main_menu_button(play)

    # Основные игровые разделы. Единая тёмно-коричневая/кремовая гамма.
    # 2 колонки, крупные кнопки — удобно для Android.
    var left_x := 75.0
    var right_x := 555.0
    var col_w := 450.0
    var row_h := 82.0
    var gap := 16.0
    var y1 := 380.0
    var y2 := y1 + row_h + gap
    var y3 := y2 + row_h + gap
    var y4 := y3 + row_h + gap

    var shop := make_menu_button("🛒  МАГАЗИН", Vector2(left_x, y1), Vector2(col_w, row_h), Color("#76583F"))
    shop.pressed.connect(func(): open_panel("shop"))
    menu_layer.add_child(shop); main_menu_controls.append(shop); decorate_main_menu_button(shop)

    var coll := make_menu_button("★  КОЛЛЕКЦИЯ", Vector2(right_x, y1), Vector2(col_w, row_h), Color("#8A684C"))
    coll.pressed.connect(func(): open_panel("collection"))
    menu_layer.add_child(coll); main_menu_controls.append(coll); decorate_main_menu_button(coll)

    var achievements := make_menu_button("🏆  ДОСТИЖЕНИЯ", Vector2(left_x, y2), Vector2(col_w, row_h), Color("#8A684C"))
    achievements.pressed.connect(func(): open_panel("achievements"))
    menu_layer.add_child(achievements); main_menu_controls.append(achievements); decorate_main_menu_button(achievements)

    var referral := make_menu_button("👥  РЕФЕРАЛЬНАЯ СИСТЕМА", Vector2(right_x, y2), Vector2(col_w, row_h), Color("#8A684C"))
    referral.pressed.connect(func(): open_panel("referral"))
    menu_layer.add_child(referral); main_menu_controls.append(referral); decorate_main_menu_button(referral)

    var promo := make_menu_button("🎟  ПРОМОКОДЫ", Vector2(left_x, y3), Vector2(col_w, row_h), Color("#76583F"))
    promo.pressed.connect(func(): open_panel("promo"))
    menu_layer.add_child(promo); main_menu_controls.append(promo); decorate_main_menu_button(promo)

    var rating := make_menu_button("🏆  РЕЙТИНГ", Vector2(right_x, y3), Vector2(col_w, row_h), Color("#76583F"))
    rating.pressed.connect(func(): open_panel("rating"))
    menu_layer.add_child(rating); main_menu_controls.append(rating); decorate_main_menu_button(rating)

    news_menu_button = make_menu_button("📰  НОВОСТИ", Vector2(left_x, y4), Vector2(col_w, row_h), Color("#76583F"))
    news_menu_button.pressed.connect(func(): open_panel("news"))
    menu_layer.add_child(news_menu_button); main_menu_controls.append(news_menu_button); decorate_main_menu_button(news_menu_button)

    var settings := make_menu_button("⚙  НАСТРОЙКИ", Vector2(right_x, y4), Vector2(col_w, row_h), Color("#5E554D"))
    settings.pressed.connect(func(): open_panel("settings"))
    menu_layer.add_child(settings); main_menu_controls.append(settings); decorate_main_menu_button(settings)

    var help := make_menu_button("❓  ПОМОЩЬ", Vector2(left_x, y4 + row_h + gap), Vector2(930, row_h), Color("#76583F"))
    help.pressed.connect(func(): open_panel("help"))
    menu_layer.add_child(help); main_menu_controls.append(help); decorate_main_menu_button(help)
    await set_loading_progress(82.0, "ГЛАВНОЕ МЕНЮ ГОТОВО")
    await get_tree().process_frame

    await set_loading_status("HUD ГОТОВ...")
    hud_layer = Control.new()
    hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_layer.visible = false
    add_child(hud_layer)
    # Полноэкранный невидимый блокировщик ввода для модальных окон.
    # Он находится под самим окном, но над игровыми кнопками, поэтому касания
    # по открытой панели никогда не проходят на нижний слой.
    gameplay_modal_blocker = Control.new()
    gameplay_modal_blocker.name = "GameplayModalBlocker"
    gameplay_modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    gameplay_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
    gameplay_modal_blocker.visible = false
    gameplay_modal_blocker.z_index = 20
    hud_layer.add_child(gameplay_modal_blocker)
    build_hud()
    await get_tree().process_frame
    await set_loading_progress(83.0, "HUD ГОТОВ")

    await set_loading_status("МАГАЗИН ГОТОВ...")
    shop_panel = build_shop_panel()
    await get_tree().process_frame
    await set_loading_progress(84.0, "МАГАЗИН ГОТОВ")

    await set_loading_status("КОЛЛЕКЦИЯ ГОТОВА...")
    collection_panel = build_collection_panel()
    await get_tree().process_frame
    await set_loading_progress(85.0, "КОЛЛЕКЦИЯ ГОТОВА")

    await set_loading_status("НАСТРОЙКИ ГОТОВЫ...")
    settings_panel = build_settings_panel()
    await get_tree().process_frame
    achievements_panel = build_achievements_panel()
    await get_tree().process_frame
    await set_loading_progress(86.0, "НАСТРОЙКИ И ДОСТИЖЕНИЯ ГОТОВЫ")

    await set_loading_status("ПРОФИЛЬ И ПОМОЩЬ ГОТОВЫ...")
    profile_panel = build_profile_panel()
    await get_tree().process_frame
    help_panel = build_help_panel()
    await get_tree().process_frame
    await set_loading_progress(87.0, "ПРОФИЛЬ И ПОМОЩЬ ГОТОВЫ")

    await set_loading_status("РЕФЕРАЛЫ И VIP ГОТОВЫ...")
    referral_panel = build_referral_panel()
    await get_tree().process_frame
    vip_panel = build_vip_panel()
    await get_tree().process_frame
    await set_loading_progress(88.0, "РЕФЕРАЛЫ И VIP ГОТОВЫ")

    await set_loading_status("СЕЗОНЫ И СУНДУКИ ГОТОВЫ...")
    seasons_panel = build_seasons_panel()
    await get_tree().process_frame
    chests_panel = build_chests_panel()
    await get_tree().process_frame
    await set_loading_progress(89.0, "СЕЗОНЫ И СУНДУКИ ГОТОВЫ")

    await set_loading_status("МАСТЕРСКАЯ И ПРОПУСК ГОТОВЫ...")
    workshop_panel = build_workshop_panel()
    await get_tree().process_frame
    season_pass_panel = build_season_pass_panel()
    await get_tree().process_frame
    await set_loading_progress(90.0, "МАСТЕРСКАЯ И ПРОПУСК ГОТОВЫ")

    await set_loading_status("ПРОМОКОДЫ И НОВОСТИ ГОТОВЫ...")
    promo_panel = build_promo_panel()
    await get_tree().process_frame
    news_panel = build_news_panel()
    await get_tree().process_frame
    await set_loading_progress(91.0, "ПРОМОКОДЫ И НОВОСТИ ГОТОВЫ")

    await set_loading_status("РЕЙТИНГ И БОНУС ГОТОВЫ...")
    rating_panel = build_rating_panel()
    await get_tree().process_frame
    return_bonus_panel = build_return_bonus_panel()
    await get_tree().process_frame
    await set_loading_progress(92.0, "РЕЙТИНГ И БОНУС ГОТОВЫ")
    # Старый объединённый центр больше не показывается: его функции разобраны по разделам.
    live_systems_panel = null
    await set_loading_status("ОКНО РЕЗУЛЬТАТА ГОТОВО...")
    build_result_popup()
    await get_tree().process_frame
    await set_loading_progress(93.0, "ОКНО РЕЗУЛЬТАТА ГОТОВО")
    await set_loading_status("HUD ЗАВЕРШЁН...")
    build_extra_hud()
    await get_tree().process_frame
    profile_panel.reparent(hud_layer, false)
    seasons_panel.reparent(hud_layer, false)
    chests_panel.reparent(hud_layer, false)
    workshop_panel.reparent(hud_layer, false)
    season_pass_panel.reparent(hud_layer, false)
    return_bonus_panel.reparent(hud_layer, false)
    profile_panel.position = Vector2(18, 150)
    seasons_panel.position = Vector2(35, 150)
    chests_panel.position = Vector2(35, 150)
    workshop_panel.position = Vector2(35, 150)
    season_pass_panel.position = Vector2(35, 150)
    return_bonus_panel.position = Vector2(35, 150)
    seasons_panel.z_index = 30
    chests_panel.z_index = 30
    workshop_panel.z_index = 30
    season_pass_panel.z_index = 30
    return_bonus_panel.z_index = 30
    profile_panel.z_index = 30
    await set_loading_progress(94.0, "HUD ЗАВЕРШЁН")
    await set_loading_status("НАВИГАЦИЯ ANDROID НАСТРОЕНА...")
    setup_android_ui_navigation()
    await get_tree().process_frame
    await set_loading_progress(95.0, "НАВИГАЦИЯ ANDROID НАСТРОЕНА")
    await set_loading_status("ПРОКРУТКА НАСТРОЕНА...")
    setup_android_scrolls()
    await get_tree().process_frame
    await set_loading_progress(96.0, "ПРОКРУТКА НАСТРОЕНА")

func setup_android_scrolls() -> void:
    # Единая настройка прокрутки для всех длинных окон под Android.
    # Вертикальные окна листаются обычным свайпом пальца, а полоска прокрутки
    # остаётся достаточно широкой для точного захвата.
    var stack: Array[Node] = [self]
    while not stack.is_empty():
        var current: Node = stack.pop_back()
        if current is ScrollContainer:
            configure_android_scroll(current)
        for child in current.get_children():
            stack.append(child)

func configure_android_scroll(scroll: ScrollContainer) -> void:
    if scroll.has_meta("android_scroll_configured"):
        return
    scroll.set_meta("android_scroll_configured", true)
    scroll.follow_focus = true
    scroll.scroll_deadzone = 1
    scroll.add_theme_constant_override("scroll_bar_width", 20)
    scroll.add_theme_constant_override("scroll_bar_h_separation", 3)
    if scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
        scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    else:
        # Горизонтальные категории листаются влево/вправо отдельно.
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.mouse_filter = Control.MOUSE_FILTER_STOP

func setup_android_ui_navigation() -> void:
    # Отдельные верхние кнопки «НАЗАД» больше не создаём.
    # Во всех полноэкранных окнах используется существующая кнопка «НАЗАД»
    # внизу содержимого. Системная кнопка Back Android продолжает работать.
    menu_back_button = null
    hud_back_button = null


func make_android_back_button() -> Button:
    var b := Button.new()
    b.text = "←  НАЗАД"
    b.size = Vector2(170, 62)
    b.z_index = 200
    b.focus_mode = Control.FOCUS_ALL
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    style_button(b, Color("#9A7653"))
    b.add_theme_font_size_override("font_size", 20)
    b.pressed.connect(_on_android_back_pressed)
    return b

func _visible_navigation_context() -> String:
    if sale_panel and sale_panel.visible:
        return "sale"
    if result_popup and result_popup.visible:
        return "result"
    if vip_panel and vip_panel.visible:
        return "vip"
    if shop_panel and shop_panel.visible:
        return "shop"
    if collection_panel and collection_panel.visible:
        return "collection"
    if achievements_panel and achievements_panel.visible:
        return "achievements"
    if referral_panel and referral_panel.visible:
        return "referral"
    if settings_panel and settings_panel.visible:
        return "settings"
    if help_panel and help_panel.visible:
        return "help"
    if profile_panel and profile_panel.visible:
        return "profile"
    if seasons_panel and seasons_panel.visible:
        return "seasons"
    if chests_panel and chests_panel.visible:
        return "chests"
    if workshop_panel and workshop_panel.visible:
        return "workshop"
    if season_pass_panel and season_pass_panel.visible:
        return "season_pass"
    if promo_panel and promo_panel.visible:
        return "promo"
    if news_panel and news_panel.visible:
        return "news"
    if rating_panel and rating_panel.visible:
        return "rating"
    if return_bonus_panel and return_bonus_panel.visible:
        return "return_bonus"
    if live_systems_panel and live_systems_panel.visible:
        return "systems"
    if stats_panel and stats_panel.visible:
        return "stats"
    var mission := hud_layer.get_node_or_null("MissionDetailPanel") as PanelContainer
    if mission and mission.visible:
        return "mission"
    if daily_login_panel and daily_login_panel.visible:
        return "daily_login"
    if event_panel and event_panel.visible:
        return "event"
    if waiting_overlay and waiting_overlay.visible:
        return "waiting"
    return ""

func _navigation_panel_for_context(context: String) -> Control:
    match context:
        "sale": return sale_panel
        "result": return result_popup
        "vip": return vip_panel
        "shop": return shop_panel
        "collection": return collection_panel
        "achievements": return achievements_panel
        "referral": return referral_panel
        "settings": return settings_panel
        "help": return help_panel
        "profile": return profile_panel
        "seasons": return seasons_panel
        "chests": return chests_panel
        "workshop": return workshop_panel
        "season_pass": return season_pass_panel
        "news": return news_panel
        "return_bonus": return return_bonus_panel
        "systems": return live_systems_panel
        "stats": return stats_panel
        "mission": return hud_layer.get_node_or_null("MissionDetailPanel") as Control
        "daily_login": return daily_login_panel
        "event": return event_panel
    return null

func update_android_navigation() -> void:
    # Верхние кнопки навигации отключены намеренно: в окнах остаётся только
    # одна кнопка выхода внизу, а системный Back Android работает отдельно.
    if menu_back_button and is_instance_valid(menu_back_button):
        menu_back_button.visible = false
    if hud_back_button and is_instance_valid(hud_back_button):
        hud_back_button.visible = false
    _last_nav_context = _visible_navigation_context()

func _dismiss_gameplay_side_panels_on_tap() -> void:
    # Любое свободное касание игрового поля закрывает открытое боковое окно.
    # Нажатие на другой круг закрывает предыдущее через close_side_panels().
    var mission_panel := hud_layer.get_node_or_null("MissionDetailPanel") as PanelContainer
    var has_side_panel: bool = (mission_panel != null and mission_panel.visible) or (daily_login_panel != null and daily_login_panel.visible) or (event_panel != null and event_panel.visible)
    if has_side_panel:
        close_side_panels()

func _on_android_back_pressed() -> void:
    var context := _visible_navigation_context()
    match context:
        "sale":
            if sale_panel:
                sale_panel.visible = false
            if result_popup:
                result_popup.visible = false
        "result":
            result_popup.visible = false
        "waiting":
            if waiting_overlay:
                waiting_overlay.visible = false
        "vip":
            vip_panel.visible = false
            shop_panel.visible = true
            refresh_shop()
        "shop", "collection", "achievements", "referral", "settings", "help", "stats", "promo", "news", "rating":
            show_main_menu()
        "profile", "seasons", "chests", "workshop", "season_pass", "return_bonus", "mission", "daily_login", "event":
            close_gameplay_overlay()
        _:
            if hud_layer.visible:
                show_main_menu()
    update_android_navigation()

func _input(event: InputEvent) -> void:
    # Боковые игровые окна закрываются касанием вне самого окна.
    # Это позволяет выйти из любого правого кружка одним тапом по игровому полю,
    # не ломая нажатия кнопок внутри открытого окна.
    if not hud_layer or not hud_layer.visible:
        return
    if event is InputEventScreenTouch and event.pressed:
        var pos := event.position
        var panel := _get_open_gameplay_side_panel()
        if panel and not Rect2(panel.global_position, panel.size).has_point(pos):
            close_side_panels()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var mpos := event.position
        var mpanel := _get_open_gameplay_side_panel()
        if mpanel and not Rect2(mpanel.global_position, mpanel.size).has_point(mpos):
            close_side_panels()

func _get_open_gameplay_side_panel() -> Control:
    var mission_panel := hud_layer.get_node_or_null("MissionDetailPanel") as Control
    if mission_panel and mission_panel.visible: return mission_panel
    if daily_login_panel and daily_login_panel.visible: return daily_login_panel
    if event_panel and event_panel.visible: return event_panel
    return null

func _unhandled_input(event: InputEvent) -> void:
    if blocked_overlay and is_instance_valid(blocked_overlay) and blocked_overlay.visible:
        get_viewport().set_input_as_handled()
        return
    # Свободное касание/клик по игровому полю закрывает открытое боковое окно.
    # Кнопки интерфейса обрабатываются раньше и сюда не попадают.
    if event is InputEventScreenTouch and event.pressed:
        _dismiss_gameplay_side_panels_on_tap()
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _dismiss_gameplay_side_panels_on_tap()
        return

    # Android system Back закрывает окно сначала, а не игру.
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            if _visible_navigation_context() != "":
                _on_android_back_pressed()
                get_viewport().set_input_as_handled()

func get_menu_notice_text() -> String:
    var notices := 0
    for key in chest_inventory.keys():
        notices += int(chest_inventory.get(key, 0))
    if workshop_parts > 0:
        notices += 1
    if active_event_name != "":
        notices += 1
    return "● %d новых события/награды" % notices if notices > 0 else "Всё готово • можно играть"

func build_extra_hud() -> void:
    # ЛЕВАЯ ВЕРТИКАЛЬ: сезоны/праздники + сундуки + мастерская.
    # Эти кнопки находятся только на игровом экране и НЕ добавляются в главное меню.
    var season_icon := get_current_season_icon()
    var seasons_btn := make_menu_circle_button(season_icon, "СЕЗОНЫ И ПРАЗДНИКИ", Vector2(20, 185), Color("#4D8068"))
    seasons_btn.name = "SeasonsCircleButton"
    seasons_btn.pressed.connect(func(): open_panel("seasons"))
    hud_layer.add_child(seasons_btn)

    var season_caption := Label.new()
    season_caption.name = "SeasonCircleCaption"
    season_caption.position = Vector2(8, 263)
    season_caption.size = Vector2(102, 28)
    season_caption.text = get_current_season_short_name()
    season_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    season_caption.add_theme_font_size_override("font_size", 11)
    season_caption.modulate = Color("#E1C29A")
    hud_layer.add_child(season_caption)

    # Возвращаем сундуки и мастерскую на главный экран: это НЕ пункты меню.
    var chests_btn := make_menu_circle_button("🎁", "СУНДУКИ", Vector2(20, 280), Color("#7A5A42"))
    chests_btn.name = "ChestsCircleButton"
    chests_btn.pressed.connect(func(): open_panel("chests"))
    hud_layer.add_child(chests_btn)

    var workshop_btn := make_menu_circle_button("🛠", "МАСТЕРСКАЯ", Vector2(20, 375), Color("#536B82"))
    workshop_btn.name = "WorkshopCircleButton"
    workshop_btn.pressed.connect(func(): open_panel("workshop"))
    hud_layer.add_child(workshop_btn)

    var daily_btn := Button.new()
    daily_btn.text = "🎯"
    daily_btn.position = Vector2(948, 185)
    daily_btn.size = Vector2(82, 82)
    style_button(daily_btn, Color("#9A7653"))
    daily_btn.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#9A7653"), 41, 3))
    daily_btn.add_theme_stylebox_override("hover", make_style(Color("#3A2A20"), Color("#C09A70"), 41, 4))
    daily_btn.add_theme_stylebox_override("pressed", make_style(Color("#4A3022"), Color("#E1C29A"), 41, 4))
    daily_btn.add_theme_font_size_override("font_size", 28)
    daily_btn.tooltip_text = "Миссия дня"
    daily_btn.pressed.connect(toggle_daily_mission)
    hud_layer.add_child(daily_btn)

    var weekly_btn := Button.new()
    weekly_btn.text = "🏆"
    weekly_btn.position = Vector2(948, 280)
    weekly_btn.size = Vector2(82, 82)
    style_button(weekly_btn, Color("#76583F"))
    weekly_btn.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#76583F"), 41, 3))
    weekly_btn.add_theme_stylebox_override("hover", make_style(Color("#3A2A20"), Color("#A3754D"), 41, 4))
    weekly_btn.add_theme_stylebox_override("pressed", make_style(Color("#4A3022"), Color("#E1C29A"), 41, 4))
    weekly_btn.add_theme_font_size_override("font_size", 28)
    weekly_btn.tooltip_text = "Недельная миссия"
    weekly_btn.pressed.connect(toggle_weekly_mission)
    hud_layer.add_child(weekly_btn)

    daily_claim_button = Button.new()
    daily_claim_button.text = "🎁"
    daily_claim_button.position = Vector2(948, 375)
    daily_claim_button.size = Vector2(82, 82)
    style_button(daily_claim_button, Color("#C09A70"))
    daily_claim_button.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#C09A70"), 41, 3))
    daily_claim_button.add_theme_font_size_override("font_size", 28)
    daily_claim_button.tooltip_text = "Ежедневная серия"
    daily_claim_button.pressed.connect(toggle_daily_login)
    hud_layer.add_child(daily_claim_button)

    # Правый нижний круг — именно НЕДЕЛЬНЫЕ СОБЫТИЯ, отдельно от сезонов и праздников.
    event_button = Button.new()
    event_button.text = "⚡"
    event_button.position = Vector2(948, 470)
    event_button.size = Vector2(82, 82)
    style_button(event_button, Color("#8A684C"))
    event_button.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#8A684C"), 41, 3))
    event_button.add_theme_stylebox_override("hover", make_style(Color("#3A2A20"), Color("#C09A70"), 41, 4))
    event_button.add_theme_stylebox_override("pressed", make_style(Color("#4A3022"), Color("#E1C29A"), 41, 4))
    event_button.add_theme_font_size_override("font_size", 28)
    event_button.tooltip_text = "НЕДЕЛЬНЫЕ СОБЫТИЯ"
    event_button.pressed.connect(toggle_event_panel)
    hud_layer.add_child(event_button)

    build_daily_login_panel()
    build_event_panel()

    var mission_panel := PanelContainer.new()
    mission_panel.name = "MissionDetailPanel"
    mission_panel.position = Vector2(500, 170)
    mission_panel.size = Vector2(430, 205)
    mission_panel.visible = false
    style_panel(mission_panel, Color("#6E4B33"), Color("#A3754D"), 22, 3)
    hud_layer.add_child(mission_panel)
    var mv := VBoxContainer.new()
    mv.name = "MissionDetailVBox"
    mv.alignment = BoxContainer.ALIGNMENT_CENTER
    mv.add_theme_constant_override("separation", 10)
    mission_panel.add_child(mv)
    var mt := Label.new()
    mt.name = "MissionDetailTitle"
    mt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mt.add_theme_font_size_override("font_size", 23)
    mt.modulate = Color("#E1C29A")
    mv.add_child(mt)
    var md := Label.new()
    md.name = "MissionDetailText"
    md.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    md.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    md.add_theme_font_size_override("font_size", 18)
    mv.add_child(md)

func animate_panel_in(panel: Control, from_scale: float = 0.94) -> void:
    if not panel or not is_instance_valid(panel):
        return
    panel.pivot_offset = panel.size * 0.5
    panel.scale = Vector2(from_scale, from_scale)
    panel.modulate.a = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(panel, "scale", Vector2.ONE, 0.18)
    tween.tween_property(panel, "modulate:a", 1.0, 0.14)
    play_ui_sound("open")

func animate_panel_out(panel: Control) -> void:
    if not panel or not is_instance_valid(panel):
        return
    var tween := create_tween()
    tween.set_parallel(true)
    tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_property(panel, "scale", Vector2(0.96, 0.96), 0.10)
    tween.tween_property(panel, "modulate:a", 0.0, 0.08)

func close_side_panels(except_name: String = "") -> void:
    var mission_panel := hud_layer.get_node_or_null("MissionDetailPanel") as PanelContainer
    if mission_panel and except_name != "MissionDetailPanel" and mission_panel.visible:
        animate_panel_out(mission_panel)
        mission_panel.visible = false
    if daily_login_panel and except_name != "DailyLoginPanel" and daily_login_panel.visible:
        daily_login_panel.visible = false
        daily_login_panel.scale = Vector2.ONE
        daily_login_panel.modulate.a = 1.0
    if event_panel and except_name != "EventPanel" and event_panel.visible:
        animate_panel_out(event_panel)
        event_panel.visible = false
    if return_bonus_panel and except_name != "ReturnBonusPanel" and return_bonus_panel.visible:
        animate_panel_out(return_bonus_panel)
        return_bonus_panel.visible = false
    update_android_navigation()

func toggle_daily_mission() -> void:
    toggle_mission_detail(true)

func toggle_weekly_mission() -> void:
    toggle_mission_detail(false)

func toggle_mission_detail(is_daily: bool) -> void:
    var panel := hud_layer.get_node_or_null("MissionDetailPanel") as PanelContainer
    if not panel: return
    if panel.visible and String(panel.get_meta("mission_type", "")) == ("daily" if is_daily else "weekly"):
        panel.visible = false
        update_android_navigation()
        return
    close_side_panels("MissionDetailPanel")
    panel.set_meta("mission_type", "daily" if is_daily else "weekly")
    var title := panel.get_node("MissionDetailVBox/MissionDetailTitle") as Label
    var detail := panel.get_node("MissionDetailVBox/MissionDetailText") as Label
    if is_daily:
        title.text = "🎯 МИССИЯ ДНЯ"
        detail.text = "Поймай %d игрушки\nПрогресс: %d / %d\nНаграда: +50 ₽" % [daily_mission_target, daily_mission_progress, daily_mission_target]
    else:
        title.text = "🏆 НЕДЕЛЬНОЕ ЗАДАНИЕ"
        detail.text = "Поймай %d игрушек\nПрогресс: %d / %d\nНаграда: +180 ₽" % [weekly_mission_target, weekly_mission_progress, weekly_mission_target]
    panel.visible = true
    animate_panel_in(panel)
    update_android_navigation()

func _calendar_day_number(date_str: String) -> int:
    # Локальная дата без привязки к часовому поясу/UTC. Используется для
    # ежедневной серии, чтобы переход на следующий день на Android не ломал
    # получение награды около полуночи.
    var parts := date_str.split("-")
    if parts.size() != 3:
        return -1
    var y := int(parts[0])
    var m := int(parts[1])
    var d := int(parts[2])
    if y < 1 or m < 1 or m > 12 or d < 1 or d > 31:
        return -1
    var total := 365 * (y - 1) + int(floor(float(y - 1) / 4.0)) - int(floor(float(y - 1) / 100.0)) + int(floor(float(y - 1) / 400.0))
    var month_days := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if (y % 4 == 0 and y % 100 != 0) or y % 400 == 0:
        month_days[1] = 29
    for i in range(m - 1):
        total += month_days[i]
    return total + d

func setup_login_streak() -> void:
    var today := Time.get_date_string_from_system()
    daily_claim_available = last_login_claim_date != today
    if last_login_claim_date == "":
        login_streak = 0
    elif last_login_claim_date != today:
        var gap := _calendar_day_number(today) - _calendar_day_number(last_login_claim_date)
        if gap > 1:
            login_streak = 0
        elif gap == 1 and login_streak >= 7:
            # После седьмого дня начинается новый семидневный цикл.
            login_streak = 0
    update_daily_login_ui()

func build_daily_login_panel() -> void:
    daily_login_panel = PanelContainer.new()
    daily_login_panel.name = "DailyLoginPanel"
    # Компактная карточка, привязанная к правому кругу. На Android она
    # полностью помещается в экран и раскрывается влево от кнопки.
    daily_login_panel.position = Vector2(20, 320)
    daily_login_panel.size = Vector2(130, 72)
    daily_login_panel.visible = false
    style_panel(daily_login_panel, Color("#6E4B33"), Color("#A3754D"), 22, 3)
    hud_layer.add_child(daily_login_panel)

    var v := VBoxContainer.new()
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 3)
    daily_login_panel.add_child(v)

    var title := Label.new()
    title.name = "DailyLoginTitle"
    title.text = "🎁 ЕЖЕДНЕВНАЯ СЕРИЯ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 6)
    v.add_child(title)

    var detail := Label.new()
    detail.name = "DailyLoginText"
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    detail.add_theme_font_size_override("font_size", 5)
    v.add_child(detail)

    daily_days_container = GridContainer.new()
    daily_days_container.name = "DailyDaysGrid"
    daily_days_container.columns = 4
    daily_days_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    daily_days_container.add_theme_constant_override("h_separation", 1)
    daily_days_container.add_theme_constant_override("v_separation", 1)
    v.add_child(daily_days_container)

    daily_day_buttons.clear()
    for day in range(1, 8):
        var day_button := Button.new()
        day_button.name = "DailyDay%d" % day
        day_button.custom_minimum_size = Vector2(30, 18)
        day_button.add_theme_font_size_override("font_size", 3)
        day_button.mouse_filter = Control.MOUSE_FILTER_STOP
        day_button.focus_mode = Control.FOCUS_ALL
        day_button.set_meta("day_index", day)
        # Используем bind вместо захвата переменной цикла: на Android каждый день
        # гарантированно получает свой обработчик нажатия.
        day_button.pressed.connect(claim_login_reward_for_day.bind(day))
        daily_days_container.add_child(day_button)
        daily_day_buttons.append(day_button)

    var hint := Label.new()
    hint.name = "DailyLoginHint"
    hint.text = "Нажми на день, который доступен сейчас"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 3)
    v.add_child(hint)

func update_daily_login_ui() -> void:
    if not daily_claim_button: return
    if daily_claim_available:
        daily_claim_button.modulate.a = 0.65 + 0.35 * (0.5 + 0.5 * sin(time_alive * 5.0))
    else:
        daily_claim_button.modulate.a = 0.65

    if daily_login_panel and daily_login_panel.visible:
        var detail := daily_login_panel.get_node_or_null("VBoxContainer/DailyLoginText") as Label
        var current_day := mini(login_streak + (1 if daily_claim_available else 0), 7)
        var reward := 20 + current_day * 5
        if detail:
            detail.text = "Серия: %d дней   •   День %d из 7\nСегодняшняя награда: +%d ₽" % [login_streak, current_day, reward]

        for i in range(daily_day_buttons.size()):
            var day := i + 1
            var btn := daily_day_buttons[i]
            var claimed := day <= login_streak
            var available := daily_claim_available and day == current_day
            # Не блокируем кнопки через disabled: на некоторых Android-сборках
            # отключённая кнопка визуально выглядит доступной, но не получает touch.
            # Обработчик сам проверяет, можно ли забрать этот день.
            btn.disabled = false
            if claimed:
                btn.text = "✓ ДЕНЬ %d\n🎁 ПРИЗ ПОЛУЧЕН" % day
                btn.tooltip_text = "Приз за этот день уже получен"
                style_button(btn, Color("#5FBF72"))
            elif available:
                btn.text = "🎁 ДЕНЬ %d\n+%d ₽\nЗАБРАТЬ" % [day, 20 + day * 5]
                btn.tooltip_text = "Забрать приз за сегодняшний день"
                style_button(btn, Color("#C09A70"))
            else:
                btn.text = "🔒 ДЕНЬ %d\n+%d ₽" % [day, 20 + day * 5]
                style_button(btn, Color("#5B5B66"))

func toggle_daily_login() -> void:
    if not daily_login_panel:
        return
    if daily_login_panel.visible:
        animate_panel_out(daily_login_panel)
        await get_tree().create_timer(0.10).timeout
        if is_instance_valid(daily_login_panel): daily_login_panel.visible = false
        return
    setup_login_streak()
    close_side_panels("DailyLoginPanel")
    daily_login_panel.visible = true
    # Небольшое появление от точки правого круга: окно выглядит как часть той же навигации.
    # Центр карточки совпадает с центром правого круга; раскрытие идёт строго влево.
    # Правый край карточки совпадает с внутренним краем правой вертикали кнопок.
    var right_edge := 1030.0
    var final_x := maxf(8.0, right_edge - daily_login_panel.size.x)
    var final_pos := Vector2(final_x, 320)
    daily_login_panel.position = Vector2(final_x + 55.0, 320)
    daily_login_panel.modulate.a = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(daily_login_panel, "position", final_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(daily_login_panel, "modulate:a", 1.0, 0.16)
    play_ui_sound("open")
    update_daily_login_ui()
    update_android_navigation()

func claim_login_reward() -> void:
    # Оставляем совместимость со старой кнопкой, но теперь награда забирается
    # нажатием на доступный день в списке из 7 дней.
    var current_day := mini(login_streak + (1 if daily_claim_available else 0), 7)
    claim_login_reward_for_day(current_day)

func claim_login_reward_for_day(day: int) -> void:
    if SERVER_AUTHORITATIVE:
        if day < 1 or day > 7: return
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; update_ui(); return
        if _server_action("daily_login", {"day":day, "local_date":Time.get_date_string_from_system()}):
            current_result = "ЕЖЕДНЕВНАЯ НАГРАДА ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; update_ui()
        return
    # Обработчик намеренно идемпотентный: повторное касание после получения
    # награды ничего не выдаёт повторно.
    if day < 1 or day > 7:
        return
    if not daily_claim_available:
        update_daily_login_ui()
        return

    var current_day := clampi(login_streak + 1, 1, 7)
    if day != current_day:
        if toast_label:
            toast_label.text = "🔒 Сначала заберите доступный ДЕНЬ %d" % current_day
            toast_label.visible = true
        return

    var today := Time.get_date_string_from_system()
    var today_day := _calendar_day_number(today)
    if last_login_claim_date != "":
        var last_day := _calendar_day_number(last_login_claim_date)
        var gap := today_day - last_day
        if gap == 1:
            login_streak += 1
        elif gap > 1:
            login_streak = 1
        else:
            # Защита от повторного получения в тот же календарный день.
            return
    else:
        login_streak = 1

    login_streak = clampi(login_streak, 1, 7)
    var reward := server_reward_amount(20 + login_streak * 5)
    coins += reward
    last_login_claim_date = today
    daily_claim_available = false
    current_result = "🎁 ЕЖЕДНЕВНАЯ НАГРАДА • ДЕНЬ %d • +%d ₽" % [login_streak, reward]
    save_game()
    update_ui()
    update_daily_login_ui()
    if toast_label:
        toast_label.text = "🎁 ДЕНЬ %d ПОЛУЧЕН • +%d ₽" % [login_streak, reward]
        toast_label.visible = true

func setup_events() -> void:
    # Сезоны и праздники теперь являются реальными игровыми событиями.
    # Событие выбирается по календарю, а не случайно, поэтому оформление и бонусы
    # соответствуют текущей дате и не сбрасываются каждые несколько минут.
    activate_calendar_event()

func get_today_event() -> Dictionary:
    var dt := Time.get_datetime_dict_from_system()
    var key := "%02d-%02d" % [int(dt.get("month", 1)), int(dt.get("day", 1))]
    for h in holiday_calendar:
        if String(h.get("date", "")) == key:
            return {"id":"holiday_" + key, "name":String(h.get("name", "Праздник")), "theme":String(h.get("season", "")), "holiday":true}
    var season := get_current_season()
    return {"id":"season_" + String(season.get("id", "")), "name":String(season.get("name", "Сезон")), "theme":String(season.get("id", "")), "holiday":false}

func get_event_profile(event: Dictionary) -> Dictionary:
    var id := String(event.get("id", ""))
    var profile := {"accent":Color("#8A684C"), "glow":Color("#F2DCC0"), "capture":0.06, "reward":1.15, "rare":0.04, "toy":0.35, "title":String(event.get("name", "Событие"))}
    # Большие праздники получают более заметные бонусы и тематические цвета.
    if id == "holiday_12-31" or id == "holiday_01-01":
        profile = {"accent":Color("#D6A73A"), "glow":Color("#FFF0B0"), "capture":0.10, "reward":1.50, "rare":0.10, "toy":0.55, "title":"🎆 НОВОГОДНИЙ ПРАЗДНИК"}
    elif id == "holiday_10-31":
        profile = {"accent":Color("#FF7A2F"), "glow":Color("#FFB14E"), "capture":0.12, "reward":1.65, "rare":0.14, "toy":0.60, "title":"🎃 ХЭЛЛОУИН"}
    elif id == "holiday_02-14":
        profile = {"accent":Color("#FF4F8B"), "glow":Color("#FF9FC2"), "capture":0.08, "reward":1.35, "rare":0.08, "toy":0.50, "title":"❤️ ДЕНЬ ВЛЮБЛЁННЫХ"}
    elif id == "holiday_06-01":
        profile = {"accent":Color("#38B86B"), "glow":Color("#8DEBFF"), "capture":0.10, "reward":1.45, "rare":0.10, "toy":0.65, "title":"🧸 ДЕНЬ ЗАЩИТЫ ДЕТЕЙ"}
    elif id == "holiday_06-12":
        profile = {"accent":Color("#4D83FF"), "glow":Color("#E9F2FF"), "capture":0.08, "reward":1.40, "rare":0.08, "toy":0.50, "title":"🇷🇺 ДЕНЬ РОССИИ"}
    elif id == "holiday_09-01":
        profile = {"accent":Color("#3E8ED0"), "glow":Color("#FFD65A"), "capture":0.07, "reward":1.30, "rare":0.06, "toy":0.45, "title":"🎒 ДЕНЬ ЗНАНИЙ"}
    elif id.begins_with("holiday_"):
        profile = {"accent":Color("#8A4DFF"), "glow":Color("#D7C7FF"), "capture":0.08, "reward":1.30, "rare":0.06, "toy":0.45, "title":String(event.get("name", "ПРАЗДНИК"))}
    else:
        var sid := String(event.get("theme", ""))
        match sid:
            "winter": profile = {"accent":Color("#4D9FE8"), "glow":Color("#C9F3FF"), "capture":0.06, "reward":1.15, "rare":0.04, "toy":0.35, "title":"❄️ ЗИМНИЙ СЕЗОН"}
            "spring": profile = {"accent":Color("#59B879"), "glow":Color("#FFD4E8"), "capture":0.06, "reward":1.15, "rare":0.04, "toy":0.35, "title":"🌸 ВЕСЕННИЙ СЕЗОН"}
            "summer": profile = {"accent":Color("#2BB7D8"), "glow":Color("#FFE27A"), "capture":0.06, "reward":1.15, "rare":0.04, "toy":0.35, "title":"☀️ ЛЕТНИЙ СЕЗОН"}
            "autumn": profile = {"accent":Color("#C56A32"), "glow":Color("#FFD08A"), "capture":0.06, "reward":1.15, "rare":0.04, "toy":0.35, "title":"🍂 ОСЕННИЙ СЕЗОН"}
    return profile

func activate_calendar_event() -> void:
    var event := get_today_event()
    var profile := get_event_profile(event)
    active_event_id = String(event.get("id", ""))
    active_event_name = String(profile.get("title", event.get("name", "Событие")))
    active_event_theme = String(event.get("theme", ""))
    active_event_end_unix = int(Time.get_unix_time_from_system()) + 86400
    active_event_accent = Color(profile.get("accent", Color("#8A684C")))
    active_event_glow = Color(profile.get("glow", Color("#F2DCC0")))
    active_event_bonus = float(profile.get("capture", 0.06))
    active_event_reward_mult = float(profile.get("reward", 1.15))
    active_event_rare_bonus = float(profile.get("rare", 0.0))
    active_event_toy_bonus = float(profile.get("toy", 0.35))
    apply_event_theme()
    if event_panel:
        update_event_panel()
    if event_button:
        event_button.tooltip_text = "НЕДЕЛЬНЫЕ СОБЫТИЯ"
        event_button.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#8A684C"), 41, 3))
    save_game()
    if notifications_on:
        schedule_background_notifications()

func apply_event_theme() -> void:
    # Меняем только визуальный слой и свет — модели аппарата и весь игровой контент сохраняются.
    for light in machine_lights:
        if light and is_instance_valid(light):
            light.light_color = active_event_glow
    if event_button and is_instance_valid(event_button):
        event_button.add_theme_stylebox_override("normal", make_style(Color("#241B16"), active_event_accent, 41, 3))
        event_button.add_theme_stylebox_override("hover", make_style(Color("#3A2A20"), active_event_glow, 41, 4))
        event_button.add_theme_stylebox_override("pressed", make_style(Color("#4A3022"), active_event_glow, 41, 4))
    if event_panel and is_instance_valid(event_panel):
        style_panel(event_panel, Color("#6E4B33"), Color("#A3754D"), 22, 3)
    if world_environment and is_instance_valid(world_environment) and world_environment.environment:
        world_environment.environment.background_color = active_event_accent.darkened(0.82)
    build_event_decorations()

func build_event_decorations() -> void:
    if event_decor_root and is_instance_valid(event_decor_root):
        event_decor_root.queue_free()
    event_decor_root = Node3D.new()
    event_decor_root.name = "CalendarEventDecorations"
    add_child(event_decor_root)
    # Лёгкие 3D-декорации без внешних ассетов: праздник виден прямо на аппарате.
    var deco_mat := make_mat(active_event_accent, 0.35, 0.28, 0.55)
    var glow_mat := make_mat(active_event_glow, 0.15, 0.30, 1.2)
    for x in [-2.75, 0.0, 2.75]:
        make_sphere(event_decor_root, 0.09, Vector3(x, 8.95, 1.72), glow_mat, "EventLight")
    var dt := Time.get_datetime_dict_from_system()
    var month := int(dt.get("month", 1)); var day := int(dt.get("day", 1))
    if month == 10 and day == 31:
        make_sphere(event_decor_root, 0.30, Vector3(-3.15, 7.0, 1.70), deco_mat, "Pumpkin")
        make_sphere(event_decor_root, 0.30, Vector3(3.15, 7.0, 1.70), deco_mat, "Pumpkin")
    elif month == 12 or (month == 1 and day <= 7):
        for x in [-3.0, 3.0]:
            make_sphere(event_decor_root, 0.20, Vector3(x, 7.1, 1.70), glow_mat, "WinterOrnament")
    elif month == 2 and day == 14:
        for x in [-3.0, 3.0]:
            make_sphere(event_decor_root, 0.18, Vector3(x, 7.15, 1.70), deco_mat, "HeartDecoration")
    elif month == 6 and day == 1:
        for x in [-3.0, 3.0]:
            make_sphere(event_decor_root, 0.22, Vector3(x, 7.15, 1.70), glow_mat, "ToyDayDecoration")

func start_random_event() -> void:
    # Совместимость со старым сохранением/старым вызовом: событие всегда календарное.
    activate_calendar_event()

func get_weekly_event() -> Dictionary:
    var unix_now := int(Time.get_unix_time_from_system())
    var week_index := int(floor(float(unix_now) / 604800.0))
    var events: Array[Dictionary] = [
        {"name":"ТОЧНЫЙ ЗАХВАТ","desc":"Увеличенная точность клешни на этой неделе.","capture":0.08,"reward":1.10,"rare":0.02},
        {"name":"ОХОТА ЗА РЕДКИМИ","desc":"Редкие игрушки появляются заметно чаще.","capture":0.03,"reward":1.12,"rare":0.08},
        {"name":"БОЛЬШОЙ ВЫИГРЫШ","desc":"Повышенная награда за успешный захват.","capture":0.04,"reward":1.25,"rare":0.03},
        {"name":"НЕДЕЛЯ ЛЕГКИХ ИГРУШЕК","desc":"Шанс успешного захвата лёгких призов повышен.","capture":0.10,"reward":1.08,"rare":0.02}
    ]
    return events[posmod(week_index, events.size())]

func update_weekly_event() -> void:
    var ev := get_weekly_event()
    weekly_event_name = String(ev["name"])
    weekly_event_desc = String(ev["desc"])
    weekly_event_capture = float(ev["capture"])
    weekly_event_reward = float(ev["reward"])
    weekly_event_rare = float(ev["rare"])
    var now := int(Time.get_unix_time_from_system())
    weekly_event_end_unix = ((now / 604800) + 1) * 604800

func build_event_panel() -> void:
    event_panel = PanelContainer.new()
    event_panel.name = "EventPanel"
    event_panel.position = Vector2(585, 560)
    event_panel.size = Vector2(435, 300)
    event_panel.visible = false
    style_panel(event_panel, Color("#6E4B33"), Color("#A3754D"), 22, 3)
    hud_layer.add_child(event_panel)
    var v := VBoxContainer.new()
    v.name = "EventVBox"
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 8)
    event_panel.add_child(v)
    var title := Label.new()
    title.name = "EventTitle"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    v.add_child(title)
    var text := Label.new()
    text.name = "EventText"
    text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.add_theme_font_size_override("font_size", 18)
    v.add_child(text)

func update_event_panel() -> void:
    if not event_panel: return
    update_weekly_event()
    var title := event_panel.get_node("EventVBox/EventTitle") as Label
    var text := event_panel.get_node("EventVBox/EventText") as Label
    var left := maxi(0, weekly_event_end_unix - int(Time.get_unix_time_from_system()))
    title.text = "⚡ НЕДЕЛЬНОЕ СОБЫТИЕ\n%s" % weekly_event_name
    text.text = "%s\n\nДо конца недели: %02dд %02dч %02dм\n🎯 Захват: +%d%%   💰 Награда: ×%.2f\n✨ Шанс редкого приза: +%d%%" % [weekly_event_desc, int(left / 86400), int((left % 86400) / 3600), int((left % 3600) / 60), int(weekly_event_capture * 100.0), weekly_event_reward, int(weekly_event_rare * 100.0)]

func toggle_event_panel() -> void:
    if not event_panel:
        return
    if event_panel.visible:
        event_panel.visible = false
        return
    close_side_panels("EventPanel")
    event_panel.visible = true
    update_event_panel()
    animate_panel_in(event_panel)
    update_android_navigation()

func build_audio() -> void:
    # Звук движения клешни + отдельная фоновая мелодия без авторских сэмплов.
    if not sfx_move or not is_instance_valid(sfx_move):
        sfx_move = make_sfx_player("res://audio/claw_move.wav")
    if sfx_move.stream is AudioStreamWAV:
        (sfx_move.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
    music_player = make_sfx_player("res://audio/background_music.ogg")
    music_player.volume_db = music_volume_db
    music_player.finished.connect(func():
        if music_on and music_player and is_instance_valid(music_player):
            music_player.play()
    )
    apply_music_settings()

func apply_music_settings() -> void:
    if not music_player or not is_instance_valid(music_player):
        return
    music_player.volume_db = music_volume_db
    if music_on:
        if not music_player.playing:
            music_player.play()
    elif music_player.playing:
        music_player.stop()

func make_sfx_player(path: String) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.stream = load(path)
    player.volume_db = sfx_volume_db
    add_child(player)
    return player

func make_menu_circle_button(icon_text: String, tooltip_text: String, pos: Vector2, accent: Color) -> Button:
    var b := Button.new()
    b.text = icon_text
    b.position = pos
    b.size = Vector2(78, 78)
    b.tooltip_text = tooltip_text
    b.add_theme_color_override("font_color", Color.WHITE)
    b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.add_theme_color_override("font_pressed_color", Color.WHITE)
    b.add_theme_color_override("font_focus_color", Color.WHITE)
    b.add_theme_font_size_override("font_size", 30)
    b.add_theme_stylebox_override("normal", make_style(Color("#241B16"), accent, 39, 3))
    b.add_theme_stylebox_override("hover", make_style(Color("#3A2A20"), accent.lightened(0.18), 39, 4))
    b.add_theme_stylebox_override("pressed", make_style(Color("#4A3022"), Color.WHITE, 39, 4))
    b.add_theme_stylebox_override("focus", make_style(Color("#30231B"), accent, 39, 3))
    return b

func make_menu_button(text_value: String, pos: Vector2, size_value: Vector2, accent: Color = CYAN, large: bool = false) -> Button:
    var b := Button.new()
    b.text = text_value
    b.add_to_group("all_ui_text")
    b.set_meta("ru_key", text_value)
    b.position = pos
    b.size = size_value
    style_button(b, accent, large)
    return b

func build_hud() -> void:
    var top := ColorRect.new()
    top.color = Color("#211813")
    top.position = Vector2(0, 0)
    top.size = Vector2(1080, 138)
    hud_layer.add_child(top)

    # Верхний левый информационный блок: только рубли и уровень.
    var info_panel := PanelContainer.new()
    # Информационный блок компактнее и сдвинут вправо, чтобы слева было
    # отдельное крупное окно профиля.
    info_panel.position = Vector2(195, 15)
    info_panel.size = Vector2(280, 108)
    style_panel(info_panel, Color("#241B16"), Color("#76583F"), 22, 2)
    hud_layer.add_child(info_panel)

    hud_profile_button = Button.new()
    hud_profile_button.position = Vector2(15, 15)
    hud_profile_button.size = Vector2(165, 108)
    hud_profile_button.tooltip_text = "Открыть профиль игрока"
    style_button(hud_profile_button, Color("#76583F"))
    hud_profile_button.add_theme_font_size_override("font_size", 17)
    hud_profile_button.pressed.connect(func(): open_panel("profile"))
    hud_layer.add_child(hud_profile_button)
    update_hud_profile_button()

    var info_row := HBoxContainer.new()
    info_row.add_theme_constant_override("separation", 0)
    info_row.alignment = BoxContainer.ALIGNMENT_CENTER
    info_panel.add_child(info_row)

    var rubles_box := VBoxContainer.new()
    rubles_box.custom_minimum_size = Vector2(140, 0)
    rubles_box.alignment = BoxContainer.ALIGNMENT_CENTER
    info_row.add_child(rubles_box)

    var rubles_title := Label.new()
    rubles_title.text = "БАЛАНС"
    rubles_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rubles_title.add_theme_font_size_override("font_size", 12)
    rubles_title.modulate = Color("#C9B39A")
    rubles_box.add_child(rubles_title)

    coins_label = Label.new()
    coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    coins_label.add_theme_font_size_override("font_size", 22)
    coins_label.modulate = Color("#DDB47A")
    rubles_box.add_child(coins_label)

    var divider := VSeparator.new()
    divider.custom_minimum_size = Vector2(1, 72)
    info_row.add_child(divider)

    var level_box := VBoxContainer.new()
    level_box.custom_minimum_size = Vector2(140, 0)
    level_box.alignment = BoxContainer.ALIGNMENT_CENTER
    info_row.add_child(level_box)

    var level_title := Label.new()
    level_title.text = "УРОВЕНЬ"
    level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    level_title.add_theme_font_size_override("font_size", 12)
    level_title.modulate = Color("#C9B39A")
    level_box.add_child(level_title)

    level_label = Label.new()
    level_label.name = "LevelLabel"
    level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    level_label.add_theme_font_size_override("font_size", 22)
    level_label.modulate = Color("#E4C9A3")
    level_box.add_child(level_label)

    xp_bar = ProgressBar.new()
    xp_bar.name = "XPBar"
    xp_bar.custom_minimum_size = Vector2(118, 7)
    xp_bar.show_percentage = false
    xp_bar.add_theme_stylebox_override("background", make_style(Color("#120F0D"), Color("#4B392B"), 6, 1))
    xp_bar.add_theme_stylebox_override("fill", make_style(Color("#9A7653"), Color("#C09A70"), 6, 1))
    xp_bar.value = 0.0
    level_box.add_child(xp_bar)

    xp_label = Label.new()
    xp_label.name = "XPLabel"
    xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    xp_label.add_theme_font_size_override("font_size", 10)
    xp_label.modulate = Color("#E7D8C6")
    level_box.add_child(xp_label)

    var machine_panel := PanelContainer.new()
    machine_panel.position = Vector2(490, 15)
    machine_panel.size = Vector2(360, 108)
    style_panel(machine_panel, Color("#241B16"), Color("#76583F"), 22, 2)
    hud_layer.add_child(machine_panel)
    machine_status_label = Label.new()
    machine_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    machine_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    machine_status_label.add_theme_font_size_override("font_size", 15)
    machine_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    machine_status_label.add_theme_constant_override("outline_size", 4)
    machine_status_label.add_theme_color_override("font_outline_color", Color("#120E0A"))
    machine_panel.add_child(machine_status_label)

    status_label = null
    var menu := Button.new()
    menu.text = "МЕНЮ"
    menu.position = Vector2(870, 32)
    menu.size = Vector2(195, 62)
    style_button(menu, Color("#76583F"))
    menu.pressed.connect(show_main_menu)
    hud_layer.add_child(menu)

    # Виртуальный джойстик — единая панель. Кнопки являются её дочерними
    # элементами, поэтому не рисуют отдельный фон поверх джойстика.
    var pad := Panel.new()
    pad.name = "ClawJoystickPad"
    pad.position = Vector2(52, 1570)
    pad.size = Vector2(250, 250)
    style_panel(pad, Color("#241B16"), Color("#76583F"), 28, 3)
    pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(pad)

    var dirs: Array = [
        ["↑", Vector2(89, 12), 0.0, -1.0],
        ["←", Vector2(10, 92), -1.0, 0.0],
        ["→", Vector2(168, 92), 1.0, 0.0],
        ["↓", Vector2(89, 172), 0.0, 1.0]
    ]
    for d in dirs:
        var db := make_control_button(String(d[0]), Vector2.ZERO)
        db.position = d[1]
        db.size = Vector2(72, 68)
        db.add_theme_font_size_override("font_size", 28)
        var dx := float(d[2])
        var dz := float(d[3])
        db.button_down.connect(func(): joystick_hold_x = dx; joystick_hold_z = dz)
        db.button_up.connect(func():
            if is_equal_approx(joystick_hold_x, dx) and is_equal_approx(joystick_hold_z, dz):
                joystick_hold_x = 0.0
                joystick_hold_z = 0.0
        )
        pad.add_child(db)

    var pass_btn := Button.new()
    pass_btn.name = "SeasonPassHudButton"
    pass_btn.text = "🎟  СЕЗОННЫЙ\nПРОПУСК"
    pass_btn.position = Vector2(52, 1468)
    pass_btn.size = Vector2(250, 82)
    style_button(pass_btn, Color("#76583F"))
    pass_btn.add_theme_font_size_override("font_size", 16)
    pass_btn.tooltip_text = "Сезонный пропуск"
    pass_btn.pressed.connect(func(): open_panel("season_pass"))
    hud_layer.add_child(pass_btn)

    var grab := Button.new()
    grab.text = "⦿\nЗАХВАТ"
    grab.position = Vector2(700, 1580)
    grab.size = Vector2(330, 190)
    style_button(grab, Color("#8A684C"), true)
    grab.tooltip_text = "Зафиксировать позицию и опустить клешню"
    grab.button_down.connect(drop_claw)
    hud_layer.add_child(grab)


func make_control_button(text_value: String, pos: Vector2) -> Button:
    var b := Button.new()
    b.text = text_value
    b.position = pos
    b.size = Vector2(110, 88)
    style_button(b, Color("#8A684C"))
    b.add_theme_font_size_override("font_size", 32)
    return b

func build_result_popup() -> void:
    result_popup = PanelContainer.new()
    result_popup.position = Vector2(90, 520)
    result_popup.size = Vector2(900, 430)
    result_popup.visible = false
    style_panel(result_popup, Color("#A3754D"))
    hud_layer.add_child(result_popup)
    var v := VBoxContainer.new()
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 12)
    result_popup.add_child(v)
    var title := Label.new()
    title.text = "ПРИЗ ПОЛУЧЕН!"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    title.modulate = Color("#C6A27A")
    v.add_child(title)
    popup_name_label = Label.new()
    popup_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    popup_name_label.add_theme_font_size_override("font_size", 42)
    popup_name_label.modulate = Color("#F39C32")
    v.add_child(popup_name_label)
    popup_info_label = Label.new()
    popup_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    popup_info_label.add_theme_font_size_override("font_size", 19)
    popup_info_label.modulate = Color("#D8C3AA")
    v.add_child(popup_info_label)
    popup_xp_label = Label.new()
    popup_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    popup_xp_label.add_theme_font_size_override("font_size", 32)
    popup_xp_label.modulate = Color("#E1C29A")
    v.add_child(popup_xp_label)
    popup_achievement_label = Label.new()
    popup_achievement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    popup_achievement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    popup_achievement_label.add_theme_font_size_override("font_size", 17)
    popup_achievement_label.modulate = Color("#F0D4A9")
    v.add_child(popup_achievement_label)

func build_shop_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.position = Vector2(28, 135)
    p.size = Vector2(1024, 1600)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)

    var root := VBoxContainer.new()
    root.name = "VBoxContainer"
    root.add_theme_constant_override("separation", 10)
    p.add_child(root)

    var title := Label.new()
    title.text = "🛒  МАГАЗИН"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.modulate = GOLD
    root.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "КЛЕШНЯ • МОДУЛИ • СКИНЫ • АППАРАТ"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 16)
    subtitle.modulate = Color("#D7C9E8")
    root.add_child(subtitle)
    var vip_button := Button.new()
    vip_button.text = "💎  VIP МАГАЗИН — ЭКСКЛЮЗИВЫ"
    vip_button.custom_minimum_size = Vector2(0, 68)
    style_button(vip_button, Color("#C69A35"))
    vip_button.add_theme_font_size_override("font_size", 20)
    vip_button.pressed.connect(func(): shop_panel.visible = false; vip_panel.visible = true; refresh_vip_panel(); update_android_navigation())
    root.add_child(vip_button)

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 7)
    root.add_child(tabs)
    var tab_specs := [["⚙  УЛУЧШЕНИЯ", "upgrades"], ["🦾  СКИНЫ КЛЕШНИ", "claw_skins"], ["🧸  СКИНЫ ИГРУШЕК", "toy_skins"], ["🏪  СКИНЫ АППАРАТА", "machine_skins"]]
    for spec in tab_specs:
        var b := Button.new()
        b.text = String(spec[0])
        b.custom_minimum_size = Vector2(0, 62)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        style_button(b, CYAN)
        b.add_theme_font_size_override("font_size", 14)
        b.pressed.connect(func(cat: String = String(spec[1])): shop_category = cat; refresh_shop())
        tabs.add_child(b)

    var wallet := Label.new()
    wallet.name = "ShopWallet"
    wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wallet.add_theme_font_size_override("font_size", 21)
    wallet.modulate = GOLD
    root.add_child(wallet)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    shop_content = VBoxContainer.new()
    shop_content.add_theme_constant_override("separation", 9)
    shop_content.custom_minimum_size = Vector2(950, 0)
    scroll.add_child(shop_content)

    var close := Button.new()
    close.text = "←  НАЗАД"
    close.custom_minimum_size = Vector2(0, 74)
    style_button(close, CYAN)
    close.pressed.connect(func(): show_main_menu())
    root.add_child(close)
    return p

func refresh_shop() -> void:
    if not shop_content: return
    for child in shop_content.get_children(): child.queue_free()
    var wallet := shop_panel.get_node_or_null("VBoxContainer/ShopWallet")
    if wallet: wallet.text = "💰  БАЛАНС: %d ₽" % coins

    match shop_category:
        "upgrades": build_shop_upgrades()
        "claw_skins": build_shop_claw_skins()
        "toy_skins": build_shop_toy_skins()
        "machine_skins": build_shop_machine_skins()

func shop_section(title: String, desc: String) -> void:
    var h := Label.new()
    h.text = title
    h.add_theme_font_size_override("font_size", 27)
    h.modulate = GOLD
    shop_content.add_child(h)
    var d := Label.new()
    d.text = desc
    d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    d.add_theme_font_size_override("font_size", 16)
    d.modulate = Color("#D7C9E8")
    shop_content.add_child(d)

func shop_item_button(title: String, desc: String, state: String, accent: Color, action: Callable) -> void:
    var b := Button.new()
    b.text = title + "\n" + desc + "\n" + state
    b.custom_minimum_size = Vector2(0, 108)
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.alignment = HORIZONTAL_ALIGNMENT_CENTER
    style_button(b, accent)
    b.add_theme_font_size_override("font_size", 18)
    b.pressed.connect(action)
    shop_content.add_child(b)

func shop_upgrade_preview(i: int, level: int) -> String:
    if i < 0 or i >= upgrade_specs.size():
        return ""
    var bonus := float(upgrade_specs[i]["bonus"])
    if i == 4 or i == 7:
        return "Было: уровень %d • Станет: уровень %d • скорость +%.0f%% за уровень" % [level, level + 1, bonus * 100.0]
    return "Было: уровень %d • Станет: уровень %d • бонус +%.1f%%" % [level, level + 1, bonus * 100.0]

func build_shop_upgrades() -> void:
    shop_section("⚙  ИГРОВЫЕ УЛУЧШЕНИЯ", "Улучшения за рубли напрямую меняют характеристики игры: захват, точность, удачу и скорость. Мастерская на эти характеристики не влияет.")
    for i in range(upgrade_specs.size()):
        var level: int = upgrade_levels[i]
        var maxed := level >= 5
        var price := int(upgrade_specs[i]["base_price"]) * (level + 1)
        var state := "█████  МАКСИМУМ" if maxed else "УРОВЕНЬ %d / 5   •   %d ₽" % [level, price]
        var desc := "Эффект +%.1f%% за уровень" % (float(upgrade_specs[i]["bonus"]) * 100.0)
        if not maxed:
            desc += "\n" + shop_upgrade_preview(i, level)
        shop_item_button("%02d  %s" % [i + 1, String(upgrade_specs[i]["name"])], desc, state, CYAN, func(idx: int = i): buy_upgrade(idx); refresh_shop())

func build_shop_claw_skins() -> void:
    shop_section("🦾  СКИНЫ КЛЕШНИ", "Только внешний вид. Выберите стиль после покупки — клешня сразу изменит оформление.")
    for i in range(claw_skin_specs.size()):
        var owned := owned_claw_skins[i]
        var equipped := selected_claw_skin == i
        var state := "✓ УСТАНОВЛЕНО" if equipped else ("✓ КУПЛЕНО • НАЖМИТЕ, ЧТОБЫ НАДЕТЬ" if owned else "%d ₽" % int(claw_skin_specs[i]["price"]))
        var accent: Color = claw_skin_specs[i]["color"]
        shop_item_button("%02d  🦾 %s" % [i + 1, String(claw_skin_specs[i]["name"])], "Цвет клешни и металлических элементов", state, accent, func(idx: int = i): buy_claw_skin(idx); refresh_shop())

func build_shop_toy_skins() -> void:
    shop_section("🧸  СКИНЫ ИГРУШЕК", "Оформление всей партии призов. Скин применяется к игрушкам в автомате без изменения их характеристик.")
    for i in range(toy_skin_specs.size()):
        var owned := owned_toy_skins[i]
        var equipped := selected_toy_skin == i
        var state := "✓ УСТАНОВЛЕНО" if equipped else ("✓ КУПЛЕНО • НАЖМИТЕ, ЧТОБЫ НАДЕТЬ" if owned else "%d ₽" % int(toy_skin_specs[i]["price"]))
        var accent: Color = toy_skin_specs[i]["tint"]
        shop_item_button("%02d  🧸 %s" % [i + 1, String(toy_skin_specs[i]["name"])], "Стиль плюша и расцветка коллекции", state, accent, func(idx: int = i): buy_toy_skin(idx); refresh_shop())

func build_shop_machine_skins() -> void:
    shop_section("🏪  СКИНЫ АППАРАТА", "Полное оформление корпуса и подсветки. Игровая механика и физика остаются прежними.")
    for i in range(machine_skin_specs.size()):
        var owned := owned_machine_skins[i]
        var equipped := selected_machine_skin == i
        var state := "✓ УСТАНОВЛЕНО" if equipped else ("✓ КУПЛЕНО • НАЖМИТЕ, ЧТОБЫ НАДЕТЬ" if owned else "%d ₽" % int(machine_skin_specs[i]["price"]))
        var accent: Color = machine_skin_specs[i]["light"]
        shop_item_button("%02d  🏪 %s" % [i + 1, String(machine_skin_specs[i]["name"])], "Корпус + фирменная подсветка", state, accent, func(idx: int = i): buy_machine_skin(idx); refresh_shop())

func buy_cosmetic(index: int, specs: Array[Dictionary], owned: Array[bool], selected: int) -> int:
    if index < 0 or index >= specs.size(): return selected
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; update_ui(); return selected
        var item_id := "claw_skin_%d" % index if specs == claw_skin_specs else ("toy_skin_%d" % index if specs == toy_skin_specs else "machine_skin_%d" % index)
        # Уже купленный скин можно установить сразу, не дожидаясь ответа HTTP.
        # Сервер всё равно подтверждает выбор и сохраняет его.
        # Применяем внешний вид сразу, не ожидая HTTP. Если сервер отклонит
        # покупку, его game_state ниже восстановит прежний выбор.
        var can_preview := owned[index] or coins >= int(specs[index]["price"])
        if can_preview:
            selected = index
            if specs == claw_skin_specs:
                selected_claw_skin = index
            elif specs == toy_skin_specs:
                selected_toy_skin = index
            else:
                selected_machine_skin = index
            apply_shop_visuals()
            if specs == toy_skin_specs:
                build_prizes()
            refresh_shop()
            current_result = "УСТАНОВЛЕН СКИН: %s" % String(specs[index].get("name", "ГОТОВО"))
            update_ui()
        if not _start_fast_cosmetic_server_request(item_id):
            current_result = "СЕРВЕР ЗАНЯТ — НЕ УДАЛОСЬ ОТПРАВИТЬ СКИН"
            update_ui()
        return selected
    if owned[index]:
        selected = index
    elif coins >= int(specs[index]["price"]):
        coins -= int(specs[index]["price"])
        owned[index] = true
        selected = index
        save_game()
    else:
        current_result = "НЕДОСТАТОЧНО РУБЛЕЙ"
        update_ui()
        return selected
    save_game()
    apply_shop_visuals()
    update_ui()
    return selected

func buy_claw_skin(index: int) -> void:
    selected_claw_skin = buy_cosmetic(index, claw_skin_specs, owned_claw_skins, selected_claw_skin)
func buy_toy_skin(index: int) -> void:
    selected_toy_skin = buy_cosmetic(index, toy_skin_specs, owned_toy_skins, selected_toy_skin)
    build_prizes()
func buy_machine_skin(index: int) -> void:
    selected_machine_skin = buy_cosmetic(index, machine_skin_specs, owned_machine_skins, selected_machine_skin)

func _recolor_mesh_tree(root: Node, color: Color, skip_names: Array[String] = []) -> void:
    if not root or not is_instance_valid(root):
        return
    if root is MeshInstance3D:
        var mesh_node := root as MeshInstance3D
        if String(mesh_node.name) not in skip_names:
            var material := mesh_node.material_override
            if material is StandardMaterial3D:
                (material as StandardMaterial3D).albedo_color = color
            elif material is ShaderMaterial:
                var shader_mat := material as ShaderMaterial
                # Плюшевая игрушка использует ShaderMaterial, поэтому изменение
                # только albedo_color раньше вообще не влияло на её внешний вид.
                if shader_mat.get_shader_parameter("base_color") != null:
                    shader_mat.set_shader_parameter("base_color", color)
    for child in root.get_children():
        _recolor_mesh_tree(child, color, skip_names)

func _apply_toy_skin_style(root: Node, style_index: int) -> void:
    if not root or not is_instance_valid(root): return
    if root is MeshInstance3D and root.material_override is ShaderMaterial:
        var sm := root.material_override as ShaderMaterial
        sm.set_shader_parameter("skin_style", float(style_index))
    for child in root.get_children():
        _apply_toy_skin_style(child, style_index)

func apply_shop_visuals() -> void:
    var current_machine: Node3D = get_node_or_null("PremiumClawMachine") as Node3D
    if claw and selected_claw_skin >= 0 and selected_claw_skin < claw_skin_specs.size():
        _recolor_mesh_tree(claw, claw_skin_specs[selected_claw_skin]["color"], ["MotorHousing"])

    if current_machine and selected_machine_skin >= 0 and selected_machine_skin < machine_skin_specs.size():
        var ms: Dictionary = machine_skin_specs[selected_machine_skin]
        _recolor_mesh_tree(current_machine, ms["frame"], ["FrontGlass", "BackGlass", "LeftGlass", "RightGlass", "PrizeHole", "PrizeHoleDepth", "PrizeHoleFrame", "PrizeHoleTrim"])
        for light in machine_lights:
            if light: light.light_color = ms["light"]

    # Скин игрушек должен менять и уже созданные игрушки. У плюша материал
    # является ShaderMaterial, поэтому цвет задаётся через base_color.
    if selected_toy_skin >= 0 and selected_toy_skin < toy_skin_specs.size():
        var tint: Color = toy_skin_specs[selected_toy_skin]["tint"]
        for body in prize_bodies:
            if body and is_instance_valid(body):
                _recolor_mesh_tree(body, tint)
                _apply_toy_skin_style(body, selected_toy_skin)

func build_vip_panel() -> PanelContainer:
    var p := PanelContainer.new(); p.position = Vector2(35, 145); p.size = Vector2(1010, 1580); p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3); menu_layer.add_child(p)
    var scroll := ScrollContainer.new(); p.add_child(scroll)
    var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 12); v.custom_minimum_size = Vector2(930, 0); scroll.add_child(v)
    var title := Label.new(); title.text = "💎  VIP МАГАЗИН"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 40); title.modulate = Color("#FFE58A"); v.add_child(title)
    var sub := Label.new(); sub.text = "Эксклюзивные предметы и постоянные бонусы"; sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sub.add_theme_font_size_override("font_size", 19); v.add_child(sub)
    var wallet := Label.new(); wallet.name = "VIPWallet"; wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; wallet.add_theme_font_size_override("font_size", 22); wallet.modulate = GOLD; v.add_child(wallet)
    var list := VBoxContainer.new(); list.name = "VIPList"; list.add_theme_constant_override("separation", 9); v.add_child(list)
    var close := Button.new(); close.text = "←  В МАГАЗИН"; close.custom_minimum_size = Vector2(0, 80); style_button(close, CYAN); close.pressed.connect(func(): vip_panel.visible = false; shop_panel.visible = true; refresh_shop(); update_android_navigation()); v.add_child(close)
    refresh_vip_panel(); return p

func refresh_vip_panel() -> void:
    if not vip_panel: return
    var wallet := vip_panel.get_node_or_null("ScrollContainer/VBoxContainer/VIPWallet") as Label
    if wallet: wallet.text = "💰 БАЛАНС: %d ₽" % coins
    var list := vip_panel.get_node_or_null("ScrollContainer/VBoxContainer/VIPList") as VBoxContainer
    if not list: return
    for c in list.get_children(): c.queue_free()
    for i in range(vip_specs.size()):
        var item := vip_specs[i]
        var owned := i < vip_owned.size() and vip_owned[i]
        var b := Button.new(); b.custom_minimum_size = Vector2(0, 105); b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.text = ("✓  " if owned else "💎  ") + String(item["name"]) + "\n" + String(item["desc"]) + "\n" + ("ПОЛУЧЕНО" if owned else "%d ₽" % int(item["price"]))
        style_button(b, Color("#C69A35")); b.add_theme_font_size_override("font_size", 18); b.pressed.connect(func(idx: int = i): buy_vip(idx)); list.add_child(b)

func buy_vip(index: int) -> void:
    if index < 0 or index >= vip_specs.size(): return
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "": current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; update_ui(); return
        _server_action("vip_buy", {"index":index}); return
    if index >= vip_owned.size(): vip_owned.resize(vip_specs.size())
    if vip_owned[index]:
        vip_selected = index; current_result = "💎 VIP: %s" % String(vip_specs[index]["name"])
    elif coins >= int(vip_specs[index]["price"]):
        coins -= int(vip_specs[index]["price"]); vip_owned[index] = true; vip_selected = index
        var item: Dictionary = vip_specs[index]
        if item.has("skin"): selected_claw_skin = clampi(int(item["skin"]), 0, claw_skin_specs.size()-1); owned_claw_skins[selected_claw_skin] = true
        if item.has("machine"): selected_machine_skin = clampi(int(item["machine"]), 0, machine_skin_specs.size()-1); owned_machine_skins[selected_machine_skin] = true
        if item.has("toy"): selected_toy_skin = clampi(int(item["toy"]), 0, toy_skin_specs.size()-1); owned_toy_skins[selected_toy_skin] = true
        apply_shop_visuals(); build_prizes(); current_result = "💎 VIP ПРЕДМЕТ ПОЛУЧЕН"
    else: current_result = "НЕДОСТАТОЧНО РУБЛЕЙ"
    save_game(); update_ui(); refresh_vip_panel()

func get_current_season() -> Dictionary:
    var month := int(Time.get_datetime_dict_from_system().get("month", 1))
    for season in season_specs:
        if month in season["months"]: return season
    return season_specs[0]

func get_current_season_icon() -> String:
    var season := get_current_season()
    match String(season.get("id", "autumn")):
        "winter": return "❄️"
        "spring": return "🌸"
        "summer": return "☀️"
        "autumn": return "🍂"
    return "🌎"

func get_current_season_short_name() -> String:
    var season := get_current_season()
    match String(season.get("id", "autumn")):
        "winter": return "ЗИМА"
        "spring": return "ВЕСНА"
        "summer": return "ЛЕТО"
        "autumn": return "ОСЕНЬ"
    return "СЕЗОН"

func build_seasons_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.name = "SeasonsPanel"
    p.position = Vector2(35, 130)
    p.size = Vector2(1010, 1600)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)

    var scroll := ScrollContainer.new()
    scroll.name = "SeasonsScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.add_theme_constant_override("scroll_bar_width", 12)
    p.add_child(scroll)

    var v := VBoxContainer.new()
    v.name = "SeasonsContent"
    v.add_theme_constant_override("separation", 14)
    v.custom_minimum_size = Vector2(930, 0)
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(v)

    var title := Label.new()
    title.name = "SeasonsTitle"
    title.text = "🌎  СЕЗОНЫ И ПРАЗДНИКИ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.add_theme_font_size_override("font_size", 30)
    title.modulate = GOLD
    v.add_child(title)

    var current := Label.new()
    current.name = "CurrentSeason"
    current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    current.add_theme_font_size_override("font_size", 22)
    current.modulate = Color("#F0E1CE")
    v.add_child(current)

    var bonus := Label.new()
    bonus.name = "SeasonBonuses"
    bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bonus.add_theme_font_size_override("font_size", 19)
    bonus.modulate = Color("#E1C29A")
    v.add_child(bonus)

    var holiday_header := Label.new()
    holiday_header.name = "HolidayHeader"
    holiday_header.text = "🎉  ПРАЗДНИКИ ТЕКУЩЕГО СЕЗОНА"
    holiday_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    holiday_header.add_theme_font_size_override("font_size", 23)
    holiday_header.modulate = GOLD
    v.add_child(holiday_header)

    var list := VBoxContainer.new()
    list.name = "HolidayList"
    list.add_theme_constant_override("separation", 8)
    v.add_child(list)

    var all_header := Label.new()
    all_header.name = "AllSeasonsHeader"
    all_header.text = "🗓  КАЛЕНДАРЬ СЕЗОНОВ"
    all_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    all_header.add_theme_font_size_override("font_size", 23)
    all_header.modulate = GOLD
    v.add_child(all_header)

    var seasons_list := VBoxContainer.new()
    seasons_list.name = "AllSeasonsList"
    seasons_list.add_theme_constant_override("separation", 8)
    v.add_child(seasons_list)

    var upcoming_header := Label.new()
    upcoming_header.name = "UpcomingHeader"
    upcoming_header.text = "📅  БЛИЖАЙШИЕ ПРАЗДНИКИ"
    upcoming_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    upcoming_header.add_theme_font_size_override("font_size", 23)
    upcoming_header.modulate = GOLD
    v.add_child(upcoming_header)

    var upcoming_list := VBoxContainer.new()
    upcoming_list.name = "UpcomingList"
    upcoming_list.add_theme_constant_override("separation", 7)
    v.add_child(upcoming_list)

    var note := Label.new()
    note.name = "SeasonsNote"
    note.text = "Сезонные бонусы действуют постоянно в течение сезона. Праздничные бонусы включаются в соответствующие даты. Недельные события находятся отдельно справа на игровом экране."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 15)
    note.modulate = Color("#C9D9D0")
    v.add_child(note)

    var close := Button.new()
    close.name = "CloseSeasons"
    close.text = "✕  ЗАКРЫТЬ"
    close.custom_minimum_size = Vector2(0, 80)
    style_button(close, CYAN)
    close.pressed.connect(close_gameplay_overlay)
    v.add_child(close)

    refresh_seasons_panel()
    return p

func refresh_seasons_panel() -> void:
    if not seasons_panel:
        return

    var season := get_current_season()
    active_season_id = String(season.get("id", ""))
    var today_event := get_today_event()
    var profile := get_event_profile(today_event)

    var current := seasons_panel.get_node_or_null("SeasonsScroll/SeasonsContent/CurrentSeason") as Label
    if current:
        var event_type := "ПРАЗДНИК СЕГОДНЯ" if bool(today_event.get("holiday", false)) else "ТЕКУЩИЙ СЕЗОН"
        current.text = "%s\n%s\n%s" % [event_type, String(profile.get("title", season.get("name", "Сезон"))), String(season.get("theme", ""))]

    var bonus := seasons_panel.get_node_or_null("SeasonsScroll/SeasonsContent/SeasonBonuses") as Label
    if bonus:
        bonus.text = "⚡ БУСТЫ И БОНУСЫ\n🎯 Захват: +%d%%    💰 Награда: ×%.2f    ✨ Редкий приз: +%d%%\n🧸 Доп. шанс тематической игрушки: +%d%%" % [
            int(float(profile.get("capture", 0.0)) * 100.0),
            float(profile.get("reward", 1.0)),
            int(float(profile.get("rare", 0.0)) * 100.0),
            int(float(profile.get("toy", 0.0)) * 100.0)
        ]

    var list := seasons_panel.get_node_or_null("SeasonsScroll/SeasonsContent/HolidayList") as VBoxContainer
    if list:
        for c in list.get_children():
            c.queue_free()
        var found := 0
        for h in holiday_calendar:
            if String(h.get("season", "")) == active_season_id:
                var b := Label.new()
                b.text = "📌  %s  —  %s" % [String(h.get("date", "")), String(h.get("name", "Праздник"))]
                b.add_theme_font_size_override("font_size", 18)
                b.modulate = Color("#F0E1CE")
                list.add_child(b)
                found += 1
        if found == 0:
            var empty := Label.new()
            empty.text = "В этом сезоне пока нет праздничных событий."
            empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            empty.add_theme_font_size_override("font_size", 18)
            list.add_child(empty)

    var seasons_list := seasons_panel.get_node_or_null("SeasonsScroll/SeasonsContent/AllSeasonsList") as VBoxContainer
    if seasons_list:
        for c in seasons_list.get_children():
            c.queue_free()
        for s in season_specs:
            var sid := String(s.get("id", ""))
            var marker := "▶  " if sid == active_season_id else ""
            var item := Label.new()
            item.text = "%s%s\n   %s" % [marker, String(s.get("name", "Сезон")), String(s.get("theme", ""))]
            item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            item.add_theme_font_size_override("font_size", 18)
            item.modulate = GOLD if sid == active_season_id else Color("#E0D4C6")
            seasons_list.add_child(item)

    var upcoming_list := seasons_panel.get_node_or_null("SeasonsScroll/SeasonsContent/UpcomingList") as VBoxContainer
    if upcoming_list:
        for c in upcoming_list.get_children():
            c.queue_free()
        var now_day := int(floor(Time.get_unix_time_from_system() / 86400.0))
        var upcoming: Array[Dictionary] = []
        var dt := Time.get_datetime_dict_from_system()
        var current_year := int(dt.get("year", 2026))
        for h in holiday_calendar:
            var parts := String(h.get("date", "01-01")).split("-")
            if parts.size() != 2:
                continue
            var month := int(parts[0])
            var day := int(parts[1])
            var candidate := Time.get_unix_time_from_datetime_dict({"year":current_year,"month":month,"day":day,"hour":0,"minute":0,"second":0})
            if candidate < Time.get_unix_time_from_system() - 43200:
                candidate = Time.get_unix_time_from_datetime_dict({"year":current_year + 1,"month":month,"day":day,"hour":0,"minute":0,"second":0})
            var copy := h.duplicate()
            copy["unix"] = int(candidate)
            copy["days"] = maxi(0, int(floor((float(candidate) - Time.get_unix_time_from_system()) / 86400.0)))
            upcoming.append(copy)
        upcoming.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("unix", 0)) < int(b.get("unix", 0)))
        var limit := mini(8, upcoming.size())
        for i in range(limit):
            var h: Dictionary = upcoming[i]
            var item := Label.new()
            item.text = "📅 %s  —  %s\n   Через %d дн. • %s" % [String(h.get("date", "")), String(h.get("name", "Праздник")), int(h.get("days", 0)), String(h.get("season", "")).to_upper()]
            item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            item.add_theme_font_size_override("font_size", 17)
            item.modulate = Color("#E0D4C6")
            upcoming_list.add_child(item)

    save_game()

func chest_rarity_for_win(rarity: String) -> String:
    var r := randf()
    var rare_boost := active_event_rare_bonus
    if rarity == "ЛЕГЕНДАРНАЯ" and r < 0.35 + rare_boost * 0.35: return "vip"
    if rarity == "ЭПИЧЕСКАЯ" and r < 0.18 + rare_boost * 0.25: return "legendary"
    if r < 0.04 + rare_boost * 0.12: return "epic"
    if r < 0.22 + rare_boost * 0.20: return "rare"
    return "common"

func award_chest_for_win(rarity: String) -> void:
    var key := chest_rarity_for_win(rarity)
    chest_inventory[key] = int(chest_inventory.get(key, 0)) + 1
    var workshop_key_chance: float = 0.12 + float(workshop_precision + workshop_cable + workshop_calibration) * 0.008 + workshop_blueprint_bonus("precision") * 0.35
    if randf() < clampf(workshop_key_chance, 0.12, 0.32):
        chest_keys += 1
        total_keys_earned += 1

func open_chest(kind: String) -> void:
    if chest_opening: return
    if _server_ready() and player_token != "":
        if _server_action("chest_open", {"kind":kind}):
            chest_opening = true
            chest_last_reward = "🔒 СУНДУК ОТКРЫВАЕТСЯ НА СЕРВЕРЕ…"
            refresh_chests_panel()
            get_tree().create_timer(0.8).timeout.connect(func():
                chest_opening = false
                refresh_chests_panel()
                update_ui())
            return
    var amount := int(chest_inventory.get(kind, 0))
    var key_cost := int(chest_key_costs.get(kind, 1))
    if amount <= 0:
        current_result = "НЕТ ТАКИХ СУНДУКОВ"
        refresh_chests_panel()
        return
    if chest_keys < key_cost:
        current_result = "НУЖНО КЛЮЧЕЙ: %d" % key_cost
        refresh_chests_panel()
        return

    chest_opening = true
    chest_last_reward = "🔒 СУНДУК ЗАКРЫТ..."
    refresh_chests_panel()
    var panel := chests_panel.get_node_or_null("VBoxContainer/ChestReveal") as Label
    if panel:
        panel.text = chest_last_reward
        panel.visible = true

    # Сначала тратим сундук и ключи, затем проигрываем короткую анимацию.
    chest_inventory[kind] = amount - 1
    chest_keys -= key_cost
    total_chests_opened += 1
    save_game()
    await get_tree().create_timer(0.35).timeout
    if not is_instance_valid(chests_panel):
        chest_opening = false
        return

    if panel:
        panel.text = "🔑 КЛЮЧ ПОВОРАЧИВАЕТСЯ..."
    await get_tree().create_timer(0.35).timeout
    if panel: panel.text = "🎁 СУНДУК ОТКРЫВАЕТСЯ..."
    await get_tree().create_timer(0.45).timeout

    var guaranteed: Dictionary = chest_guaranteed_reward(kind)
    coins += int(guaranteed.get("coins", 0))
    var guaranteed_parts := int(guaranteed.get("parts", 0))
    guaranteed_parts += int(floor(float(workshop_claw_power + workshop_motor + workshop_cooling) * 0.10))
    guaranteed_parts += int(floor(float(workshop_calibration) * 0.50))
    guaranteed_parts = int(ceil(float(guaranteed_parts) * (1.0 + workshop_blueprint_bonus("grip"))))
    workshop_parts += guaranteed_parts
    var guaranteed_keys := int(guaranteed.get("keys", 0))
    chest_keys += guaranteed_keys
    total_keys_earned += guaranteed_keys
    var reward_text := String(guaranteed.get("n", "НАГРАДА"))

    # Дополнительная случайная награда. На праздничных событиях шанс выше.
    var bonus_chance := chest_bonus_chance(kind) + float(workshop_luck) * 0.008 + workshop_blueprint_bonus("luck") * 0.50
    if randf() < bonus_chance:
        var bonus := chest_bonus_reward(kind)
        coins += int(bonus.get("coins", 0))
        workshop_parts += int(bonus.get("parts", 0))
        var bonus_keys := int(bonus.get("keys", 0))
        chest_keys += bonus_keys
        total_keys_earned += bonus_keys
        reward_text += " + " + String(bonus.get("n", "БОНУС"))

    # Редкая эксклюзивная награда: предмет не продаётся в обычном магазине.
    if randf() < chest_exclusive_chance(kind):
        var exclusive := grant_chest_exclusive(kind)
        reward_text += "  •  " + String(exclusive)

    chest_last_reward = "🔓 СУНДУК ОТКРЫТ!\nГарантировано: %s" % reward_text
    current_result = "🎁 %s: %s" % [kind.to_upper(), reward_text]
    chest_opening = false
    save_game()
    update_ui()
    refresh_chests_panel()

func chest_guaranteed_reward(kind: String) -> Dictionary:
    match kind:
        "common": return {"n":"+25 ₽ и +2 детали","coins":25,"parts":2}
        "rare": return {"n":"+100 ₽ и +5 деталей","coins":100,"parts":5}
        "epic": return {"n":"+300 ₽ и +10 деталей","coins":300,"parts":10}
        "legendary": return {"n":"+700 ₽ и +20 деталей","coins":700,"parts":20}
        "vip": return {"n":"+1500 ₽ и +30 деталей","coins":1500,"parts":30}
    return {"n":"+25 ₽","coins":25}

func chest_bonus_chance(kind: String) -> float:
    var base := {"common":0.18,"rare":0.28,"epic":0.38,"legendary":0.50,"vip":0.65}
    return clampf(float(base.get(kind, 0.18)) + active_event_rare_bonus * 0.35, 0.0, 0.95)

func chest_bonus_reward(kind: String) -> Dictionary:
    match kind:
        "common": return [{"n":"+1 ключ","keys":1},{"n":"+3 детали","parts":3}][randi_range(0,1)]
        "rare": return [{"n":"+1 ключ","keys":1},{"n":"+50 ₽","coins":50}][randi_range(0,1)]
        "epic": return [{"n":"+2 ключа","keys":2},{"n":"+100 ₽","coins":100}][randi_range(0,1)]
        "legendary": return [{"n":"+3 ключа","keys":3},{"n":"+250 ₽","coins":250}][randi_range(0,1)]
        "vip": return [{"n":"+5 ключей","keys":5},{"n":"+500 ₽","coins":500}][randi_range(0,1)]
    return {}

func chest_exclusive_chance(kind: String) -> float:
    var base := {"common":0.01,"rare":0.025,"epic":0.06,"legendary":0.12,"vip":0.22}
    return clampf(float(base.get(kind, 0.01)) + active_event_rare_bonus * 0.20, 0.0, 0.40)

func grant_chest_exclusive(kind: String) -> String:
    chest_exclusive_reward_count += 1
    if randf() < 0.55:
        var skin_name := "СКИН СУНДУКА #%d" % (chest_exclusive_skins.size() + 1)
        chest_exclusive_skins[skin_name] = true
        return "✨ ЭКСКЛЮЗИВНЫЙ СКИН: %s" % skin_name
    var toy_name := "ЭКСКЛЮЗИВНАЯ ИГРУШКА СУНДУКА #%d" % (chest_exclusive_toys.size() + 1)
    chest_exclusive_toys[toy_name] = int(chest_exclusive_toys.get(toy_name, 0)) + 1
    toy_inventory_counts[toy_name] = int(toy_inventory_counts.get(toy_name, 0)) + 1
    return "🌟 ЭКСКЛЮЗИВНАЯ ИГРУШКА: %s" % toy_name

func build_chests_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.name = "ChestsPanel"
    p.position = Vector2(35, 120)
    p.size = Vector2(1010, 1640)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)

    var scroll := ScrollContainer.new()
    scroll.name = "ChestScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.add_theme_constant_override("scroll_bar_width", 12)
    p.add_child(scroll)

    var v := VBoxContainer.new()
    v.name = "ChestContent"
    v.custom_minimum_size = Vector2(930, 0)
    v.add_theme_constant_override("separation", 12)
    scroll.add_child(v)

    var title := Label.new()
    title.text = "🎁  СУНДУКИ НАГРАД"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.modulate = GOLD
    v.add_child(title)

    var info := Label.new()
    info.name = "ChestInfo"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_font_size_override("font_size", 20)
    v.add_child(info)

    var help := Label.new()
    help.name = "ChestHelp"
    help.text = "Сундуки выдаются за удачные захваты. Для открытия нужен сундук и ключи. Чем выше редкость, тем ценнее гарантированная награда и шанс на эксклюзивный приз."
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override("font_size", 17)
    help.modulate = Color("#E0D4C6")
    v.add_child(help)

    var reveal := Label.new()
    reveal.name = "ChestReveal"
    reveal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reveal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reveal.add_theme_font_size_override("font_size", 24)
    reveal.modulate = GOLD
    reveal.custom_minimum_size = Vector2(0, 90)
    v.add_child(reveal)

    for item in [["common","ОБЫЧНЫЙ","25 ₽ + 2 детали","1 ключ"],["rare","РЕДКИЙ","100 ₽ + 5 деталей","2 ключа"],["epic","ЭПИЧЕСКИЙ","300 ₽ + 10 деталей","3 ключа"],["legendary","ЛЕГЕНДАРНЫЙ","700 ₽ + 20 деталей","5 ключей"],["vip","VIP","1500 ₽ + 30 деталей","8 ключей"]]:
        var b := Button.new()
        b.name = "Chest_" + String(item[0])
        b.custom_minimum_size = Vector2(0, 125)
        b.add_theme_font_size_override("font_size", 20)
        style_button(b, Color("#8A684C"))
        b.pressed.connect(func(k: String = String(item[0])): open_chest(k))
        v.add_child(b)

    var close := Button.new()
    close.text = "✕  ЗАКРЫТЬ"
    close.custom_minimum_size = Vector2(0, 80)
    style_button(close, CYAN)
    close.pressed.connect(close_gameplay_overlay)
    v.add_child(close)
    refresh_chests_panel()
    return p

func refresh_chests_panel() -> void:
    if not chests_panel:
        return
    var info := chests_panel.get_node_or_null("ChestScroll/ChestContent/ChestInfo") as Label
    if info:
        var total := 0
        for amount in chest_inventory.values():
            total += int(amount)
        info.text = "🔑 КЛЮЧИ: %d    •    🎁 СУНДУКОВ: %d    •    ОТКРЫТО: %d\nДетали мастерской: %d    •    Эксклюзивных наград: %d" % [chest_keys, total, total_chests_opened, workshop_parts, chest_exclusive_reward_count]
    var reveal := chests_panel.get_node_or_null("ChestScroll/ChestContent/ChestReveal") as Label
    if reveal:
        reveal.text = chest_last_reward if chest_last_reward != "" else "Выберите сундук ниже. Содержимое и гарантированные награды показаны заранее."
        reveal.visible = true
    var names := {"common":"ОБЫЧНЫЙ","rare":"РЕДКИЙ","epic":"ЭПИЧЕСКИЙ","legendary":"ЛЕГЕНДАРНЫЙ","vip":"VIP"}
    var rewards := {"common":"Гарантированно: +25 ₽ и +2 детали","rare":"Гарантированно: +100 ₽ и +5 деталей","epic":"Гарантированно: +300 ₽ и +10 деталей","legendary":"Гарантированно: +700 ₽ и +20 деталей","vip":"Гарантированно: +1500 ₽ и +30 деталей"}
    for key in names.keys():
        var b := chests_panel.get_node_or_null("ChestScroll/ChestContent/Chest_" + key) as Button
        if b:
            var need := int(chest_key_costs.get(key, 1))
            var amount := int(chest_inventory.get(key, 0))
            b.text = "🎁 %s\nВ наличии: %d    •    Нужно ключей: %d\n%s\n%s" % [names[key], amount, need, rewards[key], "ОТКРЫТЬ СУНДУК" if amount > 0 and chest_keys >= need else "НЕТ ДОСТУПНОГО ОТКРЫТИЯ"]
            b.disabled = chest_opening or amount <= 0 or chest_keys < need

func workshop_upgrade(stat: String) -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; refresh_workshop_panel(); return
        if _server_action("workshop_upgrade", {"stat":stat}):
            current_result = "ОПЕРАЦИЯ ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; refresh_workshop_panel(); update_ui()
        return
    var level := int(get("workshop_" + stat))
    var max_level := 15 if stat in ["motor", "servo", "cable", "damper", "cooling", "controller"] else 10
    if level >= max_level:
        current_result = "МОДУЛЬ УЖЕ МАКСИМАЛЬНО ПРОКАЧАН"
        refresh_workshop_panel(); return
    var cost := workshop_module_cost(stat, level)
    if workshop_parts < cost:
        current_result = "НЕДОСТАТОЧНО ДЕТАЛЕЙ"
        refresh_workshop_panel(); return
    workshop_parts -= cost
    set("workshop_" + stat, level + 1)
    workshop_level = maxi(workshop_level, 1 + int(total_workshop_levels() / 3))
    current_result = "🛠 МОДУЛЬ УЛУЧШЕН: %s %d/%d" % [stat.to_upper(), level + 1, max_level]
    save_game(); update_ui(); refresh_workshop_panel()

func workshop_blueprint_bonus(stat: String) -> float:
    var tier := String(workshop_blueprints.get(stat, "none"))
    return {"none":0.0, "basic":0.05, "advanced":0.10, "elite":0.15}.get(tier, 0.0)

func workshop_module_cost(stat: String, level: int) -> int:
    var bases := {"claw_power":80,"speed":95,"precision":105,"luck":120,"motor":130,"servo":145,"cable":155,"damper":170,"cooling":185,"controller":210}
    var raw := int(bases.get(stat, 100)) + level * int(45 + level * 8)
    var service_discount := clampf(float(workshop_damper) * 0.015 + float(workshop_calibration) * 0.01, 0.0, 0.35)
    return maxi(1, int(round(float(raw) * (1.0 - service_discount))))

func total_workshop_levels() -> int:
    return workshop_claw_power + workshop_speed + workshop_precision + workshop_luck + workshop_motor + workshop_servo + workshop_cable + workshop_damper + workshop_cooling + workshop_controller

func workshop_blueprint_cost(tier: String) -> int:
    return {"basic":250, "advanced":650, "elite":1400}.get(tier, 999999)

func workshop_buy_blueprint(stat: String, tier: String) -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; refresh_workshop_panel(); return
        if _server_action("workshop_blueprint", {"stat":stat,"tier":tier}):
            current_result = "ОПЕРАЦИЯ ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; refresh_workshop_panel(); update_ui()
        return
    var order := {"none":0,"basic":1,"advanced":2,"elite":3}
    var current := String(workshop_blueprints.get(stat, "none"))
    if int(order.get(tier, 0)) <= int(order.get(current, 0)): return
    var cost := workshop_blueprint_cost(tier)
    if workshop_parts < cost:
        current_result = "НЕДОСТАТОЧНО ДЕТАЛЕЙ ДЛЯ ЧЕРТЕЖА"; refresh_workshop_panel(); return
    workshop_parts -= cost
    workshop_blueprints[stat] = tier
    workshop_level = maxi(workshop_level, 5 + int(total_workshop_levels() / 4))
    current_result = "📐 ЧЕРТЁЖ УСТАНОВЛЕН: %s — %s" % [stat.to_upper(), tier.to_upper()]
    save_game(); update_ui(); refresh_workshop_panel()

func workshop_calibrate() -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; refresh_workshop_panel(); return
        if _server_action("workshop_calibrate", {}):
            current_result = "ОПЕРАЦИЯ ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; refresh_workshop_panel(); update_ui()
        return
    var cost := 300 + workshop_calibration * 180
    if workshop_calibration >= 5:
        current_result = "КАЛИБРОВКА МАКСИМАЛЬНА"
    elif workshop_parts < cost:
        current_result = "НЕДОСТАТОЧНО ДЕТАЛЕЙ ДЛЯ КАЛИБРОВКИ"
    else:
        workshop_parts -= cost
        workshop_calibration += 1
        current_result = "🎯 КАЛИБРОВКА УРОВЕНЬ %d/5" % workshop_calibration
        save_game()
    refresh_workshop_panel()

func workshop_toggle_overclock() -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; refresh_workshop_panel(); return
        if _server_action("workshop_overclock", {}):
            current_result = "ОПЕРАЦИЯ ПРОВЕРЯЕТСЯ СЕРВЕРОМ"; refresh_workshop_panel(); update_ui()
        return
    if workshop_overclock:
        workshop_overclock = false
        workshop_overclock_games = 0
        current_result = "⚡ ОВЕРКЛОК ОТКЛЮЧЁН"
    elif workshop_level >= 10 and workshop_parts >= 100:
        workshop_parts -= 100
        workshop_overclock = true
        workshop_overclock_games = 5
        current_result = "⚡ ОВЕРКЛОК АКТИВИРОВАН НА 5 ИГР"
        save_game()
    else:
        current_result = "НУЖЕН 10 УРОВЕНЬ МАСТЕРСКОЙ И 100 ДЕТАЛЕЙ"
    refresh_workshop_panel()

func refresh_workshop_panel() -> void:
    if not workshop_panel: return
    var info := workshop_panel.get_node_or_null("ScrollContainer/VBoxContainer/WorkshopInfo") as Label
    if info:
        info.text = "Детали: %d   •   Уровень мастерской: %d   •   Всего уровней: %d\n🏭 %d/10  •  📚 %d/10  •  🔑 %d/10  •  🎁 %d/10\n⚙ Мотор %d/15  •  Сервопривод %d/15  •  Трос %d/15\n🛡 Демпфер %d/15  •  ❄ Охлаждение %d/15  •  🧠 Контроллер %d/15  •  🎯 Калибровка %d/5" % [workshop_parts, workshop_level, total_workshop_levels(), workshop_claw_power, workshop_speed, workshop_precision, workshop_luck, workshop_motor, workshop_servo, workshop_cable, workshop_damper, workshop_cooling, workshop_controller, workshop_calibration]
    var list := workshop_panel.get_node_or_null("ScrollContainer/VBoxContainer/WorkshopList") as VBoxContainer
    if not list: return
    for c in list.get_children(): c.queue_free()

    var specs := [["claw_power","🏭 ЦЕХ ДЕТАЛЕЙ"],["speed","📚 ОБУЧЕНИЕ ОПЕРАТОРА"],["precision","🔑 СИСТЕМА СНАБЖЕНИЯ"],["luck","🎁 УПАКОВКА НАГРАД"],["motor","⚙️ ЛОГИСТИЧЕСКИЙ МОДУЛЬ"],["servo","🧠 АНАЛИТИКА ОПЕРАЦИЙ"],["cable","🔐 БЕЗОПАСНОСТЬ СНАБЖЕНИЯ"],["damper","🛡 ТЕХОБСЛУЖИВАНИЕ"],["cooling","❄ ЭНЕРГОСБЕРЕЖЕНИЕ"],["controller","🤖 АВТОМАТИКА МАСТЕРСКОЙ"]]
    for spec in specs:
        var stat := String(spec[0])
        var level := int(get("workshop_" + stat))
        var max_level := 15 if stat in ["motor", "servo", "cable", "damper", "cooling", "controller"] else 10
        var cost := workshop_module_cost(stat, level)
        var row := PanelContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        style_panel(row, Color("#241B16"), Color("#76583F"), 18, 2)
        row.custom_minimum_size = Vector2(0, 112)
        var hb := HBoxContainer.new()
        hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hb.add_theme_constant_override("separation", 8)
        row.add_child(hb)

        var text_box := VBoxContainer.new()
        text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text_box.size_flags_stretch_ratio = 1.0
        hb.add_child(text_box)
        var name_label := Label.new()
        name_label.text = String(spec[1])
        name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        name_label.add_theme_font_size_override("font_size", 19)
        name_label.modulate = Color("#F0E1CE")
        text_box.add_child(name_label)
        var desc := Label.new()
        desc.text = "Уровень %d/%d\n%s" % [level, max_level, workshop_module_effect_text(stat, level)]
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.add_theme_font_size_override("font_size", 15)
        desc.modulate = Color("#CDBBA7")
        text_box.add_child(desc)
        var module_bar := ProgressBar.new()
        module_bar.custom_minimum_size = Vector2(0, 10)
        module_bar.show_percentage = false
        module_bar.max_value = max_level
        module_bar.value = level
        module_bar.add_theme_stylebox_override("background", make_style(Color("#17120F"), Color("#4B392B"), 5, 1))
        module_bar.add_theme_stylebox_override("fill", make_style(Color("#9A7653"), Color("#C09A70"), 5, 1))
        text_box.add_child(module_bar)

        var upgrade := Button.new()
        upgrade.text = "УЛУЧШИТЬ\n%d 🔧" % cost
        upgrade.custom_minimum_size = Vector2(142, 82)
        upgrade.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        upgrade.add_theme_font_size_override("font_size", 17)
        style_button(upgrade, Color("#241B16"))
        upgrade.disabled = level >= max_level
        upgrade.pressed.connect(func(s: String = stat): workshop_upgrade(s))
        hb.add_child(upgrade)
        list.add_child(row)

    var bp_title := Label.new()
    bp_title.text = "📐 ЧЕРТЕЖИ МАСТЕРСКОЙ"
    bp_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bp_title.add_theme_font_size_override("font_size", 20)
    bp_title.modulate = GOLD
    list.add_child(bp_title)
    for spec in [["grip","ПРОИЗВОДСТВО ДЕТАЛЕЙ"],["speed","ОБУЧЕНИЕ"],["precision","СНАБЖЕНИЕ КЛЮЧАМИ"],["luck","НАГРАДНЫЕ КОРОБКИ"]]:
        var stat := String(spec[0])
        var tier := String(workshop_blueprints.get(stat,"none"))
        var effect := int(workshop_blueprint_bonus(stat) * 100.0)
        var b := Button.new()
        b.text = "%s\nТекущий: %s • Бонус: +%d%%\nСледующий чертёж: стоимость зависит от уровня" % [String(spec[1]), tier.to_upper(), effect]
        b.custom_minimum_size = Vector2(0, 72)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 15)
        style_button(b, Color("#241B16"))
        b.pressed.connect(func(s: String = stat): workshop_buy_next_blueprint(s))
        list.add_child(b)

    var cal := Button.new()
    cal.text = "🎯 ТОЧНАЯ КАЛИБРОВКА %d/5\nУлучшает стабильность инженерных систем • %d деталей" % [workshop_calibration, 300 + workshop_calibration * 180]
    cal.custom_minimum_size = Vector2(0, 70)
    cal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cal.add_theme_font_size_override("font_size", 15)
    style_button(cal, Color("#241B16"))
    cal.disabled = workshop_calibration >= 5
    cal.pressed.connect(workshop_calibrate)
    list.add_child(cal)

    var oc := Button.new()
    oc.text = "⚡ ОВЕРКЛОК: %s\n+15%% XP и инженерных наград на 5 игр • 100 деталей" % ("АКТИВЕН (%d игр)" % workshop_overclock_games if workshop_overclock else "ГОТОВ")
    oc.custom_minimum_size = Vector2(0, 70)
    oc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    oc.add_theme_font_size_override("font_size", 15)
    style_button(oc, Color("#241B16"))
    oc.pressed.connect(workshop_toggle_overclock)
    list.add_child(oc)

    var job := Button.new()
    job.text = "🔧 ФОНОВАЯ ИНЖЕНЕРНАЯ РАБОТА\n3 минуты • 60 деталей • награда %d деталей" % (110 + workshop_level * 8) if not workshop_job_active else "🔧 РАБОТА В ПРОЦЕССЕ • %s" % _format_countdown(maxi(0, workshop_job_end_unix - int(Time.get_unix_time_from_system())))
    job.custom_minimum_size = Vector2(0, 76)
    job.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    job.add_theme_font_size_override("font_size", 15)
    style_button(job, Color("#241B16"))
    job.disabled = workshop_job_active
    job.pressed.connect(start_workshop_job)
    list.add_child(job)

    var desc := Label.new()
    desc.text = "МАГАЗИН улучшает непосредственно клешню: силу, стабилизацию, точность, удачу и скорость. МАСТЕРСКАЯ отвечает за инженерные ресурсы, обслуживание, детали, XP, ключи и награды. Системы не дублируют друг друга."
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 14)
    desc.modulate = Color("#CDBBA7")
    list.add_child(desc)

func workshop_module_effect_text(stat: String, level: int) -> String:
    var effects := {"claw_power":"+0.1 детали из каждого открытого сундука за уровень", "speed":"+0.15 XP за выигрыш за уровень", "precision":"+0.8% шанс получить дополнительный ключ", "luck":"+0.8% шанс бонусной награды из сундука", "motor":"+0.1 детали из сундуков за уровень", "servo":"+0.15 XP за выигрыш за уровень", "cable":"+0.8% шанс дополнительного ключа", "damper":"снижает стоимость обслуживания инженерных систем", "cooling":"+0.1 детали из сундуков за уровень", "controller":"+0.15 XP за выигрыш за уровень"}
    return String(effects.get(stat, "Инженерный бонус мастерской")) + " • НЕ влияет на силу, точность, скорость или удачу клешни из магазина"

func workshop_buy_next_blueprint(stat: String) -> void:
    var order := {"none":0,"basic":1,"advanced":2,"elite":3}
    var current: String = String(workshop_blueprints.get(stat, "none"))
    var next: String = String({"none":"basic", "basic":"advanced", "advanced":"elite"}.get(current, "elite"))
    if next == "elite" and current == "elite": return
    workshop_buy_blueprint(stat, String(next))

func build_workshop_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.name = "WorkshopPanel"
    p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    p.offset_left = 18
    p.offset_top = 88
    p.offset_right = -18
    p.offset_bottom = -70
    p.visible = false
    p.z_index = 31
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)

    var scroll := ScrollContainer.new()
    scroll.name = "ScrollContainer"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 8
    scroll.offset_top = 8
    scroll.offset_right = -8
    scroll.offset_bottom = -8
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    p.add_child(scroll)

    var v := VBoxContainer.new()
    v.name = "VBoxContainer"
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    v.add_theme_constant_override("separation", 10)
    scroll.add_child(v)

    var title := Label.new()
    title.text = "🛠  МАСТЕРСКАЯ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.add_theme_font_size_override("font_size", 28)
    title.modulate = GOLD
    v.add_child(title)

    var info := Label.new()
    info.name = "WorkshopInfo"
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_font_size_override("font_size", 16)
    info.modulate = Color("#E8D8C8")
    v.add_child(info)

    var list := VBoxContainer.new()
    list.name = "WorkshopList"
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    v.add_child(list)

    var close := Button.new()
    close.text = "✕  ЗАКРЫТЬ"
    close.custom_minimum_size = Vector2(0, 64)
    close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    style_button(close, Color("#9A7653"))
    close.add_theme_font_size_override("font_size", 20)
    close.pressed.connect(close_gameplay_overlay)
    v.add_child(close)
    return p

func build_collection_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.position = Vector2(35, 150)
    p.size = Vector2(1010, 1570)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    p.add_child(scroll)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 12)
    v.custom_minimum_size = Vector2(940, 0)
    scroll.add_child(v)
    var h := Label.new()
    h.text = "КОЛЛЕКЦИИ"
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.add_theme_font_size_override("font_size", 40)
    v.add_child(h)
    var progress := Label.new()
    var complete_count: int = completed_collections.size()
    var collection_names: Array[String] = get_collection_names()
    progress.text = "КОЛЛЕКЦИИ: %d / %d    •    УРОВЕНЬ %d" % [complete_count, collection_names.size(), player_level]
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress.add_theme_font_size_override("font_size", 21)
    progress.modulate = GOLD
    v.add_child(progress)
    for cname in collection_names:
        var needed: int = 0
        var got: int = 0
        for toy in toys:
            if String(toy["collection"]) == cname:
                needed += 1
                if collection.has(String(toy["name"])): got += 1
        var card := VBoxContainer.new()
        card.add_theme_constant_override("separation", 3)
        var title := Label.new()
        var done: bool = completed_collections.has(cname)
        title.text = ("🏆 " if done else "▣ ") + cname + "   •   %d / %d" % [got, needed]
        title.add_theme_font_size_override("font_size", 25)
        title.modulate = Color("#E1C29A")
        card.add_child(title)
        var names := Label.new()
        var parts: Array[String] = []
        for toy in toys:
            if String(toy["collection"]) == cname:
                var mark: String = "✓" if collection.has(String(toy["name"])) else "○"
                parts.append(mark + " " + String(toy["name"]))
        names.text = "   •   ".join(parts)
        names.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        names.add_theme_font_size_override("font_size", 18)
        names.modulate = Color("#F0E7DC") if got == needed else Color("#9B8D80")
        card.add_child(names)
        v.add_child(card)
    var close := Button.new()
    close.text = "НАЗАД К АВТОМАТУ"
    close.custom_minimum_size = Vector2(0, 82)
    close.pressed.connect(func(): show_main_menu())
    v.add_child(close)
    return p

func build_achievements_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.position = Vector2(35, 150)
    p.size = Vector2(1010, 1570)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    p.add_child(scroll)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    v.custom_minimum_size = Vector2(940, 0)
    scroll.add_child(v)
    var h := Label.new()
    h.text = "ДОСТИЖЕНИЯ"
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.add_theme_font_size_override("font_size", 34)
    h.modulate = Color("#E1C29A")
    v.add_child(h)
    var summary := Label.new()
    summary.name = "AchievementSummary"
    summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    summary.add_theme_font_size_override("font_size", 20)
    summary.modulate = Color("#D8C3AA")
    v.add_child(summary)

    # Категории: быстрый поиск нужных достижений на Android.
    var category_title := Label.new()
    category_title.text = "КАТЕГОРИИ"
    category_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    category_title.add_theme_font_size_override("font_size", 20)
    category_title.modulate = Color("#E1C29A")
    v.add_child(category_title)

    var category_scroll := ScrollContainer.new()
    category_scroll.custom_minimum_size = Vector2(0, 92)
    category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(category_scroll)

    var categories := HBoxContainer.new()
    categories.name = "AchievementCategories"
    categories.add_theme_constant_override("separation", 8)
    category_scroll.add_child(categories)

    var category_names := [
        "ВСЕ", "ИГРЫ", "ИГРУШКИ", "РЕДКОСТЬ", "КОЛЛЕКЦИИ",
        "ПРОГРЕСС", "ЭКОНОМИКА", "КЛЕШНИ", "УЛУЧШЕНИЯ",
        "СУНДУКИ", "МАСТЕРСКАЯ", "СКИНЫ", "СЕРИИ", "ОСОБЫЕ"
    ]
    for category in category_names:
        var cb := Button.new()
        cb.text = category
        cb.custom_minimum_size = Vector2(145, 70)
        cb.focus_mode = Control.FOCUS_ALL
        cb.pressed.connect(_on_achievement_category_pressed.bind(category))
        style_button(cb, Color("#8A684C"))
        cb.add_theme_font_size_override("font_size", 18)
        categories.add_child(cb)
        achievement_category_buttons.append(cb)

    var list := VBoxContainer.new()
    list.name = "AchievementList"
    list.add_theme_constant_override("separation", 7)
    v.add_child(list)
    var close := Button.new()
    close.text = "НАЗАД К МЕНЮ"
    close.custom_minimum_size = Vector2(0, 82)
    style_button(close, Color("#8A684C"))
    close.pressed.connect(func(): show_main_menu())
    v.add_child(close)
    return p

func refresh_achievements_panel() -> void:
    if not achievements_panel: return
    var root := achievements_panel.get_child(0)
    if not root: return
    var v := root.get_child(0)
    var summary: Label = v.get_node("AchievementSummary")
    var list: VBoxContainer = v.get_node("AchievementList")
    var done := unlocked_achievements.size()
    var visible_count := 0
    for spec in achievement_specs:
        if achievement_matches_category(spec, selected_achievement_category):
            visible_count += 1
    summary.text = "ОТКРЫТО: %d / %d    •    ПОКАЗАНО: %d" % [done, achievement_specs.size(), visible_count]
    for i in range(achievement_category_buttons.size()):
        var cb := achievement_category_buttons[i]
        var cat: String = str([
            "ВСЕ", "ИГРЫ", "ИГРУШКИ", "РЕДКОСТЬ", "КОЛЛЕКЦИИ",
            "ПРОГРЕСС", "ЭКОНОМИКА", "КЛЕШНИ", "УЛУЧШЕНИЯ",
            "СУНДУКИ", "МАСТЕРСКАЯ", "СКИНЫ", "СЕРИИ", "ОСОБЫЕ"
        ][i])
        if cat == selected_achievement_category:
            cb.add_theme_stylebox_override("normal", make_style(Color("#4A3022"), Color("#C19A70"), 18, 3))
        else:
            cb.add_theme_stylebox_override("normal", make_style(Color("#241B16"), Color("#6E4B33"), 18, 2))
    for child in list.get_children(): child.queue_free()
    for spec in achievement_specs:
        if not achievement_matches_category(spec, selected_achievement_category):
            continue
        var row := PanelContainer.new()
        style_panel(row, Color("#3A271D"), Color("#76583F"), 18, 2)
        row.custom_minimum_size = Vector2(0, 76)
        var label := Label.new()
        var unlocked := unlocked_achievements.has(String(spec["id"]))
        var target := int(spec.get("value", 1))
        var progress_value := mini(achievement_value(spec), target)
        label.text = ("✓  " if unlocked else "○  ") + String(spec["name"]) + "\n     " + String(spec["desc"]) + "\n     Прогресс: %d / %d" % [progress_value, target]
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_size_override("font_size", 18)
        label.modulate = Color("#E8D2B5") if unlocked else Color("#A58D76")
        row.add_child(label)
        list.add_child(row)

func _on_achievement_category_pressed(category: String) -> void:
    selected_achievement_category = category
    refresh_achievements_panel()

func achievement_matches_category(spec: Dictionary, category: String) -> bool:
    if category == "ВСЕ":
        return true
    var kind := String(spec.get("kind", ""))
    match category:
        "ИГРЫ":
            return kind == "games"
        "ИГРУШКИ":
            return kind == "toys" or kind == "heavy" or kind == "lucky"
        "РЕДКОСТЬ":
            return kind == "rarity"
        "КОЛЛЕКЦИИ":
            return kind == "collections"
        "ПРОГРЕСС":
            return kind == "level" or kind == "xp"
        "ЭКОНОМИКА":
            return kind == "rubles" or kind == "max_reward"
        "КЛЕШНИ":
            return kind == "claws" or kind == "calibration"
        "УЛУЧШЕНИЯ":
            return kind == "upgrades"
        "СУНДУКИ":
            return kind == "chests_opened" or kind == "keys_earned" or kind == "exclusive"
        "МАСТЕРСКАЯ":
            return kind == "workshop_level"
        "СКИНЫ":
            return kind == "claw_skins" or kind == "toy_skins" or kind == "machine_skins"
        "СЕРИИ":
            return kind == "best_streak" or kind == "login_streak" or kind == "daily_claims" or kind == "weekly_claims"
        "ОСОБЫЕ":
            return kind == "perfect" or kind == "referrals"
    return true

func make_data_row(parent: VBoxContainer, title_text: String, value_text: String) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    var title := Label.new()
    title.text = title_text
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 19)
    title.modulate = Color("#B9A38D")
    row.add_child(title)
    var value := Label.new()
    value.text = value_text
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    value.add_theme_font_size_override("font_size", 19)
    value.modulate = Color("#F0D4A9")
    row.add_child(value)
    parent.add_child(row)

func build_profile_panel() -> PanelContainer:
    ensure_referral_code()
    var p := PanelContainer.new()
    p.name = "ProfilePanel"
    p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    p.offset_left = 12
    p.offset_top = 125
    p.offset_right = -12
    p.offset_bottom = -18
    p.visible = false
    # Основной фон профиля — тёмный с кремовой окантовкой, как в старом оформлении.
    style_panel(p, Color("#241B16"), Color("#76583F"), 22, 3)
    hud_layer.add_child(p)

    var scroll := ScrollContainer.new()
    scroll.name = "ProfileScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 10
    scroll.offset_top = 8
    scroll.offset_right = -10
    scroll.offset_bottom = -8
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    p.add_child(scroll)

    var v := VBoxContainer.new()
    v.name = "ProfileVBox"
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    # Не даём ScrollContainer ужимать содержимое до узкой колонки на Android.
    v.custom_minimum_size = Vector2(0, 0)
    v.add_theme_constant_override("separation", 10)
    scroll.add_child(v)

    var title := Label.new()
    title.text = "👤  ПРОФИЛЬ ИГРОКА"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    title.modulate = Color("#E1C29A")
    title.custom_minimum_size = Vector2(0, 42)
    v.add_child(title)

    # Верхняя карточка игрока.
    var identity := PanelContainer.new()
    identity.name = "ProfileIdentity"
    identity.custom_minimum_size = Vector2(0, 165)
    identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    style_panel(identity, Color("#241B16"), Color("#76583F"), 18, 2)
    v.add_child(identity)

    var identity_row := HBoxContainer.new()
    identity_row.name = "IdentityRow"
    identity_row.add_theme_constant_override("separation", 14)
    identity_row.alignment = BoxContainer.ALIGNMENT_CENTER
    identity_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity_row.custom_minimum_size = Vector2(0, 145)
    identity.add_child(identity_row)

    var avatar_box := PanelContainer.new()
    avatar_box.name = "AvatarBox"
    avatar_box.custom_minimum_size = Vector2(112, 112)
    style_panel(avatar_box, Color("#17120F"), Color("#B98B5C"), 16, 2)
    identity_row.add_child(avatar_box)
    var avatar_preview := Label.new()
    avatar_preview.name = "AvatarPreview"
    avatar_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    avatar_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    avatar_preview.add_theme_font_size_override("font_size", 56)
    avatar_preview.text = AVATAR_OPTIONS[clampi(player_avatar_index, 0, AVATAR_OPTIONS.size() - 1)]
    avatar_box.add_child(avatar_preview)

    var identity_info := VBoxContainer.new()
    identity_info.name = "IdentityInfo"
    identity_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity_info.alignment = BoxContainer.ALIGNMENT_CENTER
    identity_row.add_child(identity_info)

    var name_now := Label.new()
    name_now.name = "ProfileNameLabel"
    name_now.text = player_name
    name_now.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    name_now.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    name_now.add_theme_font_size_override("font_size", 28)
    name_now.modulate = Color("#F0E1CE")
    identity_info.add_child(name_now)

    var title_now := Label.new()
    title_now.name = "ProfileTitleLabel"
    title_now.text = "ТИТУЛ • %s" % get_player_title()
    title_now.add_theme_font_size_override("font_size", 18)
    title_now.modulate = Color("#C09A70")
    identity_info.add_child(title_now)

    var level := Label.new()
    level.name = "ProfileLevelLabel"
    level.text = "УР. %d" % player_level
    level.add_theme_font_size_override("font_size", 20)
    level.modulate = Color("#E1C29A")
    identity_info.add_child(level)

    var xp := Label.new()
    xp.name = "ProfileXPLabel"
    xp.text = "%d / %d XP" % [player_xp, xp_to_next]
    xp.add_theme_font_size_override("font_size", 16)
    xp.modulate = Color("#D8C3AA")
    identity_info.add_child(xp)

    var xp_bar := ProgressBar.new()
    xp_bar.name = "ProfileXPBar"
    xp_bar.custom_minimum_size = Vector2(0, 9)
    xp_bar.show_percentage = false
    xp_bar.add_theme_stylebox_override("background", make_style(Color("#120F0D"), Color("#4B392B"), 6, 1))
    xp_bar.add_theme_stylebox_override("fill", make_style(Color("#9A7653"), Color("#C09A70"), 6, 1))
    xp_bar.max_value = maxi(1, xp_to_next)
    xp_bar.value = clampi(player_xp, 0, xp_to_next)
    identity_info.add_child(xp_bar)

    var quick := Label.new()
    quick.name = "ProfileQuickStats"
    quick.text = "💰 %d ₽   •   🎮 %d игр   •   🧸 %d призов" % [coins, total_games, total_prizes_won]
    quick.add_theme_font_size_override("font_size", 16)
    quick.modulate = Color("#D8C3AA")
    identity_info.add_child(quick)

    var id_card := PanelContainer.new()
    id_card.name = "ProfileIdCard"
    id_card.custom_minimum_size = Vector2(0, 82)
    style_panel(id_card, Color("#1A130F"), Color("#9A7653"), 16, 2)
    v.add_child(id_card)
    var id_row := HBoxContainer.new()
    id_row.name = "PlayerIdRow"
    id_row.alignment = BoxContainer.ALIGNMENT_CENTER
    id_row.add_theme_constant_override("separation", 8)
    id_card.add_child(id_row)

    var id_info := VBoxContainer.new()
    id_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    id_info.alignment = BoxContainer.ALIGNMENT_CENTER
    id_row.add_child(id_info)

    var id_caption := Label.new()
    id_caption.text = "ID ИГРОКА"
    id_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    id_caption.add_theme_font_size_override("font_size", 14)
    id_caption.modulate = Color("#C09A70")
    id_info.add_child(id_caption)

    var id_value := Label.new()
    id_value.name = "PlayerIdLabel"
    id_value.text = player_id if player_id != "" else "ПОЛУЧАЕМ…"
    id_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    id_value.add_theme_font_size_override("font_size", 21)
    id_value.modulate = Color("#F0D4A9")
    id_info.add_child(id_value)

    var copy_id := Button.new()
    copy_id.name = "CopyPlayerIdButton"
    copy_id.text = "Копировать"
    copy_id.custom_minimum_size = Vector2(118, 38)
    copy_id.add_theme_font_size_override("font_size", 13)
    style_button(copy_id, Color("#76583F"))
    copy_id.tooltip_text = "Скопировать ID игрока"
    copy_id.pressed.connect(func(): copy_profile_value(player_id, "ID игрока", copy_id))
    id_row.add_child(copy_id)

    var referral_card := PanelContainer.new()
    referral_card.name = "ProfileReferralCard"
    referral_card.custom_minimum_size = Vector2(0, 82)
    style_panel(referral_card, Color("#1A130F"), Color("#9A7653"), 16, 2)
    v.add_child(referral_card)
    var referral_row := HBoxContainer.new()
    referral_row.add_theme_constant_override("separation", 8)
    referral_row.alignment = BoxContainer.ALIGNMENT_CENTER
    referral_card.add_child(referral_row)

    var referral_info := VBoxContainer.new()
    referral_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    referral_info.alignment = BoxContainer.ALIGNMENT_CENTER
    referral_row.add_child(referral_info)
    var referral_caption := Label.new()
    referral_caption.text = "РЕФЕРАЛЬНЫЙ КОД"
    referral_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    referral_caption.add_theme_font_size_override("font_size", 14)
    referral_caption.modulate = Color("#C09A70")
    referral_info.add_child(referral_caption)
    var referral_value := Label.new()
    referral_value.name = "ReferralCodeLabel"
    referral_value.text = referral_code if referral_code != "" else "ПОЛУЧАЕМ…"
    referral_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    referral_value.add_theme_font_size_override("font_size", 21)
    referral_value.modulate = Color("#F0D4A9")
    referral_info.add_child(referral_value)

    var copy_referral := Button.new()
    copy_referral.name = "CopyReferralCodeButton"
    copy_referral.text = "Копировать"
    copy_referral.custom_minimum_size = Vector2(118, 38)
    copy_referral.add_theme_font_size_override("font_size", 13)
    style_button(copy_referral, Color("#76583F"))
    copy_referral.tooltip_text = "Скопировать реферальный код"
    copy_referral.pressed.connect(func(): copy_profile_value(referral_code, "Реферальный код", copy_referral))
    referral_row.add_child(copy_referral)

    # Редактирование профиля.
    var edit_card := PanelContainer.new()
    edit_card.name = "ProfileEditCard"
    edit_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    style_panel(edit_card, Color("#241B16"), Color("#76583F"), 18, 2)
    v.add_child(edit_card)
    var edit := VBoxContainer.new()
    edit.name = "VBoxContainer"
    edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    edit.add_theme_constant_override("separation", 7)
    edit_card.add_child(edit)

    var edit_title := Label.new()
    edit_title.text = "✏️  НАСТРОЙКА ПРОФИЛЯ"
    edit_title.add_theme_font_size_override("font_size", 20)
    edit_title.modulate = GOLD
    edit.add_child(edit_title)

    var name_caption := Label.new()
    name_caption.text = "ИМЯ ИГРОКА"
    name_caption.add_theme_font_size_override("font_size", 15)
    name_caption.modulate = Color("#C09A70")
    edit.add_child(name_caption)

    var name_input := LineEdit.new()
    name_input.name = "PlayerNameInput"
    name_input.placeholder_text = "Введите имя"
    name_input.text = player_name
    name_input.max_length = 20
    name_input.custom_minimum_size = Vector2(0, 50)
    name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_input.add_theme_font_size_override("font_size", 20)
    name_input.add_theme_stylebox_override("normal", make_style(Color("#17120F"), Color("#76583F"), 12, 2))
    name_input.add_theme_stylebox_override("focus", make_style(Color("#1F1712"), Color("#B98B5C"), 12, 2))
    edit.add_child(name_input)

    var avatar_title := Label.new()
    avatar_title.text = "ВЫБЕРИТЕ АВАТАРКУ"
    avatar_title.add_theme_font_size_override("font_size", 15)
    avatar_title.modulate = Color("#D8C3AA")
    edit.add_child(avatar_title)

    var avatars := GridContainer.new()
    avatars.name = "AvatarGrid"
    avatars.columns = 4
    avatars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    avatars.add_theme_constant_override("h_separation", 7)
    avatars.add_theme_constant_override("v_separation", 7)
    edit.add_child(avatars)
    for i in range(AVATAR_OPTIONS.size()):
        var b := Button.new()
        b.name = "Avatar_%d" % i
        b.text = AVATAR_OPTIONS[i]
        b.custom_minimum_size = Vector2(0, 58)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 30)
        b.tooltip_text = "Выбрать аватарку"
        style_button(b, Color("#B98B5C") if i == player_avatar_index else Color("#76583F"))
        b.pressed.connect(func(idx: int = i): select_profile_avatar(idx))
        avatars.add_child(b)

    var save_profile := Button.new()
    save_profile.name = "SaveProfileButton"
    save_profile.text = "💾  СОХРАНИТЬ ПРОФИЛЬ"
    save_profile.custom_minimum_size = Vector2(0, 54)
    save_profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    style_button(save_profile, Color("#9A7653"))
    save_profile.add_theme_font_size_override("font_size", 18)
    save_profile.pressed.connect(func(): save_profile_changes())
    edit.add_child(save_profile)

    var status := Label.new()
    status.name = "ProfileEditStatus"
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.add_theme_font_size_override("font_size", 14)
    status.modulate = Color("#C09A70")
    edit.add_child(status)

    # Статистика: две колонки карточек, но каждая карточка получает половину ширины.
    var stats_title := Label.new()
    stats_title.text = "📊  СТАТИСТИКА"
    stats_title.add_theme_font_size_override("font_size", 21)
    stats_title.modulate = Color("#E1C29A")
    v.add_child(stats_title)

    var data := GridContainer.new()
    data.name = "ProfileData"
    data.columns = 2
    data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    data.add_theme_constant_override("h_separation", 7)
    data.add_theme_constant_override("v_separation", 7)
    v.add_child(data)

    var close := Button.new()
    close.name = "ProfileCloseButton"
    close.text = "←  НАЗАД К ИГРЕ"
    close.custom_minimum_size = Vector2(0, 54)
    close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    style_button(close, Color("#9A7653"))
    close.add_theme_font_size_override("font_size", 18)
    close.pressed.connect(func(): close_gameplay_overlay())
    v.add_child(close)
    return p

func select_profile_avatar(index: int) -> void:
    player_avatar_index = clampi(index, 0, AVATAR_OPTIONS.size() - 1)
    if SERVER_AUTHORITATIVE and _server_ready() and player_token != "":
        _server_action("profile_update", {"avatar_index":player_avatar_index})
    refresh_profile_panel()

func save_profile_changes() -> void:
    if not profile_panel: return
    var input := profile_panel.get_node_or_null("ProfileScroll/ProfileVBox/ProfileEditCard/VBoxContainer/PlayerNameInput") as LineEdit
    if not input:
        input = profile_panel.get_node_or_null("ProfileScroll/ProfileVBox/PlayerNameInput") as LineEdit
    if input:
        var clean := input.text.strip_edges()
        if clean == "": clean = "ИГРОК"
        player_name = clean.substr(0, 20)
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "ПРОФИЛЬ НЕ СОХРАНЁН: НЕТ СЕРВЕРА"; update_ui(); return
        _server_action("profile_update", {"name":player_name,"avatar_index":player_avatar_index})
    else:
        save_game()
    update_hud_profile_button()
    refresh_profile_panel()
    current_result = "👤 ПРОФИЛЬ СОХРАНЁН"
    var status := profile_panel.get_node_or_null("ProfileScroll/ProfileVBox/ProfileEditCard/VBoxContainer/ProfileEditStatus") as Label
    if status:
        status.text = "✓ Имя и аватарка сохранены"

func copy_profile_value(value: String, title: String, button: Button = null) -> void:
    var clean := value.strip_edges()
    if clean == "" or clean == "ПОЛУЧАЕМ…":
        if button:
            button.text = "Недоступно"
            get_tree().create_timer(1.2).timeout.connect(func():
                if is_instance_valid(button): button.text = "Копировать"
            )
        return
    DisplayServer.clipboard_set(clean)
    if button:
        button.text = "✓ Скопировано"
        get_tree().create_timer(1.2).timeout.connect(func():
            if is_instance_valid(button): button.text = "Копировать"
        )
    current_result = "📋 %s скопирован в буфер обмена" % title
    update_ui()

func refresh_profile_panel() -> void:
    if not profile_panel: return
    var scroll := profile_panel.get_node_or_null("ProfileScroll") as ScrollContainer
    if not scroll: return
    var v := scroll.get_node_or_null("ProfileVBox") as VBoxContainer
    if not v: return

    var idx := clampi(player_avatar_index, 0, AVATAR_OPTIONS.size() - 1)
    # Узлы верхней карточки создаются без явных имён контейнеров, поэтому
    # используем их фактические имена Godot: HBoxContainer/PanelContainer/VBoxContainer.
    var identity := v.get_node_or_null("ProfileIdentity") as PanelContainer
    var preview: Label = null
    var identity_info: VBoxContainer = null
    if identity:
        var identity_row := identity.get_node_or_null("IdentityRow") as HBoxContainer
        if identity_row:
            preview = identity_row.get_node_or_null("AvatarBox/AvatarPreview") as Label
            identity_info = identity_row.get_node_or_null("IdentityInfo") as VBoxContainer
    if preview:
        preview.text = AVATAR_OPTIONS[idx]
    if identity_info:
        var name_label := identity_info.get_node_or_null("ProfileNameLabel") as Label
        if name_label: name_label.text = player_name
        var title_label := identity_info.get_node_or_null("ProfileTitleLabel") as Label
        if title_label: title_label.text = "ТИТУЛ • %s" % get_player_title()
        var level_label := identity_info.get_node_or_null("ProfileLevelLabel") as Label
        if level_label: level_label.text = "УР. %d" % player_level
        var xp_label := identity_info.get_node_or_null("ProfileXPLabel") as Label
        if xp_label: xp_label.text = "%d / %d XP" % [player_xp, xp_to_next]
        var xp_bar := identity_info.get_node_or_null("ProfileXPBar") as ProgressBar
        if xp_bar:
            xp_bar.max_value = maxi(1, xp_to_next)
            xp_bar.value = clampi(player_xp, 0, xp_to_next)
        var quick := identity_info.get_node_or_null("ProfileQuickStats") as Label
        if quick: quick.text = "💰 %d ₽   •   🎮 %d игр   •   🧸 %d призов" % [coins, total_games, total_prizes_won]

    var input := v.get_node_or_null("ProfileEditCard/VBoxContainer/PlayerNameInput") as LineEdit
    if input and not input.has_focus(): input.text = player_name
    var id_value := v.get_node_or_null("ProfileIdCard/VBoxContainer/PlayerIdLabel") as Label
    if id_value: id_value.text = player_id if player_id != "" else "ПОЛУЧАЕМ…"
    var referral_card := v.get_node_or_null("ProfileReferralCard") as PanelContainer
    if referral_card:
        var referral_value := referral_card.find_child("ReferralCodeLabel", true, false) as Label
        if referral_value:
            referral_value.text = referral_code if referral_code != "" else "ПОЛУЧАЕМ…"

    var grid := v.get_node_or_null("ProfileEditCard/VBoxContainer/AvatarGrid") as GridContainer
    if grid:
        for i in range(grid.get_child_count()):
            var b := grid.get_child(i) as Button
            if b:
                style_button(b, Color("#B98B5C") if i == idx else Color("#76583F"))

    var data := v.get_node_or_null("ProfileData") as GridContainer
    if not data: return
    for child in data.get_children(): child.queue_free()

    var win_rate := (float(total_prizes_won) / float(total_games) * 100.0) if total_games > 0 else 0.0
    var owned_claws_count := 0
    for owned in owned_claws:
        if owned: owned_claws_count += 1
    var total_upgrades := 0
    for u in upgrade_levels: total_upgrades += u

    var stats: Array = [
        ["Баланс", "%d ₽" % coins],
        ["Всего игр", str(total_games)],
        ["Игрушек выиграно", str(total_prizes_won)],
        ["Процент побед", "%.1f%%" % win_rate],
        ["Лучшая серия", str(best_win_streak)],
        ["Достижения", "%d / %d" % [unlocked_achievements.size(), achievement_specs.size()]],
        ["Коллекции", "%d / 8" % completed_collections.size()],
        ["Клешни", "%d / %d" % [owned_claws_count, claw_specs.size()]],
        ["Уровней улучшений", str(total_upgrades)],
        ["Текущая клешня", String(claw_specs[selected_claw]["name"])],
        ["Ключи", str(chest_keys)],
        ["Детали мастерской", str(workshop_parts)],
        ["Идеальных захватов", str(perfect_grabs)],
        ["Лучший приз", best_result],
        ["Максимальная награда", "%d ₽" % highest_reward_rubles]
    ]
    for row in stats:
        var card := PanelContainer.new()
        card.custom_minimum_size = Vector2(0, 76)
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        style_panel(card, Color("#241B16"), Color("#5E4938"), 12, 1)
        data.add_child(card)
        var row_box := HBoxContainer.new()
        row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row_box.add_theme_constant_override("separation", 6)
        card.add_child(row_box)
        var key := Label.new()
        key.text = String(row[0])
        key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        key.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        key.add_theme_font_size_override("font_size", 15)
        key.modulate = Color("#C09A70")
        row_box.add_child(key)
        var val := Label.new()
        val.text = String(row[1])
        val.custom_minimum_size = Vector2(92, 0)
        val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        val.add_theme_font_size_override("font_size", 15)
        val.modulate = Color("#E7D8C6")
        row_box.add_child(val)

func get_player_title() -> String:
    if total_prizes_won >= 500: return "ЛЕГЕНДА"
    if total_prizes_won >= 100: return "ОХОТНИК ЗА ПРИЗАМИ"
    if total_prizes_won >= 25: return "ОПЕРАТОР"
    if total_prizes_won >= 10: return "СОБИРАТЕЛЬ"
    if total_prizes_won >= 1: return "НАЧИНАЮЩИЙ"
    return "ГОСТЬ"

func build_stats_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.position = Vector2(35, 100)
    p.size = Vector2(1010, 1720)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    p.add_child(scroll)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 12)
    v.custom_minimum_size = Vector2(930, 0)
    scroll.add_child(v)
    var h := Label.new()
    h.text = "📊 РАСШИРЕННАЯ СТАТИСТИКА"
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.add_theme_font_size_override("font_size", 34)
    h.modulate = Color("#E1C29A")
    v.add_child(h)
    var list := VBoxContainer.new()
    list.name = "StatsList"
    list.add_theme_constant_override("separation", 8)
    v.add_child(list)
    var close := Button.new()
    close.text = "←  НАЗАД К МЕНЮ"
    close.custom_minimum_size = Vector2(0, 82)
    style_button(close, Color("#76583F"))
    close.pressed.connect(func(): show_main_menu())
    v.add_child(close)
    return p

func refresh_stats_panel() -> void:
    if not stats_panel: return
    var list: VBoxContainer = stats_panel.get_node("ScrollContainer/VBoxContainer/StatsList") if stats_panel.has_node("ScrollContainer/VBoxContainer/StatsList") else null
    if not list: return
    for child in list.get_children(): child.queue_free()
    var losses := maxi(0, total_games - total_prizes_won)
    var win_rate := (float(total_prizes_won) / float(total_games) * 100.0) if total_games > 0 else 0.0
    var avg_xp := (float(total_xp_earned) / float(total_prizes_won)) if total_prizes_won > 0 else 0.0
    var unique_toys := collection.size()
    var rarity_lines: Array[String] = []
    for rarity in ["ОБЫЧНАЯ", "РЕДКАЯ", "ЭПИЧЕСКАЯ", "ЛЕГЕНДАРНАЯ"]:
        rarity_lines.append("%s: %d" % [rarity, int(rarity_wins.get(rarity, 0))])
    var sections := [
        ["ИГРОВАЯ АКТИВНОСТЬ", [
            ["Всего игр", str(total_games)],
            ["Успешных захватов", str(total_prizes_won)],
            ["Неудачных попыток", str(losses)],
            ["Процент успешных захватов", "%.1f%%" % win_rate],
            ["Текущая серия побед", str(current_win_streak)],
            ["Лучшая серия побед", str(best_win_streak)]
        ]],
        ["ПРИЗЫ И НАГРАДЫ", [
            ["Уникальных игрушек", str(unique_toys)],
            ["Всего XP заработано", str(total_xp_earned)],
            ["Средний XP за игрушку", "%.1f XP" % avg_xp],
            ["Лучший приз", best_result],
            ["Максимальная награда", "%d ₽" % highest_reward_rubles],
            ["Счастливых игрушек поймано", str(lucky_toy_wins)],
            ["Тяжёлых игрушек поймано", str(heavy_toy_wins)],
            ["Идеальных захватов", str(perfect_grabs)]
        ]],
        ["ПО РЕДКОСТИ", rarity_lines.map(func(x): [x, ""])],
        ["ПРОГРЕСС", [
            ["Уровень игрока", str(player_level)],
            ["Достижения", "%d / %d" % [unlocked_achievements.size(), achievement_specs.size()]],
            ["Завершённые коллекции", "%d / 8" % completed_collections.size()],
            ["Открытые клешни", "%d / %d" % [count_owned_claws(), claw_specs.size()]],
            ["Уровни улучшений", str(total_upgrade_levels())]
        ]]
    ]
    for section in sections:
        var title := Label.new()
        title.text = String(section[0])
        title.add_theme_font_size_override("font_size", 22)
        title.modulate = Color("#E1C29A")
        list.add_child(title)
        for item in section[1]:
            var row := PanelContainer.new()
            style_panel(row, Color("#76583F"))
            row.custom_minimum_size = Vector2(0, 55)
            var label := Label.new()
            label.text = String(item[0]) + ("  •  " + String(item[1]) if String(item[1]) != "" else "")
            label.add_theme_font_size_override("font_size", 17)
            label.modulate = Color("#F0E1CE")
            row.add_child(label)
            list.add_child(row)

func count_owned_claws() -> int:
    var count := 0
    for owned in owned_claws:
        if owned: count += 1
    return count

func total_upgrade_levels() -> int:
    var count := 0
    for level in upgrade_levels: count += level
    return count


func ensure_referral_code() -> void:
    if referral_code != "":
        return
    var seed := str(Time.get_unix_time_from_system()) + str(randi())
    var hash_value := hash(seed)
    referral_code = ("CLAW%06X" % (absi(hash_value) % 16777216)).to_upper()
    save_game()

func get_referral_link() -> String:
    return "claw://invite?ref=" + referral_code

func process_incoming_referral() -> void:
    if referral_used:
        return
    var incoming := ""
    for arg in OS.get_cmdline_args():
        var text := String(arg)
        var marker := "ref="
        var pos := text.find(marker)
        if pos >= 0:
            incoming = text.substr(pos + marker.length()).split("&")[0]
            break
        if text.begins_with("claw://invite/"):
            incoming = text.trim_prefix("claw://invite/").split("?")[0]
            break
    incoming = incoming.strip_edges().to_upper()
    if incoming == "" or incoming == referral_code:
        return
    # На Android серверная привязка выполняется после загрузки конфигурации.
    # Так реферальная цепочка сохраняется между разными устройствами.
    if _server_ready():
        pending_incoming_referral = incoming
        return
    # Офлайн-режим сохраняет прежнее поведение как резервный вариант.
    referral_used = true
    coins += referral_welcome_reward
    current_result = "🎁 ПОДАРОК ЗА ПРИГЛАШЕНИЕ • +%d ₽" % referral_welcome_reward
    save_game()

func build_referral_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.position = Vector2(55, 220)
    p.size = Vector2(970, 1380)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)
    var scroll := ScrollContainer.new()
    p.add_child(scroll)
    var v := VBoxContainer.new()
    v.custom_minimum_size = Vector2(880, 0)
    v.add_theme_constant_override("separation", 16)
    scroll.add_child(v)

    var title := Label.new()
    title.text = "👥 РЕФЕРАЛЬНАЯ СИСТЕМА"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    v.add_child(title)

    var info := Label.new()
    info.text = "Приглашай друзей в Хватайку.\nДруг получает подарок за первый вход по твоей ссылке, а ты получаешь приз за каждого приглашённого друга."
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_font_size_override("font_size", 21)
    v.add_child(info)

    var code_title := Label.new()
    code_title.text = "ТВОЙ РЕФЕРАЛЬНЫЙ КОД"
    code_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    code_title.add_theme_font_size_override("font_size", 25)
    v.add_child(code_title)

    referral_link_label = Label.new()
    referral_link_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    referral_link_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    referral_link_label.add_theme_font_size_override("font_size", 22)
    referral_link_label.modulate = Color("#E1C29A")
    v.add_child(referral_link_label)

    var copy := Button.new()
    copy.text = "📋 СКОПИРОВАТЬ ССЫЛКУ"
    copy.custom_minimum_size = Vector2(0, 82)
    style_button(copy, Color("#9A7653"))
    copy.pressed.connect(func():
        DisplayServer.clipboard_set(get_referral_link())
        referral_status_label.text = "Ссылка скопирована. Отправь её другу."
    )
    v.add_child(copy)

    referral_invites_label = Label.new()
    referral_invites_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    referral_invites_label.add_theme_font_size_override("font_size", 26)
    v.add_child(referral_invites_label)

    var reward := Label.new()
    reward.text = "🎁 Приз за приглашение: +%d ₽\n🎁 Подарок новому игроку: +%d ₽" % [referral_reward_per_friend, referral_welcome_reward]
    reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reward.add_theme_font_size_override("font_size", 21)
    v.add_child(reward)

    var sep := HSeparator.new()
    v.add_child(sep)

    var enter_title := Label.new()
    enter_title.text = "ЕСТЬ КОД ДРУГА?"
    enter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    enter_title.add_theme_font_size_override("font_size", 25)
    v.add_child(enter_title)

    referral_code_input = LineEdit.new()
    referral_code_input.placeholder_text = "Введите код приглашения"
    referral_code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
    referral_code_input.custom_minimum_size = Vector2(0, 65)
    referral_code_input.add_theme_font_size_override("font_size", 22)
    v.add_child(referral_code_input)

    var claim := Button.new()
    claim.text = "🎁 ПОЛУЧИТЬ ПОДАРОК"
    claim.custom_minimum_size = Vector2(0, 82)
    style_button(claim, Color("#C09A70"))
    claim.pressed.connect(func(): claim_referral_code(referral_code_input.text))
    v.add_child(claim)

    referral_status_label = Label.new()
    referral_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    referral_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    referral_status_label.add_theme_font_size_override("font_size", 19)
    v.add_child(referral_status_label)

    var note := Label.new()
    note.text = "Рефералы учитываются на сервере. Один игрок может активировать только один код, а приглашения и награды сохраняются между устройствами."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_font_size_override("font_size", 16)
    note.modulate = Color("#B9A28D")
    v.add_child(note)

    var close := Button.new()
    close.text = "← НАЗАД"
    close.custom_minimum_size = Vector2(0, 82)
    style_button(close, Color("#76583F"))
    close.pressed.connect(func(): show_main_menu())
    v.add_child(close)
    return p

func refresh_referral_panel() -> void:
    ensure_referral_code()
    if referral_link_label:
        referral_link_label.text = referral_code + "\n" + get_referral_link()
    if referral_invites_label:
        referral_invites_label.text = "👥 ПРИШЛО ДРУЗЕЙ: %d" % referral_invites
    if referral_status_label and referral_status_label.text == "":
        referral_status_label.text = "Приглашай друзей и получай +%d ₽ за каждого." % referral_reward_per_friend

func claim_referral_code(code: String) -> void:
    if referral_used:
        referral_status_label.text = "Подарок за приглашение уже получен."
        return
    var clean := code.strip_edges().to_upper()
    if clean == "" or clean == referral_code:
        referral_status_label.text = "Введите корректный код друга."
        return
    if _server_ready():
        referral_status_label.text = "Проверяем код на сервере…"
        apply_referral_remote(clean)
        return
    if not clean.begins_with("CLAW") and not clean.begins_with("KHVA"):
        referral_status_label.text = "Код приглашения не найден."
        return
    referral_used = true
    coins += referral_welcome_reward
    referral_status_label.text = "Подарок получен: +%d ₽" % referral_welcome_reward
    current_result = "🎁 ПОДАРОК ЗА ПРИГЛАШЕНИЕ • +%d ₽" % referral_welcome_reward
    save_game()
    update_ui()

func build_settings_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.position = Vector2(55, 80)
    p.size = Vector2(970, 1100)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)

    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    p.add_child(scroll)
    var v := VBoxContainer.new()
    v.custom_minimum_size = Vector2(880, 0)
    v.add_theme_constant_override("separation", 10)
    scroll.add_child(v)

    var h := Label.new(); h.text = "⚙  НАСТРОЙКИ"; h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.add_theme_font_size_override("font_size", 38); h.modulate = Color("#E1C29A"); v.add_child(h)

    var sep1 := Label.new(); sep1.text = "ЗВУК"; sep1.add_theme_font_size_override("font_size", 22); sep1.modulate = GOLD; v.add_child(sep1)
    var music := CheckButton.new(); music.text = "Фоновая музыка"; music.button_pressed = music_on; music.add_theme_font_size_override("font_size", 21)
    music.toggled.connect(func(on: bool): music_on = on; apply_music_settings(); save_game()); v.add_child(music)
    var music_vol := HSlider.new(); music_vol.min_value = -30; music_vol.max_value = 3; music_vol.step = 1; music_vol.value = music_volume_db; music_vol.custom_minimum_size = Vector2(0, 42)
    music_vol.value_changed.connect(func(value: float): music_volume_db = value; apply_music_settings(); save_game()); v.add_child(make_labeled_control("Громкость музыки", music_vol))
    var sfx := CheckButton.new(); sfx.text = "Звуки игры и интерфейса"; sfx.button_pressed = sfx_on; sfx.add_theme_font_size_override("font_size", 21)
    sfx.toggled.connect(func(on: bool): sfx_on = on; save_game()); v.add_child(sfx)
    var volume := HSlider.new(); volume.min_value = -24; volume.max_value = 3; volume.step = 1; volume.value = sfx_volume_db; volume.custom_minimum_size = Vector2(0, 42)
    volume.value_changed.connect(func(value: float): sfx_volume_db = value; if sfx_move: sfx_move.volume_db = value; save_game()); v.add_child(make_labeled_control("Громкость эффектов", volume))

    var sep2 := Label.new(); sep2.text = "ГРАФИКА"; sep2.add_theme_font_size_override("font_size", 22); sep2.modulate = GOLD; v.add_child(sep2)
    quality_option = OptionButton.new(); ["ПЛОХО","НИЗКО","СРЕДНЕ","ВЫСОКО","УЛЬТРА"].map(func(x): quality_option.add_item(x))
    quality_option.selected = clampi(quality_level,0,4); quality_option.custom_minimum_size = Vector2(0, 54)
    quality_option.item_selected.connect(func(idx: int): quality_level = clampi(idx,0,4); apply_quality_settings(); save_game(); update_quality_info()); v.add_child(make_labeled_control("Качество", quality_option))
    var fps := OptionButton.new(); [30,60,90,120].map(func(x): fps.add_item("%d FPS" % x))
    fps.selected = 1 if fps_limit == 60 else (0 if fps_limit == 30 else (2 if fps_limit == 90 else 3)); fps.custom_minimum_size = Vector2(0,54)
    fps.item_selected.connect(func(idx:int): fps_limit = [30,60,90,120][idx]; Engine.max_fps = fps_limit; save_game()); v.add_child(make_labeled_control("Ограничение кадров", fps))
    var energy := CheckButton.new(); energy.text = "Энергосбережение"; energy.button_pressed = energy_saving_on; energy.add_theme_font_size_override("font_size",21)
    energy.toggled.connect(func(on:bool): energy_saving_on = on; Engine.max_fps = 30 if on else fps_limit; save_game()); v.add_child(energy)

    var sep3 := Label.new(); sep3.text = "УПРАВЛЕНИЕ"; sep3.add_theme_font_size_override("font_size",22); sep3.modulate = GOLD; v.add_child(sep3)
    var sens := HSlider.new(); sens.min_value=0.5; sens.max_value=1.5; sens.step=0.05; sens.value=joystick_sensitivity; sens.custom_minimum_size=Vector2(0,42)
    sens.value_changed.connect(func(x:float): joystick_sensitivity=x; save_game()); v.add_child(make_labeled_control("Чувствительность управления", sens))
    var grab := HSlider.new(); grab.min_value=0.8; grab.max_value=1.3; grab.step=0.05; grab.value=grab_button_scale; grab.custom_minimum_size=Vector2(0,42)
    grab.value_changed.connect(func(x:float): grab_button_scale=x; save_game(); apply_grab_button_scale()); v.add_child(make_labeled_control("Размер кнопки «ЗАХВАТ»", grab))
    var vibration := CheckButton.new(); vibration.text="Вибрация при захвате"; vibration.button_pressed=vibration_on; vibration.add_theme_font_size_override("font_size",21)
    vibration.toggled.connect(func(on:bool): vibration_on=on; save_game()); v.add_child(vibration)

    var sep4 := Label.new(); sep4.text="ИГРА"; sep4.add_theme_font_size_override("font_size",22); sep4.modulate=GOLD; v.add_child(sep4)
    var tips := CheckButton.new(); tips.text="Автоматические подсказки"; tips.button_pressed=auto_tips_on; tips.add_theme_font_size_override("font_size",21)
    tips.toggled.connect(func(on:bool): auto_tips_on=on; if not on and waiting_overlay: waiting_overlay.visible=false; save_game()); v.add_child(tips)
    var purchases := CheckButton.new(); purchases.text="Подтверждать покупки"; purchases.button_pressed=confirm_purchases_on; purchases.add_theme_font_size_override("font_size",21)
    purchases.toggled.connect(func(on:bool): confirm_purchases_on=on; save_game()); v.add_child(purchases)
    var rare := CheckButton.new(); rare.text="Подтверждать открытие редких сундуков"; rare.button_pressed=confirm_rare_chests_on; rare.add_theme_font_size_override("font_size",21)
    rare.toggled.connect(func(on:bool): confirm_rare_chests_on=on; save_game()); v.add_child(rare)

    var sep_notifications := Label.new(); sep_notifications.text="УВЕДОМЛЕНИЯ"; sep_notifications.add_theme_font_size_override("font_size",22); sep_notifications.modulate=GOLD; v.add_child(sep_notifications)
    var notifications := CheckButton.new(); notifications.text="Уведомления игры"; notifications.button_pressed=notifications_on; notifications.add_theme_font_size_override("font_size",21)
    notifications.toggled.connect(func(on:bool): notifications_on=on; save_game(); cancel_background_notifications(); if on: schedule_background_notifications()); v.add_child(notifications)
    var notify_items := [["notify_rewards_on","🎁 Награды"],["notify_streak_on","🔥 Серия входов"],["notify_events_on","🎪 События и сезон"],["notify_workshop_on","🔧 Мастерская"],["notify_chests_on","📦 Сундуки"]]
    for item in notify_items:
        var ncb := CheckButton.new()
        ncb.text = String(item[1])
        ncb.button_pressed = bool(get(String(item[0])))
        ncb.add_theme_font_size_override("font_size", 18)
        ncb.toggled.connect(func(on: bool, key: String=String(item[0])): set(key, on); save_game(); cancel_background_notifications(); schedule_background_notifications())
        v.add_child(ncb)
    var test_notification := Button.new(); test_notification.text="🔔  ОТПРАВИТЬ ТЕСТОВОЕ УВЕДОМЛЕНИЕ"; test_notification.custom_minimum_size=Vector2(0,64); style_button(test_notification,Color("#76583F")); test_notification.add_theme_font_size_override("font_size",18); test_notification.pressed.connect(func(): test_game_notification()); v.add_child(test_notification)


    var sep5 := Label.new(); sep5.text="ЯЗЫК"; sep5.add_theme_font_size_override("font_size",22); sep5.modulate=GOLD; v.add_child(sep5)
    language_option=OptionButton.new(); language_option.add_item("Русский"); language_option.add_item("English"); language_option.selected=0 if language=="ru" else 1; language_option.custom_minimum_size=Vector2(0,54)
    language_option.item_selected.connect(func(idx:int): language="ru" if idx==0 else "en"; apply_language(); save_game()); v.add_child(language_option)

    var info := Label.new(); info.name="SettingsInfo"; info.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.add_theme_font_size_override("font_size",18); info.modulate=Color("#D8C3AA"); v.add_child(info)
    info.text = "НАСТРОЙКИ СОХРАНЯЮТСЯ АВТОМАТИЧЕСКИ\nГрафика: %s • Лимит: %d FPS • Управление: %.2fx" % [quality_name(), fps_limit, joystick_sensitivity]
    update_quality_info()

    var reset_settings := Button.new(); reset_settings.text="ВОССТАНОВИТЬ НАСТРОЙКИ ПО УМОЛЧАНИЮ"; reset_settings.custom_minimum_size=Vector2(0,68); style_button(reset_settings,Color("#76583F")); reset_settings.add_theme_font_size_override("font_size",18); reset_settings.pressed.connect(confirm_reset_settings); v.add_child(reset_settings)
    var reset := Button.new(); reset.text="СБРОСИТЬ ПРОГРЕСС"; reset.custom_minimum_size=Vector2(0,78); style_button(reset,Color("#76583F")); reset.pressed.connect(confirm_reset_progress); v.add_child(reset)
    var close := Button.new(); close.text="←  НАЗАД"; close.custom_minimum_size=Vector2(0,78); style_button(close,Color("#9A7653")); close.pressed.connect(func(): show_main_menu()); v.add_child(close)
    return p

func make_labeled_control(title_text: String, control: Control) -> VBoxContainer:
    var box := VBoxContainer.new(); box.add_theme_constant_override("separation",3)
    var label := Label.new(); label.text=title_text; label.add_theme_font_size_override("font_size",17); label.modulate=Color("#D8C3AA"); box.add_child(label); box.add_child(control)
    return box

func apply_grab_button_scale() -> void:
    var grab := hud_layer.get_node_or_null("GrabButton")
    if grab is Control:
        grab.scale = Vector2(grab_button_scale, grab_button_scale)

func reset_settings_defaults() -> void:
    music_on = true
    sfx_on = true
    music_volume_db = -8.0
    sfx_volume_db = -4.0
    vibration_on = true
    energy_saving_on = false
    confirm_purchases_on = true
    confirm_rare_chests_on = true
    fps_limit = 60
    joystick_sensitivity = 1.0
    grab_button_scale = 1.0
    auto_tips_on = true
    notifications_on = true
    notify_rewards_on = true
    notify_streak_on = true
    notify_events_on = true
    notify_workshop_on = true
    notify_chests_on = true
    quality_level = 2
    language = "ru"
    Engine.max_fps = fps_limit
    apply_quality_settings()
    apply_grab_button_scale()
    save_game()
    current_result = "⚙ НАСТРОЙКИ ВОССТАНОВЛЕНЫ"
    update_ui()
    if settings_panel:
        settings_panel.visible = true

func confirm_reset_settings() -> void:
    var dialog := ConfirmationDialog.new()
    dialog.title = "Настройки по умолчанию"
    dialog.dialog_text = "Вернуть звук, графику и управление к исходным значениям? Прогресс игры не будет затронут."
    dialog.ok_button_text = "ВОССТАНОВИТЬ"
    dialog.cancel_button_text = "ОТМЕНА"
    menu_layer.add_child(dialog)
    dialog.confirmed.connect(func(): reset_settings_defaults(); dialog.queue_free())
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered()

func confirm_reset_progress() -> void:
    var dialog := ConfirmationDialog.new()
    dialog.title = "Сброс прогресса"
    dialog.dialog_text = "Весь прогресс, покупки и коллекция будут удалены. Продолжить?"
    dialog.ok_button_text = "СБРОСИТЬ"
    dialog.cancel_button_text = "ОТМЕНА"
    menu_layer.add_child(dialog)
    dialog.confirmed.connect(func(): reset_progress(); dialog.queue_free())
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered()

func quality_name() -> String:
    var names := ["ПЛОХО", "НИЗКО", "СРЕДНЕ", "ВЫСОКО", "УЛЬТРА"]
    return names[clampi(quality_level, 0, names.size() - 1)]

func update_quality_info() -> void:
    if not settings_panel:
        return
    var info := settings_panel.get_node_or_null("ScrollContainer/VBoxContainer/SettingsInfo") as Label
    if info:
        info.text = "Качество графики: %s\nЯзык: %s\nАвтосохранение: ВКЛ" % [quality_name(), "РУССКИЙ" if language == "ru" else "ENGLISH"]

func apply_quality_settings() -> void:
    quality_level = clampi(quality_level, 0, 4)
    if not is_inside_tree():
        return

    # MSAA — главный переключатель качества сглаживания на мобильном рендерере.
    var viewport := get_viewport()
    if viewport:
        match quality_level:
            0:
                viewport.msaa_3d = Viewport.MSAA_DISABLED
            1:
                viewport.msaa_3d = Viewport.MSAA_DISABLED
            2:
                viewport.msaa_3d = Viewport.MSAA_2X
            3, 4:
                viewport.msaa_3d = Viewport.MSAA_4X

    # Упрощаем дорогие отражения на низких пресетах, но ничего не удаляем из игры.
    if reflection_probe and is_instance_valid(reflection_probe):
        reflection_probe.visible = quality_level >= 2
        reflection_probe.intensity = 0.65 if quality_level <= 1 else (0.95 if quality_level == 2 else (1.15 if quality_level == 3 else 1.25))

    # Свет остаётся на всех уровнях; на низких пресетах уменьшается его стоимость.
    var energy_mult: float = [0.62, 0.76, 0.88, 1.0, 1.08][quality_level]
    for light in scene_lights:
        if light and is_instance_valid(light):
            light.shadow_enabled = quality_level >= 3
            if light.has_meta("quality_base_energy"):
                light.light_energy = float(light.get_meta("quality_base_energy")) * energy_mult
            else:
                light.set_meta("quality_base_energy", light.light_energy)
                light.light_energy *= energy_mult

    # На низком качестве уменьшаем только визуальную детализацию материалов/сглаживание;
    # количество игрушек, модели, механика и содержимое игры сохраняются.
    if world_environment and is_instance_valid(world_environment) and world_environment.environment:
        var env := world_environment.environment
        env.glow_enabled = quality_level >= 3
        env.ambient_light_energy = [0.82, 0.74, 0.68, 0.65, 0.62][quality_level]

func set_gameplay_3d_visible(show_game: bool) -> void:
    # Меню работает как отдельный экран: автомат не остаётся под окнами меню.
    for child in get_children():
        if child is Node3D:
            child.visible = show_game

func set_main_menu_controls(show_controls: bool) -> void:
    for control in main_menu_controls:
        if is_instance_valid(control):
            control.visible = show_controls

func get_capture_preview() -> float:
    var chosen := choose_top_layer_prize()
    if chosen < 0 or chosen >= prize_bodies.size():
        return 0.0
    var body := prize_bodies[chosen]
    var bonus: float = float(claw_specs[selected_claw]["bonus"])
    var upgrade_bonus: float = float(upgrade_levels[0] + upgrade_levels[1] + upgrade_levels[2]) * 0.028
    var base := clampf(0.28 + bonus + upgrade_bonus, 0.0, 0.95)
    var weight := float(body.get_meta("toy_weight", 38.0))
    var heavy_penalty := clampf((weight - 35.0) / 180.0, -0.08, 0.30)
    var slippery_penalty := 0.12 if bool(body.get_meta("slippery", false)) else 0.0
    var lucky_bonus := 0.10 if int(prize_data[chosen].get("index", -1)) == lucky_toy_index else 0.0
    return clampf(base - heavy_penalty - slippery_penalty + lucky_bonus, 0.08, 0.95)

func apply_language() -> void:
    if language_option:
        language_option.selected = 0 if language == "ru" else 1
    var dict := {
        "▶  ИГРАТЬ":"▶  PLAY", "🛒  МАГАЗИН":"🛒  SHOP", "★  КОЛЛЕКЦИЯ":"★  COLLECTION",
        "🏆  ДОСТИЖЕНИЯ":"🏆  ACHIEVEMENTS", "⚙  НАСТРОЙКИ":"⚙  SETTINGS", "❓  ПОМОЩЬ":"❓  HELP",
        "МЕНЮ":"MENU", "👤\nПРОФИЛЬ":"👤\nPROFILE", "БАЛАНС":"BALANCE", "УРОВЕНЬ":"LEVEL",
        "ЗВУК ДВИЖЕНИЯ КЛЕШНИ":"CLAW MOVEMENT SOUND", "Фоновая музыка":"Background music",
        "Звук движения клешни":"Claw movement sound", "ГРОМКОСТЬ ЗВУКА":"SOUND VOLUME",
        "Вибрация при нажатии «ЗАХВАТ»":"Vibration on GRAB", "Автоматические подсказки":"Automatic tips",
        "СБРОСИТЬ ПРОГРЕСС":"RESET PROGRESS", "←  НАЗАД":"←  BACK", "←  НАЗАД К МЕНЮ":"←  BACK TO MENU",
        "НАЗАД К АВТОМАТУ":"BACK TO MACHINE", "ЕЖЕДНЕВНАЯ СЕРИЯ":"DAILY STREAK",
        "ЗАБРАТЬ ПРИЗ":"CLAIM REWARD", "ПРИЗ УЖЕ ПОЛУЧЕН":"REWARD CLAIMED",
        "ПОМОЩЬ":"HELP", "КАК ИГРАТЬ?":"HOW TO PLAY?", "КОЛЛЕКЦИИ":"COLLECTIONS",
        "МАГАЗИН":"SHOP", "НАСТРОЙКИ":"SETTINGS", "ПРОФИЛЬ ИГРОКА":"PLAYER PROFILE",
        "👥  РЕФЕРАЛЬНАЯ СИСТЕМА":"👥  REFERRAL SYSTEM", "👥 РЕФЕРАЛЬНАЯ СИСТЕМА":"👥 REFERRAL SYSTEM",
        "ТВОЙ РЕФЕРАЛЬНЫЙ КОД":"YOUR REFERRAL CODE", "📋 СКОПИРОВАТЬ ССЫЛКУ":"📋 COPY INVITE LINK",
        "ЕСТЬ КОД ДРУГА?":"HAVE A FRIEND CODE?", "🎁 ПОЛУЧИТЬ ПОДАРОК":"🎁 CLAIM GIFT"
    }
    for node in get_tree().get_nodes_in_group("localized_text"):
        if node is Label or node is Button or node is CheckButton:
            var ru_text := String(node.get_meta("ru_text", node.text))
            var en_text := String(node.get_meta("en_text", dict.get(ru_text, ru_text)))
            node.text = ru_text if language == "ru" else en_text
    # Для уже созданных элементов меню используем точное соответствие текста.
    var stack: Array[Node] = [self]
    while not stack.is_empty():
        var current: Node = stack.pop_back()
        if current is Label or current is Button or current is CheckButton:
            var key := String(current.get_meta("ru_key", current.text))
            if not current.has_meta("ru_key") and dict.has(key):
                current.set_meta("ru_key", key)
            if dict.has(key): current.text = key if language == "ru" else String(dict[key])
        for child in current.get_children(): stack.append(child)

func mark_localized(control: Control, ru_text: String, en_text: String) -> void:
    control.add_to_group("localized_text")
    control.set_meta("ru_text", ru_text)
    control.set_meta("en_text", en_text)
    control.text = ru_text if language == "ru" else en_text

func build_help_panel() -> PanelContainer:
    var p := PanelContainer.new()
    p.position = Vector2(80, 300)
    p.size = Vector2(920, 900)
    p.visible = false
    style_panel(p, Color("#241B16"), Color("#76583F"), 26, 3)
    menu_layer.add_child(p)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 16)
    p.add_child(v)
    var h := Label.new()
    h.text = "❓ ПОМОЩЬ"
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.add_theme_font_size_override("font_size", 36)
    h.modulate = Color("#E1C29A")
    v.add_child(h)
    var text := Label.new()
    text.text = "КАК ИГРАТЬ?\n\n1. Перемещай клешню стрелками или джойстиком.\n2. Наведи прицел на подходящую игрушку.\n3. Следи за индикатором шанса захвата.\n4. Нажми «ЗАХВАТ» и дождись результата.\n5. Тяжёлые и скользкие игрушки сложнее удержать.\n6. Выполняй ежедневные и недельные задания.\n7. Ищи счастливую игрушку дня — она даёт x3.\n8. Следи за профилем, коллекцией и прогрессом.\n\nПодсказка: не всегда выгодно брать самую большую игрушку!"
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.add_theme_font_size_override("font_size", 21)
    text.modulate = Color("#F0E1CE")
    v.add_child(text)
    var close := Button.new()
    close.text = "←  НАЗАД"
    close.custom_minimum_size = Vector2(0, 90)
    style_button(close, Color("#9A7653"))
    close.pressed.connect(func(): show_main_menu())
    v.add_child(close)
    return p

func start_game() -> void:
    if SERVER_AUTHORITATIVE and (not _server_ready() or player_token == ""):
        current_result = "ПОДКЛЮЧЕНИЕ К СЕРВЕРУ НЕ УСТАНОВЛЕНО — ИГРА ЗАБЛОКИРОВАНА"
        update_ui()
        register_player_remote()
        return
    if online_maintenance:
        var dialog := AcceptDialog.new()
        dialog.title = "Технические работы"
        dialog.dialog_text = online_announcement if online_announcement != "" else "Игра временно недоступна. Попробуйте позже."
        menu_layer.add_child(dialog)
        dialog.popup_centered()
        return
    close_all_panels()
    register_game_activity()
    set_main_menu_controls(false)
    menu_layer.visible = false
    hud_layer.visible = true
    set_gameplay_3d_visible(true)
    current_result = "ГОТОВ К ИГРЕ"
    update_ui()

func update_hud_profile_button() -> void:
    if not hud_profile_button or not is_instance_valid(hud_profile_button):
        return
    var idx := clampi(player_avatar_index, 0, AVATAR_OPTIONS.size() - 1)
    hud_profile_button.text = "%s\n%s" % [AVATAR_OPTIONS[idx], player_name]
    hud_profile_button.tooltip_text = "Профиль: %s" % player_name

func show_main_menu() -> void:
    if not game_initialized:
        return
    close_all_panels()
    if gameplay_modal_blocker and is_instance_valid(gameplay_modal_blocker):
        gameplay_modal_blocker.visible = false
    hud_layer.visible = false
    set_gameplay_3d_visible(false)
    set_main_menu_controls(true)
    menu_layer.visible = true

func open_panel(which: String) -> void:
    if not game_initialized:
        return
    # Окна на экране аппарата работают как переключатель: открыть одно —
    # автоматически закрыть все остальные. При этом сам аппарат остаётся видимым.
    if which == "profile" or which == "seasons" or which == "chests" or which == "workshop" or which == "season_pass" or which == "return_bonus":
        close_all_panels()
        menu_layer.visible = false
        set_main_menu_controls(false)
        hud_layer.visible = true
        set_gameplay_3d_visible(true)
        if gameplay_modal_blocker and is_instance_valid(gameplay_modal_blocker):
            gameplay_modal_blocker.visible = true
        if which == "profile":
            profile_panel.visible = true
            refresh_profile_panel()
        elif which == "seasons":
            seasons_panel.visible = true
            refresh_seasons_panel()
        elif which == "chests":
            chests_panel.visible = true
            refresh_chests_panel()
        elif which == "workshop":
            workshop_panel.visible = true
            refresh_workshop_panel()
        elif which == "season_pass":
            season_pass_panel.visible = true
            refresh_season_pass_panel()
        else:
            return_bonus_panel.visible = true
            refresh_return_bonus_panel()
        for child in hud_layer.get_children():
            if child is PanelContainer and child.visible and child != gameplay_modal_blocker:
                animate_panel_in(child)
                break
        return

    # Обычные пункты меню открываются отдельным экраном, как и раньше.
    close_all_panels()
    set_gameplay_3d_visible(false)
    hud_layer.visible = false
    set_main_menu_controls(false)
    menu_layer.visible = true
    if which == "shop": shop_panel.visible = true
    elif which == "collection": collection_panel.visible = true
    elif which == "settings": settings_panel.visible = true
    elif which == "achievements":
        achievements_panel.visible = true
        refresh_achievements_panel()
    elif which == "help":
        help_panel.visible = true
    elif which == "referral":
        referral_panel.visible = true
        refresh_referral_panel()
    elif which == "promo":
        promo_panel.visible = true
        refresh_promo_panel()
    elif which == "news":
        news_panel.visible = true
        refresh_news_panel()
    elif which == "rating":
        rating_panel.visible = true
        refresh_rating_panel()
    # Все основные окна меню появляются одинаково плавно.
    for child in menu_layer.get_children():
        if child is PanelContainer and child.visible:
            animate_panel_in(child)
            break
    update_android_navigation()

func close_gameplay_overlay() -> void:
    if not game_initialized:
        return
    close_all_panels()
    if gameplay_modal_blocker and is_instance_valid(gameplay_modal_blocker):
        gameplay_modal_blocker.visible = false
    menu_layer.visible = false
    hud_layer.visible = true
    set_gameplay_3d_visible(true)
    update_android_navigation()

func close_all_panels() -> void:
    if gameplay_modal_blocker and is_instance_valid(gameplay_modal_blocker):
        gameplay_modal_blocker.visible = false
    if shop_panel: shop_panel.visible = false
    if collection_panel: collection_panel.visible = false
    if settings_panel: settings_panel.visible = false
    if achievements_panel: achievements_panel.visible = false
    if profile_panel: profile_panel.visible = false
    if help_panel: help_panel.visible = false
    if referral_panel: referral_panel.visible = false
    if vip_panel: vip_panel.visible = false
    if seasons_panel: seasons_panel.visible = false
    if chests_panel: chests_panel.visible = false
    if workshop_panel: workshop_panel.visible = false
    if season_pass_panel: season_pass_panel.visible = false
    if promo_panel: promo_panel.visible = false
    if news_panel: news_panel.visible = false
    if rating_panel: rating_panel.visible = false
    if return_bonus_panel: return_bonus_panel.visible = false
    if live_systems_panel: live_systems_panel.visible = false
    if stats_panel: stats_panel.visible = false
    if result_popup: result_popup.visible = false
    if sale_panel: sale_panel.visible = false
    if waiting_overlay: waiting_overlay.visible = false
    close_side_panels()
    update_android_navigation()

func update_ui() -> void:
    if coins_label:
        coins_label.text = "%d ₽" % coins
    if status_label:
        status_label.text = current_result
    if level_label:
        level_label.text = "УР. %d" % player_level
    if xp_label:
        xp_label.text = "ОПЫТ  %d / %d XP" % [player_xp, xp_to_next]
    if xp_bar:
        xp_bar.max_value = float(xp_to_next)
        xp_bar.value = float(player_xp)
    if machine_status_label:
        var lucky_name := String(toys[lucky_toy_index].get("name", "—")) if lucky_toy_index >= 0 and lucky_toy_index < toys.size() else "—"
        var active_note := ""
        if active_event_name != "":
            active_note = "\n⚡  %s" % active_event_name
        machine_status_label.text = "🧸  ПРИЗЫ: %d\n🍀  ИГРУШКА ДНЯ: %s ×3\n🔥  СЕРИЯ ПОБЕД: %d\n📦  ПАРТИЯ: %s%s" % [prize_bodies.size(), lucky_name, current_win_streak, batch_type, active_note]
    update_missions()
    if news_menu_button and is_instance_valid(news_menu_button):
        news_menu_button.text = "📰  НОВОСТИ  !" if news_unread > 0 else "📰  НОВОСТИ"

func _process(delta: float) -> void:
    time_alive += delta
    if music_player:
        apply_music_settings()
    if notification_permission_waiting and OS.has_feature("android") and fmod(time_alive, 1.0) < delta:
        if _android_notification_permission_granted():
            notification_permission_waiting = false
            if notification_pending_test:
                notification_pending_test = false
                _send_pending_test_notification()
    server_settings_sync_timer -= delta
    if remote_request_kind == "" and _server_ready() and player_token != "" and not remote_action_queue.is_empty():
        var queued_action: Dictionary = remote_action_queue.pop_front()
        var queued_name := String(queued_action.get("name", ""))
        var queued_payload: Variant = queued_action.get("payload", {})
        if queued_payload is Dictionary and queued_name != "":
            _server_action(queued_name, queued_payload)
    if server_settings_dirty and server_settings_sync_timer <= 0.0 and _server_ready() and player_token != "" and remote_request_kind == "":
        var settings_payload := {"music":music_on,"sfx":sfx_on,"sfx_volume_db":sfx_volume_db,"music_volume_db":music_volume_db,"vibration_on":vibration_on,"energy_saving_on":energy_saving_on,"confirm_purchases_on":confirm_purchases_on,"confirm_rare_chests_on":confirm_rare_chests_on,"fps_limit":fps_limit,"joystick_sensitivity":joystick_sensitivity,"grab_button_scale":grab_button_scale,"auto_tips_on":auto_tips_on,"notifications_on":notifications_on,"notify_rewards_on":notify_rewards_on,"notify_streak_on":notify_streak_on,"notify_events_on":notify_events_on,"notify_workshop_on":notify_workshop_on,"notify_chests_on":notify_chests_on,"quality_level":quality_level,"language":language}
        if _server_action("settings_update", {"settings":settings_payload}):
            server_settings_dirty = false
            server_settings_sync_timer = 30.0
    remote_auth_retry_timer -= delta
    if _server_ready() and player_token == "" and remote_request_kind == "":
        if remote_auth_retry_timer <= 0.0:
            remote_auth_retry_timer = 10.0
            register_player_remote()
    remote_sync_timer -= delta
    if remote_sync_timer <= 0.0 and _server_ready() and player_token != "":
        remote_sync_timer = 10.0
        sync_player_to_server()
    remote_notification_timer -= delta
    if remote_notification_timer <= 0.0 and _server_ready():
        remote_notification_timer = 30.0
        poll_server_notifications()
    if rarity_flash_timer > 0.0:
        rarity_flash_timer -= delta
        if result_popup and result_popup.visible:
            result_popup.modulate = Color(1,1,1,1).lerp(rarity_flash_color, 0.16 * maxf(0.0, rarity_flash_timer))
    # Лёгкая анимация загрузочного экрана работает даже до инициализации игры.
    if not game_initialized:
        loading_elapsed += delta
        if loading_ring and is_instance_valid(loading_ring):
            loading_ring.rotation = sin(loading_elapsed * 0.65) * 0.035
        if loading_tip and is_instance_valid(loading_tip):
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
            var next_tip := int(loading_elapsed / 2.5) % tips.size()
            if next_tip != loading_tip_index:
                loading_tip_index = next_tip
                loading_tip.text = tips[loading_tip_index]
        return
    if aim_marker and is_instance_valid(aim_marker):
        aim_marker.position.x = claw_pos.x
        aim_marker.position.z = claw_pos.z
        aim_marker.position.y = 3.08
        aim_marker.visible = hud_layer.visible and drop_state == 0
        aim_marker.scale = Vector3.ONE * (1.0 + sin(time_alive * 3.0) * 0.05)
    animate_camera(delta)
    animate_machine_lights()
    process_claw(delta)
    if start_button and menu_layer.visible:
        start_button.modulate.a = 0.72 + 0.28 * (0.5 + 0.5 * sin(time_alive * 3.8))
    update_daily_login_ui()
    process_workshop_job()
    update_return_bonus_state()
    if season_pass_panel and season_pass_panel.visible:
        refresh_season_pass_panel()
    if promo_panel and promo_panel.visible:
        refresh_promo_panel()
    if rating_panel and rating_panel.visible:
        refresh_rating_panel()
    if return_bonus_panel and return_bonus_panel.visible:
        refresh_return_bonus_panel()
    if not android_touch_hint_shown and hud_layer and hud_layer.visible:
        android_touch_hint_shown = true
        if toast_label:
            toast_label.text = "👆 Управляйте клешнёй кнопками на экране. Нажмите ЗАХВАТ для попытки."
            toast_label.visible = true
            get_tree().create_timer(3.0).timeout.connect(func():
                if is_instance_valid(toast_label): toast_label.visible = false
            )
    if event_button and hud_layer and hud_layer.visible:
        if active_event_end_unix <= int(Time.get_unix_time_from_system()):
            activate_calendar_event()
            if prize_bodies.size() < TARGET_PRIZE_COUNT:
                spawn_random_prizes(TARGET_PRIZE_COUNT - prize_bodies.size())
        event_button.modulate.a = 0.65 + 0.35 * (0.5 + 0.5 * sin(time_alive * 3.0))
        event_ui_update_timer -= delta
        if event_ui_update_timer <= 0.0:
            event_ui_update_timer = 0.5
            update_event_panel()
    if hud_layer and hud_layer.visible and drop_state == 0:
        waiting_idle_time += delta
        if waiting_idle_time > 8.0:
            show_waiting_screen()
    update_android_navigation()
    if refill_animation_timer > 0.0:
        refill_animation_timer -= delta
        for light in machine_lights:
            if light and is_instance_valid(light):
                light.light_energy += 0.45 + sin(time_alive * 12.0) * 0.18
        var all_refill_done := true
        for body in prize_bodies:
            if not body or not is_instance_valid(body):
                continue
            if bool(body.get_meta("refill_active", false)):
                var delay_left: float = float(body.get_meta("refill_delay", 0.0))
                if delay_left > 0.0:
                    body.set_meta("refill_delay", maxf(0.0, delay_left - delta))
                    all_refill_done = false
                    continue
                var target: Vector3 = body.get_meta("refill_target", body.position)
                body.position = body.position.lerp(target, minf(1.0, delta * 4.0))
                body.rotation.x = lerpf(body.rotation.x, 0.0, minf(1.0, delta * 2.2))
                body.rotation.z = lerpf(body.rotation.z, 0.0, minf(1.0, delta * 2.2))
                all_refill_done = false
                if body.position.distance_to(target) < 0.035:
                    body.position = target
                    body.freeze = false
                    body.set_meta("refill_active", false)
        if all_refill_done:
            refill_animation_timer = 0.0
            current_result = "ГОТОВ К ИГРЕ"
            save_game()
            update_ui()
    if popup_timer > 0.0:
        popup_timer -= delta
        if popup_timer <= 0.0 and result_popup:
            result_popup.visible = false
    if drop_state == 0 and hud_layer.visible:
        # Движение не прыгает между точками: кнопка задаёт цель, а каретка
        # плавно догоняет её с инерцией. Клавиатура также работает плавно.
        var keyboard_speed := 2.6
        if Input.is_action_pressed("move_left"): move_x(-delta * keyboard_speed)
        if Input.is_action_pressed("move_right"): move_x(delta * keyboard_speed)
        if Input.is_action_pressed("move_forward"): move_z(-delta * keyboard_speed)
        if Input.is_action_pressed("move_back"): move_z(delta * keyboard_speed)
        var is_moving := (claw_pos.x != claw_move_target.x or claw_pos.z != claw_move_target.z)
        if is_moving and sfx_on and sfx_move and not sfx_move.playing:
            sfx_move.play()
        elif not is_moving and sfx_move and sfx_move.playing:
            sfx_move.stop()
        var smooth := 1.0 - exp(-delta * 10.0)
        claw_pos.x = lerpf(claw_pos.x, claw_move_target.x, smooth)
        claw_pos.z = lerpf(claw_pos.z, claw_move_target.z, smooth)
        if absf(claw_pos.x - claw_move_target.x) < 0.002: claw_pos.x = claw_move_target.x
        if absf(claw_pos.z - claw_move_target.z) < 0.002: claw_pos.z = claw_move_target.z
        if joystick_hold_x != 0.0 or joystick_hold_z != 0.0:
            var hold_speed := 2.75 * maxf(0.65, joystick_sensitivity)
            if joystick_hold_x != 0.0: move_x(joystick_hold_x * delta * hold_speed)
            if joystick_hold_z != 0.0: move_z(joystick_hold_z * delta * hold_speed)
        if Input.is_action_just_pressed("drop_claw"): drop_claw()

func animate_camera(delta: float) -> void:
    if not camera: return
    var target_pos := camera_base + Vector3(sin(time_alive * 0.18) * 0.10, sin(time_alive * 0.32) * 0.045, 0.0)
    camera.position = camera.position.lerp(target_pos, delta * 1.6)
    var target_look := camera_look + Vector3(sin(time_alive * 0.23) * 0.12, 0.03 * sin(time_alive * 0.4), 0.0)
    camera.look_at(target_look, Vector3.UP)

func animate_machine_lights() -> void:
    for i in range(machine_lights.size()):
        var light := machine_lights[i]
        var base := 0.55 if i >= 3 else 2.0
        light.light_energy = base + sin(time_alive * 1.2 + float(i)) * (0.08 if i >= 3 else 0.25)

func process_claw(delta: float) -> void:
    if not claw: return
    if drop_state != 0 and sfx_move and sfx_move.playing:
        sfx_move.stop()

    # 0 = ready, 1 = lowering, 2 = gripping, 3 = raising,
    # 4 = moving to chute, 5 = lowering over chute, 6 = releasing/waiting.
    if drop_state == 1:
        # Опускаемся только до верхнего слоя игрушек под клешнёй.
        # Если сверху уже лежит игрушка, клешня не пытается пробиться к нижним слоям.
        claw_pos.y = move_toward(claw_pos.y, claw_drop_target_y, delta * 13.0)
        animate_grip(0.0)
        if claw_pos.y <= claw_drop_target_y + 0.02:
            # Контакт клешни слегка сдвигает соседние игрушки — они физически
            # сталкиваются и перераскладываются, как в настоящем автомате.
            for j in range(prize_bodies.size()):
                var nearby_body := prize_bodies[j]
                if not nearby_body or not is_instance_valid(nearby_body) or nearby_body.freeze:
                    continue
                var dx := nearby_body.global_position.x - claw_pos.x
                var dz := nearby_body.global_position.z - claw_pos.z
                if sqrt(dx * dx + dz * dz) < 0.95:
                    nearby_body.apply_impulse(Vector3(randf_range(-0.18, 0.18), 0.12, randf_range(-0.18, 0.18)))
            drop_state = 2
            drop_time = 0.0

    elif drop_state == 2:
        drop_time += delta
        animate_grip(clampf(drop_time / 0.12, 0.0, 1.0))
        if drop_time >= 0.14:
            if _server_ready() and player_token != "" and not server_attempt_ready:
                # Не оставляем клешню навсегда внизу, если HTTP-ответ задержался.
                # Сервер всё равно остаётся источником истины; при нормальном ответе
                # этот таймер сбрасывается сразу в resolve_grab().
                if drop_time < 0.32:
                    return
                _abort_server_claw_attempt("Сервер слишком долго отвечает — клешня возвращается")
                return
            var grabbed := resolve_grab()
            drop_time = 0.0
            if grabbed:
                drop_state = 3
            else:
                if _server_ready() and player_token != "":
                    _server_action("game_finish")
                # Если клешня ничего не взяла, никаких лишних движений к отверстию:
                # сразу плавно возвращаем её в верхнюю парковочную точку над отверстием.
                grabbed_toy = null
                grabbed_index = -1
                claw_move_target = CLAW_HOME
                claw_target = CLAW_HOME
                drop_state = 8
                current_result = "КЛЕШНЬ ВОЗВРАЩАЕТСЯ"
                animate_grip(0.0)
                save_game()
                update_ui()

    elif drop_state == 3:
        # Сначала поднимаем клешню вертикально, игрушка жёстко следует за ней.
        claw_pos.y = move_toward(claw_pos.y, CLAW_HOME.y, delta * 6.0)
        animate_grip(1.0)
        follow_grabbed_toy()
        if claw_pos.y >= CLAW_HOME.y - 0.03:
            # Сервер может разрешить успешный захват, но случайно сделать
            # соскальзывание уже после подъёма — визуально это выглядит естественно.
            if SERVER_AUTHORITATIVE and server_attempt_slip and grabbed_toy and is_instance_valid(grabbed_toy):
                grabbed_toy.freeze = false
                grabbed_toy.sleeping = false
                grabbed_toy.linear_velocity = Vector3(randf_range(-0.35, 0.35), -1.7, randf_range(-0.35, 0.35))
                grabbed_toy.angular_velocity = Vector3(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
                grabbed_toy = null
                grabbed_index = -1
                pending_prize_data.clear()
                _server_action("game_finish")
                claw_move_target = CLAW_HOME
                claw_target = CLAW_HOME
                drop_state = 8
                drop_time = 0.0
                current_result = "ИГРУШКА СКОЛЬЗНУЛА"
                save_game()
                update_ui()
            elif not SERVER_AUTHORITATIVE and grabbed_toy and is_instance_valid(grabbed_toy) and String(pending_prize_data.get("kind", "toy")) == "toy" and randf() < clampf(GRAB_SLIP_CHANCE + (0.10 if bool(grabbed_toy.get_meta("slippery", false)) else 0.0) + clampf((float(grabbed_toy.get_meta("toy_weight", 38.0)) - 35.0) / 220.0, 0.0, 0.18) - (0.10 if int(pending_prize_data.get("index", -1)) == lucky_toy_index else 0.0), 0.05, 0.55):
                if _server_ready() and player_token != "":
                    _server_action("game_finish")
                grabbed_toy.freeze = false
                grabbed_toy.sleeping = false
                grabbed_toy.linear_velocity = Vector3(randf_range(-0.4, 0.4), -1.6, randf_range(-0.4, 0.4))
                grabbed_toy.angular_velocity = Vector3(randf_range(-1.8, 1.8), randf_range(-1.8, 1.8), randf_range(-1.8, 1.8))
                grabbed_toy = null
                grabbed_index = -1
                pending_prize_data.clear()
                claw_move_target = CLAW_HOME
                claw_target = CLAW_HOME
                drop_state = 8
                drop_time = 0.0
                current_result = "ИГРУШКА СКОЛЬЗНУЛА"
                save_game()
                update_ui()
            else:
                drop_state = 4
                drop_time = 0.0

    elif drop_state == 4:
        # Теперь именно КЛЕШНЯ С ИГРУШКОЙ едет к отверстию.
        var chute_target := Vector3(PRIZE_HOLE.x, CLAW_HOME.y, PRIZE_HOLE.z)
        var travel_speed := 6.8
        claw_pos.x = move_toward(claw_pos.x, chute_target.x, delta * travel_speed)
        claw_pos.z = move_toward(claw_pos.z, chute_target.z, delta * travel_speed)
        animate_grip(1.0)
        follow_grabbed_toy()
        if absf(claw_pos.x - chute_target.x) < 0.02 and absf(claw_pos.z - chute_target.z) < 0.02:
            claw_pos.x = chute_target.x
            claw_pos.z = chute_target.z
            drop_state = 5
            drop_time = 0.0

    elif drop_state == 5:
        # Опускаем клешню прямо над отверстием, сохраняя игрушку в захвате.
        var release_y := PRIZE_HOLE.y + 1.95
        claw_pos.y = move_toward(claw_pos.y, release_y, delta * 5.0)
        animate_grip(0.0)
        follow_grabbed_toy()
        if claw_pos.y <= release_y + 0.01:
            drop_state = 6
            drop_time = 0.0

    elif drop_state == 6:
        # Разжимаем когти и отпускаем игрушку точно над центром шахты.
        drop_time += delta
        animate_grip(clampf(drop_time / 0.22, 0.0, 1.0))
        if drop_time >= 0.22:
            if grabbed_toy and is_instance_valid(grabbed_toy):
                var chute_drop := PRIZE_HOLE + Vector3(0, 1.05, 0)
                grabbed_toy.global_position = chute_drop
                grabbed_toy.freeze = false
                grabbed_toy.sleeping = false
                grabbed_toy.linear_velocity = Vector3(0, -2.2, 0)
                play_upgrade_sound("drop")
                grabbed_toy.angular_velocity = Vector3(randf_range(-1.2, 1.2), randf_range(-1.2, 1.2), randf_range(-1.2, 1.2))
            drop_state = 7
            drop_time = 0.0

    elif drop_state == 7:
        # Даём игрушке физически провалиться в шахту, затем завершаем раунд.
        drop_time += delta
        if drop_time >= 0.75:
            if grabbed_toy and is_instance_valid(grabbed_toy):
                remove_delivered_prize()
                finalize_delivered_prize()
                show_prize_popup(last_prize_name, last_prize_collection, last_prize_rarity, last_prize_xp, last_reward_rubles)
                refill_prizes_if_needed()
            grabbed_toy = null
            grabbed_index = -1
            # После сброса клешня НЕ остаётся внизу: плавно возвращается
            # в верхнюю парковочную точку, которая находится прямо над отверстием.
            claw_move_target = CLAW_HOME
            claw_target = CLAW_HOME
            drop_state = 8
            drop_time = 0.0
            animate_grip(0.0)
            current_result = "КЛЕШНЬ ВОЗВРАЩАЕТСЯ"
            save_game()
            update_ui()

    elif drop_state == 8:
        # Возвращаем клешню вверх в её исходное положение над отверстием.
        var return_speed := 6.2
        claw_pos.y = move_toward(claw_pos.y, CLAW_HOME.y, delta * return_speed)
        claw_pos.x = move_toward(claw_pos.x, CLAW_HOME.x, delta * return_speed)
        claw_pos.z = move_toward(claw_pos.z, CLAW_HOME.z, delta * return_speed)
        animate_grip(0.0)
        if (claw_pos - CLAW_HOME).length() < 0.025:
            claw_pos = CLAW_HOME
            claw_move_target = CLAW_HOME
            claw_target = CLAW_HOME
            drop_state = 0
            drop_time = 0.0
            current_result = "ГОТОВ К ИГРЕ"
            save_game()
            update_ui()

    claw.position = claw_pos
    if rail_carriage:
        rail_carriage.position.x = claw_pos.x
        rail_carriage.position.z = claw_pos.z
    update_cable()

func follow_grabbed_toy() -> void:
    if grabbed_toy and is_instance_valid(grabbed_toy):
        var shake := Vector3(sin(time_alive * 18.0) * 0.035, sin(time_alive * 13.0) * 0.025, cos(time_alive * 16.0) * 0.035)
        var hold := claw.global_position + Vector3(0, -1.15, 0) + shake
        grabbed_toy.global_position = hold
        grabbed_toy.rotation.x = sin(time_alive * 14.0) * 0.06
        grabbed_toy.rotation.z = cos(time_alive * 17.0) * 0.08
        grabbed_toy.freeze = true
        grabbed_toy.sleeping = true

func update_cable() -> void:
    if not cable: return
    var length: float = maxf(0.15, CLAW_HOME.y - claw_pos.y + 0.65)
    cable.mesh.height = length
    cable.position.y = length * 0.5 + 0.65
    if cable_glow:
        cable_glow.mesh.height = length
        cable_glow.position.y = length * 0.5 + 0.65

func animate_grip(amount: float) -> void:
    for i in range(claw_arms.size()):
        var arm := claw_arms[i]
        arm.rotation.z = lerpf(0.0, -0.42, amount)
        arm.position.y = sin(float(i) + time_alive * 5.0) * 0.008

func move_x(amount: float) -> void:
    if drop_state != 0 or not hud_layer.visible: return
    register_game_activity()
    claw_move_target.x = clampf(claw_move_target.x + amount, CLAW_MIN.x, CLAW_MAX.x)

func move_z(amount: float) -> void:
    if drop_state != 0 or not hud_layer.visible: return
    register_game_activity()
    claw_move_target.z = clampf(claw_move_target.z + amount, CLAW_MIN.z, CLAW_MAX.z)

func _start_fast_claw_server_attempt() -> bool:
    if not _server_ready() or player_token == "":
        return false
    if claw_http_busy or not claw_http:
        return false
    server_attempt_ready = false
    server_attempt_success = false
    server_attempt_toy_id = ""
    server_attempt_toy_name = ""
    server_attempt_reward = {}
    server_attempt_slip = false
    server_target_prize_index = -1
    var target_id := ""
    server_target_prize_index = -1
    var nearest := choose_nearest_prize()
    if nearest >= 0 and nearest < prize_data.size():
        server_target_prize_index = nearest
        var nd: Dictionary = prize_data[nearest]
        var ni := int(nd.get("index", -1))
        if ni >= 0 and ni < toys.size(): target_id = String(toys[ni].get("id", ""))
    var payload := {"type":"game_start", "target_toy_id":target_id, "action_id":"game_start_%s_%s" % [player_id, str(Time.get_ticks_msec())]}
    claw_http_busy = true
    var err := claw_http.request(_normalized_server_url() + "/api/player/action", _remote_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        claw_http_busy = false
        return false
    return true

func _start_fast_cosmetic_server_request(item_id: String) -> bool:
    if not _server_ready() or player_token == "" or cosmetic_http_busy or not cosmetic_http:
        return false
    cosmetic_http_busy = true
    var payload := {"type":"cosmetic_buy", "action_id":"cosmetic_%s_%s" % [player_id, str(Time.get_ticks_msec())], "item_id":item_id}
    var err := cosmetic_http.request(_normalized_server_url() + "/api/player/action", _remote_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        cosmetic_http_busy = false
        return false
    return true

func _claw_is_over_chute() -> bool:
    var dx := claw_pos.x - PRIZE_HOLE.x
    var dz := claw_pos.z - PRIZE_HOLE.z
    return sqrt(dx * dx + dz * dz) <= 0.82

func drop_claw() -> void:
    if drop_state != 0 or not hud_layer.visible: return
    # Над шахтой выдачи захват запрещён: это парковочная точка клешни.
    if _claw_is_over_chute():
        current_result = "ПЕРЕДВИНЬТЕ КЛЕШНЮ К ИГРУШКАМ"
        update_ui()
        return
    play_upgrade_sound("grab")
    register_game_activity()
    var nearest_prize := choose_nearest_prize()
    if nearest_prize >= 0 and nearest_prize < prize_bodies.size():
        var nearest_body := prize_bodies[nearest_prize]
        if nearest_body and is_instance_valid(nearest_body):
            claw_drop_target_y = clampf(nearest_body.global_position.y + 0.92, 3.50, MAX_PRIZE_CENTER_Y + 0.95)
    else:
        claw_drop_target_y = 3.50
    if _server_ready():
        if player_token == "":
            current_result = "НЕТ АВТОРИЗАЦИИ СЕРВЕРА"
            update_ui()
            return
        server_attempt_ready = false
        server_attempt_success = false
        server_attempt_toy_id = ""
        server_attempt_toy_name = ""
        server_attempt_reward = {}
        if not _start_fast_claw_server_attempt():
            current_result = "СЕРВЕР ЗАНЯТ — ПОВТОРИТЕ"
            update_ui()
            return
    if not SERVER_AUTHORITATIVE:
        total_games += 1
    if vibration_on:
        Input.vibrate_handheld(55, 0.35)
    save_game()
    claw_target = claw_pos
    claw_move_target = claw_pos
    claw_drop_target_y = find_top_layer_drop_y()
    drop_state = 1
    drop_time = 0.0
    current_result = "КЛЕШНЬ ОПУСКАЕТСЯ..."
    update_ui()

func resolve_grab() -> bool:
    # В онлайне результат захвата уже определён сервером в game_start.
    # Клиент отвечает только за визуальную часть и выбор игрушки под клешнёй.
    if _server_ready() and player_token != "":
        if not server_attempt_ready:
            current_result = "ЖДЁМ ОТВЕТ СЕРВЕРА…"
            update_ui()
            return false
        if not server_attempt_success:
            current_result = "НЕ УДЕРЖАЛА 😅"
            play_upgrade_sound("fail")
            current_win_streak = 0
            update_ui()
            return false
        var server_choice := -1
        if server_attempt_toy_name != "":
            for i in range(prize_data.size()):
                if String(prize_data[i].get("kind", "toy")) == "toy" and String(prize_data[i].get("name", "")) == server_attempt_toy_name:
                    server_choice = i
                    break
        if server_choice < 0 and server_attempt_toy_id != "":
            for i in range(prize_data.size()):
                if String(prize_data[i].get("kind", "toy")) == "toy":
                    var pi := int(prize_data[i].get("index", -1))
                    if pi >= 0 and pi < toys.size() and String(toys[pi].get("id", "")) == server_attempt_toy_id:
                        server_choice = i
                        break
        # Визуально захватываем только игрушку, которая действительно находится
        # под клешнёй. Если серверный приз есть, но сейчас далеко от неё, выбираем
        # ближайшую верхнюю игрушку текущей партии; сервер всё равно остаётся
        # источником истины для успешности и награды.
        if server_choice >= 0:
            var candidate := prize_bodies[server_choice] if server_choice < prize_bodies.size() else null
            if candidate and is_instance_valid(candidate):
                var cdx := candidate.global_position.x - claw_pos.x
                var cdz := candidate.global_position.z - claw_pos.z
                if sqrt(cdx * cdx + cdz * cdz) > 1.05:
                    server_choice = -1
        # Фиксируем именно ту ближайшую игрушку, над которой игрок нажал «ЗАХВАТ».
        # После движения вниз не выбираем другую игрушку случайно.
        var chosen_server := server_target_prize_index
        if chosen_server < 0 or chosen_server >= prize_bodies.size():
            chosen_server = server_choice
        if chosen_server >= 0 and chosen_server < prize_bodies.size():
            var exact_body := prize_bodies[chosen_server]
            if not exact_body or not is_instance_valid(exact_body):
                chosen_server = -1
            else:
                var exact_dist := Vector2(exact_body.global_position.x - claw_pos.x, exact_body.global_position.z - claw_pos.z).length()
                if exact_dist > 0.90:
                    chosen_server = -1
        if chosen_server < 0:
            chosen_server = choose_top_layer_prize()
        if chosen_server < 0 or chosen_server >= prize_bodies.size():
            current_result = "ПОД КЛЕШНЁЙ НЕТ ПРИЗА"
            update_ui()
            return false
        grabbed_index = chosen_server
        var selected_body_server := prize_bodies[chosen_server]
        grabbed_toy = selected_body_server
        pending_prize_data = prize_data[chosen_server].duplicate(true)
        pending_prize_data["weight"] = float(selected_body_server.get_meta("toy_weight", 38.0)) if selected_body_server else 38.0
        last_reward_rubles = int(server_attempt_reward.get("amount", 0))
        last_prize_xp = 0
        last_prize_name = String(pending_prize_data.get("name", "Приз"))
        last_prize_collection = String(pending_prize_data.get("collection", ""))
        last_prize_rarity = String(pending_prize_data.get("rarity", ""))
        if grabbed_toy and is_instance_valid(grabbed_toy):
            grabbed_toy.freeze = true
            grabbed_toy.sleeping = true
        play_upgrade_sound("win")
        current_result = "ЗАХВАТ: %s • СЕРВЕР ПОДТВЕРДИЛ" % last_prize_name
        update_ui()
        return true

    var bonus: float = float(claw_specs[selected_claw]["bonus"])
    var upgrade_bonus: float = float(upgrade_levels[0] + upgrade_levels[1] + upgrade_levels[2]) * 0.028
    var success_chance: float = clampf(0.28 + bonus + upgrade_bonus, 0.0, 0.95)
    var empty_chance: float = clampf(0.16 - float(upgrade_levels[1]) * 0.012, 0.015, 0.16)
    var chosen := choose_top_layer_prize()
    if chosen < 0:
        current_result = "ПОД КЛЕШНЁЙ НЕТ ПРИЗА"
        update_ui()
        return false
    var selected_body := prize_bodies[chosen]
    var selected_weight := float(selected_body.get_meta("toy_weight", 38.0)) if selected_body else 38.0
    var heavy_penalty := clampf((selected_weight - 35.0) / 180.0, -0.08, 0.30)
    var slippery_penalty := 0.12 if selected_body and bool(selected_body.get_meta("slippery", false)) else 0.0
    var horizontal_distance := Vector2(claw_pos.x - selected_body.global_position.x, claw_pos.z - selected_body.global_position.z).length()
    # Точность теперь действительно влияет на захват: чем ближе центр клешни
    # к центру верхней игрушки, тем выше шанс удержать её.
    var aim_bonus := clampf((0.82 - horizontal_distance) * 0.12, 0.0, 0.10)
    var lucky_bonus := 0.0
    if String(prize_data[chosen].get("kind", "toy")) == "toy" and int(prize_data[chosen].get("index", -1)) == lucky_toy_index:
        lucky_bonus = 0.10
    var rarity_bonus := event_rarity_weight_bonus(String(prize_data[chosen].get("rarity", "ОБЫЧНАЯ")))
    var final_chance := clampf(success_chance - heavy_penalty - slippery_penalty + lucky_bonus + active_event_bonus + rarity_bonus + aim_bonus, 0.08, 0.98)
    if randf() < empty_chance or randf() > final_chance:
        current_result = "НЕ УДЕРЖАЛА 😅"
        play_upgrade_sound("fail")
        current_win_streak = 0
        update_ui()
        return false
    grabbed_index = chosen
    if selected_body and claw_pos.distance_to(selected_body.global_position) < 0.75:
        perfect_grabs += 1
    grabbed_toy = prize_bodies[chosen]
    if grabbed_toy and is_instance_valid(grabbed_toy):
        grabbed_toy.freeze = true
        grabbed_toy.sleeping = true
    pending_prize_data = prize_data[chosen].duplicate(true)
    pending_prize_data["weight"] = selected_weight
    last_reward_rubles = 0
    last_prize_xp = 0
    last_prize_name = String(pending_prize_data.get("name", "Приз"))
    last_prize_collection = String(pending_prize_data.get("collection", ""))
    last_prize_rarity = String(pending_prize_data.get("rarity", ""))
    var aim_quality := "ИДЕАЛЬНО" if horizontal_distance <= 0.22 else ("ТОЧНО" if horizontal_distance <= 0.48 else "НОРМАЛЬНО")
    current_result = "ЗАХВАТ: %s • НАВЕДЕНИЕ %s" % [last_prize_name, aim_quality]
    update_ui()
    return true

func finalize_delivered_prize() -> void:
    if _server_ready():
        if player_token == "":
            current_result = "НЕТ АВТОРИЗАЦИИ СЕРВЕРА"
            pending_prize_data.clear()
            update_ui()
            return
        if not _server_action("game_finish"):
            current_result = "СЕРВЕР ЗАНЯТ — НАГРАДА НЕ ЗАЧИСЛЕНА"
            update_ui()
            return
        # В онлайн-режиме награду, игрушку, XP, сундук и достижения выдаёт только сервер.
        pending_prize_data.clear()
        current_result = "РЕЗУЛЬТАТ ПРОВЕРЯЕТСЯ СЕРВЕРОМ…"
        update_ui()
        return
    if pending_prize_data.is_empty():
        return
    var d: Dictionary = pending_prize_data
    var kind := String(d.get("kind", "toy"))
    last_reward_rubles = 0
    last_prize_xp = 0
    last_prize_name = String(d.get("name", "Приз"))
    last_prize_collection = String(d.get("collection", ""))
    last_prize_rarity = String(d.get("rarity", ""))
    var previous_count: int = 0
    if kind == "capsule":
        last_reward_rubles = randi_range(int(d.get("reward_min", 3)), int(d.get("reward_max", 12)))
        last_reward_rubles = maxi(last_reward_rubles, int(round(last_reward_rubles * active_event_reward_mult)))
        coins += last_reward_rubles
        play_upgrade_sound("coin")
        highest_reward_rubles = maxi(highest_reward_rubles, last_reward_rubles)
        current_result = "🪙 КАПСУЛА: +%d ₽" % last_reward_rubles
    else:
        var already_owned := collection.has(last_prize_name)
        previous_count = int(toy_inventory_counts.get(last_prize_name, 1 if already_owned else 0))
        collection[last_prize_name] = last_prize_rarity
        toy_inventory_counts[last_prize_name] = previous_count + 1
        last_prize_xp = award_toy_xp(last_prize_rarity)
        total_prizes_won += 1
        current_win_streak += 1
        award_chest_for_win(last_prize_rarity)
        best_win_streak = maxi(best_win_streak, current_win_streak)
        if float(d.get("weight", 38.0)) >= 80.0:
            heavy_toy_wins += 1
        daily_mission_progress = mini(daily_mission_target, daily_mission_progress + 1)
        weekly_mission_progress = mini(weekly_mission_target, weekly_mission_progress + 1)
        rarity_wins[last_prize_rarity] = int(rarity_wins.get(last_prize_rarity, 0)) + 1
        total_xp_earned += last_prize_xp
        # Праздничный множитель действует на обычную награду тоже.
        coins += maxi(0, int(round(float(rarity_reward(last_prize_rarity)) * maxf(0.0, active_event_reward_mult - 1.0))))
        if int(d.get("index", -1)) == lucky_toy_index:
            lucky_toy_wins += 1
            last_prize_xp *= 3
            total_xp_earned += last_prize_xp - int(last_prize_xp / 3.0)
            coins += int(rarity_reward(last_prize_rarity) * 2.0 * active_event_reward_mult)
            current_result = "🍀 СЧАСТЛИВАЯ ИГРУШКА! x3"
            if last_prize_xp > best_result_xp:
                best_result_xp = last_prize_xp
                best_result = "%s • +%d XP" % [last_prize_name, last_prize_xp]
        check_collection_completion(last_prize_collection)
        current_result = "🎉 ДОСТАЛ: %s • %s" % [last_prize_name, last_prize_rarity]
        rarity_flash_timer = 1.6
        rarity_flash_color = rarity_color(last_prize_rarity)
        play_upgrade_sound("win")
    if kind == "toy" and previous_count > 0 and not sale_available:
        # Только дубль уже имеющейся игрушки можно продать.
        sale_name = last_prize_name
        sale_rarity = last_prize_rarity
        sale_price = maxi(3, int(round(float(rarity_reward(last_prize_rarity)) * 0.65)))
        sale_available = true
        show_sale_offer()
    complete_daily_mission_if_ready()
    complete_weekly_mission_if_ready()
    check_achievements()
    update_missions()
    pending_prize_data.clear()
    save_game()
    update_ui()

func choose_nearest_prize(max_distance: float = 1.28) -> int:
    var best := -1
    var best_dist := max_distance
    var best_y := -100.0
    for i in range(prize_bodies.size()):
        var body := prize_bodies[i]
        if not body or not is_instance_valid(body) or not body.visible or body.freeze:
            continue
        if i >= prize_data.size(): continue
        if String(prize_data[i].get("kind", "toy")) != "toy": continue
        var dx := body.global_position.x - claw_pos.x
        var dz := body.global_position.z - claw_pos.z
        var dist := sqrt(dx * dx + dz * dz)
        if dist <= best_dist and (dist < best_dist - 0.015 or body.global_position.y > best_y):
            best = i
            best_dist = dist
            best_y = body.global_position.y
    return best

func find_top_layer_drop_y() -> float:
    var best_y := 3.50
    var found := false
    var best_center_y := -100.0
    for i in range(prize_bodies.size()):
        var body := prize_bodies[i]
        if not body or not is_instance_valid(body) or not body.visible:
            continue
        var d: Dictionary = prize_data[i]
        var dx := body.global_position.x - claw_pos.x
        var dz := body.global_position.z - claw_pos.z
        # Радиус рабочей зоны клешни. Берём только самый верхний предмет.
        if sqrt(dx * dx + dz * dz) <= 0.82 and body.global_position.y > best_center_y:
            best_center_y = body.global_position.y
            found = true
    if found:
        # Центр клешни находится примерно на 1.0 м выше центра игрушки.
        best_y = clampf(best_center_y + 0.98, 3.50, MAX_PRIZE_CENTER_Y + 0.95)
    return best_y

func choose_top_layer_prize() -> int:
    var best := -1
    var best_y := -100.0
    var best_dist := 999.0
    for i in range(prize_bodies.size()):
        var body := prize_bodies[i]
        if not body or not is_instance_valid(body) or not body.visible:
            continue
        var dx := body.global_position.x - claw_pos.x
        var dz := body.global_position.z - claw_pos.z
        var dist := sqrt(dx * dx + dz * dz)
        if dist > 0.82:
            continue
        var y := body.global_position.y
        # Только верхний слой: нижняя игрушка не выбирается, если сверху есть другая.
        if y > best_y + 0.035 or (absf(y - best_y) <= 0.035 and dist < best_dist):
            best = i
            best_y = y
            best_dist = dist
    return best

func remove_delivered_prize() -> void:
    if grabbed_index < 0 or grabbed_index >= prize_bodies.size():
        return
    var body := prize_bodies[grabbed_index]
    if body and is_instance_valid(body):
        body.queue_free()
    prize_bodies.remove_at(grabbed_index)
    prize_data.remove_at(grabbed_index)

func choose_toy() -> int:
    var total := 0.0
    var active: Array[int] = []
    var nearby: Array[int] = []
    for i in range(prize_bodies.size()):
        var body := prize_bodies[i]
        if body and is_instance_valid(body) and body.visible:
            var d: Dictionary = prize_data[i]
            if String(d.get("kind", "toy")) == "toy" and not batch_allowed(int(d.get("index", 0))):
                continue
            var weight := 1.0
            if String(d.get("kind", "toy")) == "capsule":
                weight = 5.5
            else:
                var source_index: int = int(d.get("index", 0))
                weight = float(toys[source_index]["weight"])
            total += weight
            active.append(i)
            var dx := body.global_position.x - claw_pos.x
            var dz := body.global_position.z - claw_pos.z
            if sqrt(dx * dx + dz * dz) <= 0.95:
                nearby.append(i)
    if active.is_empty(): return -1
    var pool: Array[int] = nearby if not nearby.is_empty() else active
    total = 0.0
    for i in pool:
        var d: Dictionary = prize_data[i]
        if String(d.get("kind", "toy")) == "capsule":
            total += 5.5
        else:
            var source_index: int = int(d.get("index", 0))
            total += float(toys[source_index]["weight"])
    var r := randf() * total
    for i in pool:
        var d: Dictionary = prize_data[i]
        var weight := 5.5 if String(d.get("kind", "toy")) == "capsule" else float(toys[int(d.get("index", 0))]["weight"])
        r -= weight
        if r <= 0.0: return i
    return pool.back()

func xp_for_rarity(rarity: String) -> int:
    match rarity:
        "ОБЫЧНАЯ": return randi_range(3, 5)
        "РЕДКАЯ": return randi_range(5, 7)
        "ЭПИЧЕСКАЯ": return randi_range(7, 10)
        "ЛЕГЕНДАРНАЯ": return randi_range(10, 14)
        _: return 4

func xp_needed_for_level(level: int) -> int:
    var l: int = maxi(1, level)
    return 80 + (l - 1) * 18 + int(pow(float(l - 1), 1.35) * 2.2)

func award_toy_xp(rarity: String) -> int:
    # Каждая успешно полученная игрушка даёт немного опыта.
    # Редкость повышает награду, но значения остаются небольшими.
    if player_level >= MAX_PLAYER_LEVEL:
        player_xp = xp_to_next
        current_result = "🎉 %s • МАКСИМАЛЬНЫЙ УРОВЕНЬ" % rarity
        return 0
    var gained: int = xp_for_rarity(rarity)
    var workshop_xp_bonus: int = int(floor(float(workshop_speed + workshop_servo + workshop_controller) * 0.15))
    workshop_xp_bonus += int(floor(float(gained) * workshop_blueprint_bonus("speed")))
    if workshop_overclock and workshop_overclock_games > 0:
        workshop_xp_bonus += int(ceil(float(gained) * 0.15))
    gained += workshop_xp_bonus
    player_xp += gained
    add_season_pass_xp(gained)
    current_result = "🎁 %s • +%d XP" % [rarity, gained]
    while player_xp >= xp_to_next and player_level < MAX_PLAYER_LEVEL:
        player_xp -= xp_to_next
        player_level += 1
        xp_to_next = xp_needed_for_level(player_level)
        var level_reward: int = 15 + player_level * 2
        coins += level_reward
        current_result = "⬆ НОВЫЙ УРОВЕНЬ %d • +%d ₽" % [player_level, level_reward]
        play_upgrade_sound("level")
    if player_level >= MAX_PLAYER_LEVEL:
        player_xp = xp_to_next
    return gained

func check_collection_completion(collection_name: String) -> void:
    if completed_collections.has(collection_name):
        return
    var needed: int = 0
    var got: int = 0
    for toy in toys:
        if String(toy["collection"]) == collection_name:
            needed += 1
            if collection.has(String(toy["name"])):
                got += 1
    if needed > 0 and got >= needed:
        completed_collections[collection_name] = true
        var reward: int = 60 + needed * 10
        coins += reward
        current_result = "🏆 КОЛЛЕКЦИЯ «%s» ПОЛНА • +%d ₽" % [collection_name, reward]
        check_achievements()

func achievement_value(spec: Dictionary) -> int:
    match String(spec.get("kind", "")):
        "toys": return total_prizes_won
        "games": return total_games
        "rarity": return int(rarity_wins.get(String(spec.get("rarity", "")), 0))
        "collections": return completed_collections.size()
        "level": return player_level
        "rubles": return coins
        "claws":
            var count := 0
            for owned in owned_claws:
                if owned: count += 1
            return count
        "upgrades":
            var total := 0
            for lvl in upgrade_levels: total += lvl
            return total
        "best_streak": return best_win_streak
        "perfect": return perfect_grabs
        "heavy": return heavy_toy_wins
        "lucky": return lucky_toy_wins
        "xp": return total_xp_earned
        "max_reward": return highest_reward_rubles
        "chests_opened": return total_chests_opened
        "keys_earned": return total_keys_earned
        "exclusive": return chest_exclusive_reward_count
        "workshop_level": return workshop_level
        "parts": return workshop_parts
        "calibration": return workshop_calibration
        "overclock": return 1 if workshop_overclock_games > 0 or workshop_overclock else 0
        "claw_skins":
            var count_claw_skins := 0
            for owned in owned_claw_skins:
                if owned: count_claw_skins += 1
            return count_claw_skins
        "toy_skins":
            var count_toy_skins := 0
            for owned in owned_toy_skins:
                if owned: count_toy_skins += 1
            return count_toy_skins
        "machine_skins":
            var count_machine_skins := 0
            for owned in owned_machine_skins:
                if owned: count_machine_skins += 1
            return count_machine_skins
        "login_streak": return login_streak
        "daily_claims": return total_daily_claims
        "weekly_claims": return total_weekly_claims
        "referrals": return referral_invites
    return 0

func check_achievements() -> void:
    for spec in achievement_specs:
        var id := String(spec["id"])
        if unlocked_achievements.has(id):
            continue
        if achievement_value(spec) >= int(spec["value"]):
            unlocked_achievements[id] = true
            pending_new_achievements.append(String(spec["name"]))
    if not pending_new_achievements.is_empty():
        current_result = "🏆 НОВОЕ ДОСТИЖЕНИЕ: %s" % pending_new_achievements[0]

func show_prize_popup(toy_name: String, cname: String, rarity: String, xp: int, reward_rubles: int = 0) -> void:
    if not result_popup: return
    popup_name_label.text = toy_name
    popup_info_label.text = "%s  •  %s" % [cname, rarity]
    if reward_rubles > 0:
        popup_xp_label.text = "+%d ₽" % reward_rubles
    else:
        popup_xp_label.text = "+%d XP" % xp
    if pending_new_achievements.is_empty():
        popup_achievement_label.text = ""
    else:
        popup_achievement_label.text = "🏆 ДОСТИЖЕНИЕ: " + " • ".join(pending_new_achievements)
    popup_timer = 3.0
    result_popup.visible = true
    pending_new_achievements.clear()

func rarity_reward(rarity: String) -> int:
    match rarity:
        "ОБЫЧНАЯ": return 8
        "РЕДКАЯ": return 20
        "ЭПИЧЕСКАЯ": return 50
        "ЛЕГЕНДАРНАЯ": return 150
    return 5

func buy_claw(index: int) -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"
            update_ui()
            return
        if _server_action("shop_buy", {"item_id":"claw_%d" % (index + 1)}):
            current_result = "Покупка проверяется сервером…"
            update_ui()
            return
        return
    if index >= 0 and index < owned_claws.size() and owned_claws[index]:
        selected_claw = index
        current_result = "УСТАНОВЛЕНА: %s" % String(claw_specs[index]["name"])
        save_game()
        update_ui()
        return
    if _server_ready() and player_token != "":
        if _server_action("shop_buy", {"item_id":"claw_%d" % (index + 1)}):
            current_result = "Покупка проверяется сервером…"
            update_ui()
            return
    var price := int(claw_specs[index]["price"])
    if owned_claws[index]:
        selected_claw = index
        current_result = "УСТАНОВЛЕНА: %s" % String(claw_specs[index]["name"])
    elif coins >= price:
        coins -= price
        owned_claws[index] = true
        selected_claw = index
        current_result = "КУПЛЕНА: %s" % String(claw_specs[index]["name"])
        check_achievements()
        save_game()
    else:
        current_result = "НЕДОСТАТОЧНО РУБЛЕЙ"
    update_ui()

func buy_upgrade(index: int) -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "":
            current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"
            update_ui()
            return
        if _server_action("shop_buy", {"item_id":"upgrade_%d" % (index + 1)}):
            current_result = "Улучшение проверяется сервером…"
            update_ui()
            return
        return
    if _server_ready() and player_token != "":
        if _server_action("shop_buy", {"item_id":"upgrade_%d" % (index + 1)}):
            current_result = "Улучшение проверяется сервером…"
            update_ui()
            return
    if index < 0 or index >= upgrade_specs.size():
        return
    var level: int = upgrade_levels[index]
    if level >= 5:
        current_result = "МАКСИМАЛЬНЫЙ УРОВЕНЬ"
        update_ui()
        return
    var price: int = int(upgrade_specs[index]["base_price"]) * (level + 1)
    if coins >= price:
        coins -= price
        upgrade_levels[index] = level + 1
        current_result = "УЛУЧШЕНИЕ: %s • УРОВЕНЬ %d" % [String(upgrade_specs[index]["name"]), level + 1]
        check_achievements()
        save_game()
    else:
        current_result = "НЕДОСТАТОЧНО РУБЛЕЙ"
    update_ui()

func show_sale_offer() -> void:
    if not result_popup: return
    popup_xp_label.text = "ДУБЛЬ • ПРОДАТЬ ЗА %d ₽?" % sale_price
    popup_achievement_label.text = "Игрушка уже есть в коллекции. Можно оставить дубль или продать его."
    popup_timer = 0.0
    result_popup.visible = true
    if not sale_panel:
        sale_panel = PanelContainer.new()
        sale_panel.position = Vector2(90, 900)
        sale_panel.size = Vector2(900, 130)
        style_panel(sale_panel, Color("#9A7653"))
        hud_layer.add_child(sale_panel)
        var h := HBoxContainer.new()
        h.alignment = BoxContainer.ALIGNMENT_CENTER
        h.add_theme_constant_override("separation", 14)
        sale_panel.add_child(h)
        var sell := Button.new()
        sell.text = "💰 ПРОДАТЬ"
        sell.custom_minimum_size = Vector2(280, 75)
        style_button(sell, Color("#C09A70"))
        sell.add_theme_font_size_override("font_size", 22)
        sell.pressed.connect(sell_duplicate)
        h.add_child(sell)
        var keep := Button.new()
        keep.text = "ОСТАВИТЬ"
        keep.custom_minimum_size = Vector2(280, 75)
        style_button(keep, Color("#76583F"))
        keep.add_theme_font_size_override("font_size", 22)
        keep.pressed.connect(keep_duplicate)
        h.add_child(keep)
    sale_panel.visible = true

func sell_duplicate() -> void:
    if not sale_available: return
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "": current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; update_ui(); return
        if _server_action("sell_duplicate", {"toy_name":sale_name,"amount":sale_price}):
            sale_available = false
            if sale_panel: sale_panel.visible = false
            result_popup.visible = false
        return
    coins += sale_price
    current_result = "💰 ДУБЛЬ ПРОДАН • +%d ₽" % sale_price
    sale_available = false
    sale_panel.visible = false
    result_popup.visible = false
    save_game()
    update_ui()

func keep_duplicate() -> void:
    sale_available = false
    if sale_panel: sale_panel.visible = false
    result_popup.visible = false
    current_result = "🧸 ДУБЛЬ ОСТАВЛЕН В КОЛЛЕКЦИИ"
    save_game()
    update_ui()

func reset_progress() -> void:
    coins = 120
    selected_claw = 0
    owned_claws = [true, false, false, false, false, false, false, false, false, false]
    collection.clear()
    toy_inventory_counts.clear()
    completed_collections.clear()
    player_level = 1
    player_xp = 0
    xp_to_next = xp_needed_for_level(1)
    total_games = 0
    total_prizes_won = 0
    total_chests_opened = 0
    total_keys_earned = 0
    total_daily_claims = 0
    total_weekly_claims = 0
    current_win_streak = 0
    best_win_streak = 0
    total_xp_earned = 0
    highest_reward_rubles = 0
    perfect_grabs = 0
    heavy_toy_wins = 0
    lucky_toy_wins = 0
    login_streak = 0
    last_login_claim_date = ""
    active_event_id = ""
    active_event_name = ""
    active_event_end_unix = 0
    active_event_bonus = 0.0
    active_event_reward_mult = 1.0
    batch_type = "ОБЫЧНАЯ ПАРТИЯ"
    batch_index = 0
    language = "ru"
    sfx_volume_db = -4.0
    vibration_on = true
    auto_tips_on = true
    daily_mission_progress = 0
    daily_mission_date = Time.get_date_string_from_system()
    daily_mission_claimed = false
    weekly_mission_progress = 0
    weekly_mission_key = ""
    weekly_mission_claimed = false
    lucky_toy_date = ""
    lucky_toy_index = 0
    rarity_wins.clear()
    unlocked_achievements.clear()
    upgrade_levels = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    vip_owned.resize(vip_specs.size())
    for i in range(vip_owned.size()): vip_owned[i] = false
    vip_selected = 0
    active_season_id = ""
    chest_inventory = {"common": 0, "rare": 0, "epic": 0, "legendary": 0, "vip": 0}
    chest_keys = 0
    chest_opening = false
    chest_last_reward = ""
    chest_exclusive_toys = {}
    chest_exclusive_skins = {}
    chest_exclusive_reward_count = 0
    workshop_parts = 0
    workshop_level = 1
    workshop_claw_power = 0
    workshop_speed = 0
    workshop_precision = 0
    workshop_luck = 0
    workshop_motor = 0
    workshop_servo = 0
    workshop_cable = 0
    workshop_damper = 0
    workshop_cooling = 0
    workshop_controller = 0
    workshop_blueprints = {"grip":"none", "speed":"none", "precision":"none", "luck":"none"}
    workshop_calibration = 0
    workshop_overclock = false
    workshop_overclock_games = 0
    return_bonus_days = 0
    return_bonus_available = false
    return_bonus_claimed = false
    last_active_unix = int(Time.get_unix_time_from_system())
    workshop_job_end_unix = 0
    workshop_job_active = false
    workshop_job_name = ""
    workshop_job_reward = 0
    season_pass_xp = 0
    season_pass_level = 1
    promo_codes_used.clear()
    promo_status = ""
    notify_rewards_on = true
    notify_streak_on = true
    notify_events_on = true
    notify_workshop_on = true
    notify_chests_on = true
    saved_prizes.clear()
    build_prizes()
    current_result = "ПРОГРЕСС СБРОШЕН"
    save_game()
    update_ui()

func serialize_prizes() -> Array:
    var result: Array = []
    for i in range(prize_bodies.size()):
        var body := prize_bodies[i]
        if not body or not is_instance_valid(body):
            continue
        var source_index: int = int(prize_data[i].get("index", 0)) if i < prize_data.size() else 0
        var d: Dictionary = prize_data[i] if i < prize_data.size() else {}
        result.append({
            "kind": String(d.get("kind", "toy")),
            "source_index": source_index,
            "variant": int(d.get("variant", 0)),
            "size_factor": float(d.get("size_factor", 1.0)),
            "position": [body.position.x, body.position.y, body.position.z],
            "rotation": [body.rotation.x, body.rotation.y, body.rotation.z]
        })
    return result

func setup_daily_systems() -> void:
    var today := Time.get_date_string_from_system()
    if daily_mission_date != today:
        daily_mission_date = today
        daily_mission_progress = 0
        daily_mission_claimed = false
    var day_number := int(floor(Time.get_unix_time_from_system() / 86400.0))
    var week_key := str(int(floor(float(day_number) / 7.0)))
    if weekly_mission_key != week_key:
        weekly_mission_key = week_key
        weekly_mission_progress = 0
        weekly_mission_claimed = false
    if lucky_toy_date != today:
        lucky_toy_date = today
        lucky_toy_index = abs(today.hash()) % toys.size()
    save_game()

func register_game_activity() -> void:
    last_game_activity = time_alive
    if _server_ready():
        sync_player_to_server()
    waiting_idle_time = 0.0
    if waiting_overlay:
        waiting_overlay.visible = false

func update_missions() -> void:
    if not hud_layer or not is_instance_valid(hud_layer):
        return
    var panel := hud_layer.get_node_or_null("MissionDetailPanel") as PanelContainer
    if panel and panel.visible:
        var is_daily := String(panel.get_meta("mission_type", "daily")) == "daily"
        var title := panel.get_node("MissionDetailVBox/MissionDetailTitle") as Label
        var detail := panel.get_node("MissionDetailVBox/MissionDetailText") as Label
        if is_daily:
            title.text = "🎯 МИССИЯ ДНЯ"
            detail.text = "Поймай %d игрушки\nПрогресс: %d / %d\nНаграда: +50 ₽" % [daily_mission_target, daily_mission_progress, daily_mission_target]
        else:
            title.text = "🏆 НЕДЕЛЬНОЕ ЗАДАНИЕ"
            detail.text = "Поймай %d игрушек\nПрогресс: %d / %d\nНаграда: +180 ₽" % [weekly_mission_target, weekly_mission_progress, weekly_mission_target]

func show_waiting_screen() -> void:
    if not auto_tips_on:
        return
    if not waiting_overlay or not hud_layer.visible or drop_state != 0:
        return
    waiting_overlay.visible = true
    var tips := [
        "ПОДСКАЗКА: ЦЕЛЬСЯ В ЦЕНТР ИГРУШКИ",
        "ПОДСКАЗКА: ТЯЖЁЛЫЕ ИГРУШКИ СЛОЖНЕЕ УДЕРЖАТЬ",
        "ПОДСКАЗКА: СЧАСТЛИВАЯ ИГРУШКА ДАЁТ x3",
        "ПОДСКАЗКА: ВЫПОЛНЯЙ МИССИИ ДЛЯ БОНУСОВ",
        "ПОДСКАЗКА: НЕ СПЕШИ — СНАЧАЛА ВЫБЕРИ УДОБНУЮ ЦЕЛЬ",
        "ПОДСКАЗКА: ИГРУШКИ МОГУТ СТАЛКИВАТЬСЯ ДРУГ С ДРУГОМ",
        "ПОДСКАЗКА: СКОЛЬЗКИЕ ИГРУШКИ ЛЕГЧЕ ПОТЕРЯТЬ ПРИ ПОДЪЁМЕ",
        "ПОДСКАЗКА: РЕДКИЕ ИГРУШКИ МОГУТ ПРИНЕСТИ БОЛЬШУЮ НАГРАДУ",
        "ПОДСКАЗКА: СЛЕДИ ЗА ЕЖЕДНЕВНОЙ И НЕДЕЛЬНОЙ МИССИЯМИ",
        "ПОДСКАЗКА: СОБИРАЙ ИГРУШКИ, ЧТОБЫ РАЗВИВАТЬ ПРОФИЛЬ",
        "ПОДСКАЗКА: ПОСЛЕ НЕУДАЧНОГО ЗАХВАТА ИГРУШКА МОЖЕТ РАСКАЧАТЬСЯ",
        "ПОДСКАЗКА: ПРОВЕРЯЙ ПРОФИЛЬ, ЧТОБЫ СЛЕДИТЬ ЗА ПРОГРЕССОМ"
    ]
    # Меняем подсказку медленнее: одна новая подсказка примерно раз в 12 секунд.
    waiting_tip_label.text = tips[int(time_alive / 12.0) % tips.size()]

func complete_daily_mission_if_ready() -> void:
    if _server_ready() and player_token != "" and daily_mission_progress >= daily_mission_target and not daily_mission_claimed:
        if _server_action("claim_daily_mission"):
            return
    if daily_mission_progress >= daily_mission_target and not daily_mission_claimed:
        coins += server_reward_amount(daily_mission_reward)
        daily_mission_progress = daily_mission_target
        daily_mission_claimed = true
        total_daily_claims += 1
        current_result = "🎯 МИССИЯ ДНЯ ВЫПОЛНЕНА • +%d ₽" % server_reward_amount(daily_mission_reward)
        notify_phone("🎯 Хватайка", "Ежедневная миссия выполнена. Награда +50 ₽ уже получена!")

func complete_weekly_mission_if_ready() -> void:
    if _server_ready() and player_token != "" and weekly_mission_progress >= weekly_mission_target and not weekly_mission_claimed:
        if _server_action("claim_weekly_mission"):
            return
    if weekly_mission_progress >= weekly_mission_target and not weekly_mission_claimed:
        coins += server_reward_amount(weekly_mission_reward)
        weekly_mission_progress = weekly_mission_target
        weekly_mission_claimed = true
        total_weekly_claims += 1
        current_result = "🏆 НЕДЕЛЬНОЕ ЗАДАНИЕ ВЫПОЛНЕНА • +%d ₽" % server_reward_amount(weekly_mission_reward)
        notify_phone("🏆 Хватайка", "Недельное задание выполнено. Награда +180 ₽ уже получена!")

func claim_daily_bonus() -> void:
    if SERVER_AUTHORITATIVE:
        if not _server_ready() or player_token == "": current_result = "НЕТ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ"; update_ui(); return
        if _server_action("claim_daily"):
            return
        return
    # Награда выдаётся только один раз в календарный день.
    var today: String = Time.get_date_string_from_system()
    if last_daily_bonus_date == today:
        return

    coins += server_reward_amount(daily_bonus_amount)
    last_daily_bonus_date = today
    save_game()

    if toast_label:
        toast_label.text = "ЕЖЕДНЕВНЫЙ БОНУС  +%d ₽" % daily_bonus_amount
        toast_label.visible = true
        await get_tree().create_timer(3.0).timeout
        if is_instance_valid(toast_label):
            toast_label.visible = false

func rarity_color(rarity: String) -> Color:
    match rarity:
        "ОБЫЧНАЯ": return Color("#D6D0C8")
        "НЕОБЫЧНАЯ": return Color("#76B77B")
        "РЕДКАЯ": return Color("#6E9FD8")
        "ЭПИЧЕСКАЯ": return Color("#9C78D8")
        "ЛЕГЕНДАРНАЯ": return Color("#D6A14A")
        "МИФИЧЕСКАЯ": return Color("#D36C55")
        _: return Color.WHITE

func build_upgrade_sound_system() -> void:
    # Отдельные короткие SFX: интерфейс, захват, успех, срыв, монеты и выдача.
    var files := {
        "button":"res://audio/ui_click.wav",
        "open":"res://audio/ui_open.wav",
        "close":"res://audio/ui_close.wav",
        "coin":"res://audio/coin.wav",
        "grab":"res://audio/grab_close.wav",
        "win":"res://audio/grab_success.wav",
        "fail":"res://audio/grab_fail.wav",
        "drop":"res://audio/prize_drop.wav"
    }
    for key in files.keys():
        var player := AudioStreamPlayer.new()
        player.name = "SFX_" + String(key)
        player.stream = load(String(files[key]))
        player.volume_db = sfx_volume_db
        add_child(player)
        sound_players[key] = player
    # Движение клешни остаётся отдельным циклическим моторным звуком.
    sfx_move = make_sfx_player("res://audio/claw_move.wav")
    if sfx_move.stream is AudioStreamWAV:
        (sfx_move.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

func play_ui_sound(kind: String) -> void:
    if not sfx_on: return
    var player: AudioStreamPlayer = sound_players.get(kind, null)
    if player and is_instance_valid(player) and player.stream:
        player.volume_db = sfx_volume_db
        player.play()

func play_upgrade_sound(kind: String) -> void:
    if kind == "grab":
        play_ui_sound("grab")
    elif kind == "win":
        play_ui_sound("win")
    elif kind == "fail":
        play_ui_sound("fail")
    elif kind == "coin":
        play_ui_sound("coin")
    elif kind == "drop":
        play_ui_sound("drop")
    elif kind == "level" or kind == "chest" or kind == "button":
        play_ui_sound("button")

func get_profile_summary() -> String:
    var collections_done := completed_collections.size()
    var unique := collection.size()
    return "Игрок: %s\nУровень %d  •  XP %d/%d\nИгр: %d  •  Игрушек: %d  •  Уникальных: %d\nЛучшая серия: %d  •  Идеальных захватов: %d\nКоллекции: %d/%d\nКлючи: %d  •  Детали: %d" % [player_name, player_level, player_xp, xp_to_next, total_games, total_prizes_won, unique, best_win_streak, perfect_grabs, collections_done, get_collection_names().size(), chest_keys, workshop_parts]

func get_daily_weekly_summary() -> String:
    return "ЕЖЕДНЕВНОЕ: %d/%d   •   Награда %d ₽\nЕЖЕНЕДЕЛЬНОЕ: %d/%d   •   Награда %d ₽" % [daily_mission_progress,daily_mission_target,int(round(float(daily_mission_reward) * online_reward_multiplier)),weekly_mission_progress,weekly_mission_target,int(round(float(weekly_mission_reward) * online_reward_multiplier))]

func refresh_upgrade_dashboard() -> void:
    update_ui()
    if menu_layer and menu_layer.visible:
        menu_notice_count = int((daily_mission_target - daily_mission_progress) > 0) + int((weekly_mission_target - weekly_mission_progress) > 0) + int(chest_keys > 0)

func save_game() -> void:
    # SERVER_AUTHORITATIVE: this file is a UI/cache snapshot only. Economy/progress authority lives on server.
    server_settings_dirty = true
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({
            "coins": coins,
            "player_name": player_name,
            "player_avatar_index": player_avatar_index,
            "music": music_on,
            "sfx": sfx_on,
            "sfx_volume_db": sfx_volume_db,
            "music_volume_db": music_volume_db,
            "vibration_on": vibration_on,
            "energy_saving_on": energy_saving_on,
            "confirm_purchases_on": confirm_purchases_on,
            "confirm_rare_chests_on": confirm_rare_chests_on,
            "fps_limit": fps_limit,
            "joystick_sensitivity": joystick_sensitivity,
            "grab_button_scale": grab_button_scale,
            "auto_tips_on": auto_tips_on,
            "notifications_on": notifications_on,
            "notify_rewards_on": notify_rewards_on,
            "notify_streak_on": notify_streak_on,
            "notify_events_on": notify_events_on,
            "notify_workshop_on": notify_workshop_on,
            "notify_chests_on": notify_chests_on,
            "return_bonus_days": return_bonus_days,
            "return_bonus_available": return_bonus_available,
            "return_bonus_claimed": return_bonus_claimed,
            "last_active_unix": last_active_unix,
            "workshop_job_end_unix": workshop_job_end_unix,
            "workshop_job_active": workshop_job_active,
            "workshop_job_name": workshop_job_name,
            "workshop_job_reward": workshop_job_reward,
            "season_pass_xp": season_pass_xp,
            "season_pass_level": season_pass_level,
            "promo_codes_used": promo_codes_used,
            "quality_level": quality_level,
            "language": language,
            "server_url": server_url,
            "player_id": player_id,
            "player_token": player_token,
            "bonus_keys": bonus_keys,
            "engineering_parts": engineering_parts,
            "claw": selected_claw,
            "owned_claws": owned_claws,
            "owned_claw_skins": owned_claw_skins,
            "owned_toy_skins": owned_toy_skins,
            "owned_machine_skins": owned_machine_skins,
            "selected_claw_skin": selected_claw_skin,
            "selected_toy_skin": selected_toy_skin,
            "selected_machine_skin": selected_machine_skin,
            "vip_owned": vip_owned,
            "vip_selected": vip_selected,
            "active_season_id": active_season_id,
            "chest_inventory": chest_inventory,
            "chest_keys": chest_keys,
            "chest_exclusive_toys": chest_exclusive_toys,
            "chest_exclusive_skins": chest_exclusive_skins,
            "chest_exclusive_reward_count": chest_exclusive_reward_count,
            "total_chests_opened": total_chests_opened,
            "total_keys_earned": total_keys_earned,
            "total_daily_claims": total_daily_claims,
            "total_weekly_claims": total_weekly_claims,
            "workshop_parts": workshop_parts,
            "workshop_level": workshop_level,
            "workshop_claw_power": workshop_claw_power,
            "workshop_speed": workshop_speed,
            "workshop_precision": workshop_precision,
            "workshop_luck": workshop_luck,
            "workshop_motor": workshop_motor,
            "workshop_servo": workshop_servo,
            "workshop_cable": workshop_cable,
            "workshop_damper": workshop_damper,
            "workshop_cooling": workshop_cooling,
            "workshop_controller": workshop_controller,
            "workshop_blueprints": workshop_blueprints,
            "workshop_calibration": workshop_calibration,
            "workshop_overclock": workshop_overclock,
            "workshop_overclock_games": workshop_overclock_games,
            "collection": collection,
            "toy_inventory_counts": toy_inventory_counts,
            "completed_collections": completed_collections,
            "upgrades": upgrade_levels,
            "level": player_level,
            "xp": player_xp,
            "xp_to_next": xp_to_next,
            "games": total_games,
            "total_prizes_won": total_prizes_won,
            "rarity_wins": rarity_wins,
            "achievements": unlocked_achievements,
            "last_daily_bonus_date": last_daily_bonus_date,
            "login_streak": login_streak,
            "last_login_claim_date": last_login_claim_date,
            "active_event_id": active_event_id,
            "active_event_name": active_event_name,
            "active_event_end_unix": active_event_end_unix,
            "active_event_bonus": active_event_bonus,
            "active_event_reward_mult": active_event_reward_mult,
            "batch_type": batch_type,
            "batch_index": batch_index,
            "referral_code": referral_code,
            "referral_invites": referral_invites,
            "referral_used": referral_used,
            "best_result": best_result,
            "best_result_xp": best_result_xp,
            "current_win_streak": current_win_streak,
            "best_win_streak": best_win_streak,
            "total_xp_earned": total_xp_earned,
            "highest_reward_rubles": highest_reward_rubles,
            "perfect_grabs": perfect_grabs,
            "heavy_toy_wins": heavy_toy_wins,
            "lucky_toy_wins": lucky_toy_wins,
            "daily_mission_progress": daily_mission_progress,
            "daily_mission_date": daily_mission_date,
            "daily_mission_claimed": daily_mission_claimed,
            "weekly_mission_progress": weekly_mission_progress,
            "weekly_mission_key": weekly_mission_key,
            "weekly_mission_claimed": weekly_mission_claimed,
            "lucky_toy_index": lucky_toy_index,
            "lucky_toy_date": lucky_toy_date,
            "prizes": serialize_prizes(),
            "claw_position": [claw_pos.x, claw_pos.y, claw_pos.z]
        }))
        f.close()

func load_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH): return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f: return
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(parsed) != TYPE_DICTIONARY: return
    var data: Dictionary = parsed
    player_token = String(data.get("player_token", player_token))
    player_name = String(data.get("player_name", "ИГРОК")).strip_edges()
    if player_name == "":
        player_name = "ИГРОК"
    player_name = player_name.substr(0, 20)
    player_avatar_index = clampi(int(data.get("player_avatar_index", 0)), 0, AVATAR_OPTIONS.size() - 1)
    bonus_keys = int(data.get("bonus_keys", 0))
    engineering_parts = int(data.get("engineering_parts", 0))
    coins = maxi(0, int(data.get("coins", 120)))
    selected_claw = clampi(int(data.get("claw", 0)), 0, claw_specs.size() - 1)
    music_on = bool(data.get("music", true))
    sfx_on = bool(data.get("sfx", true))
    sfx_volume_db = clampf(float(data.get("sfx_volume_db", -4.0)), -24.0, 3.0)
    music_volume_db = clampf(float(data.get("music_volume_db", -8.0)), -30.0, 3.0)
    vibration_on = bool(data.get("vibration_on", true))
    energy_saving_on = bool(data.get("energy_saving_on", false))
    confirm_purchases_on = bool(data.get("confirm_purchases_on", true))
    confirm_rare_chests_on = bool(data.get("confirm_rare_chests_on", true))
    fps_limit = int(data.get("fps_limit", 60))
    if fps_limit not in [30,60,90,120]: fps_limit = 60
    Engine.max_fps = 30 if energy_saving_on else fps_limit
    joystick_sensitivity = clampf(float(data.get("joystick_sensitivity", 1.0)), 0.5, 1.5)
    grab_button_scale = clampf(float(data.get("grab_button_scale", 1.0)), 0.8, 1.3)
    auto_tips_on = bool(data.get("auto_tips_on", true))
    notifications_on = bool(data.get("notifications_on", true))
    notify_rewards_on = bool(data.get("notify_rewards_on", true))
    notify_streak_on = bool(data.get("notify_streak_on", true))
    notify_events_on = bool(data.get("notify_events_on", true))
    notify_workshop_on = bool(data.get("notify_workshop_on", true))
    notify_chests_on = bool(data.get("notify_chests_on", true))
    return_bonus_days = maxi(0, int(data.get("return_bonus_days", 0)))
    return_bonus_available = bool(data.get("return_bonus_available", false))
    return_bonus_claimed = bool(data.get("return_bonus_claimed", false))
    last_active_unix = int(data.get("last_active_unix", 0))
    workshop_job_end_unix = int(data.get("workshop_job_end_unix", 0))
    workshop_job_active = bool(data.get("workshop_job_active", false))
    workshop_job_name = String(data.get("workshop_job_name", ""))
    workshop_job_reward = maxi(0, int(data.get("workshop_job_reward", 0)))
    season_pass_xp = maxi(0, int(data.get("season_pass_xp", 0)))
    season_pass_level = clampi(int(data.get("season_pass_level", 1)), 1, SEASON_PASS_MAX_LEVEL)
    var saved_codes: Variant = data.get("promo_codes_used", {})
    if saved_codes is Dictionary: promo_codes_used = saved_codes
    server_url = String(data.get("server_url", DEFAULT_SERVER_URL)).strip_edges().trim_suffix("/")
    # Migrate old cloud endpoint to the new Selectel server.
    if server_url == "" or server_url == "https://khvataika-server.onrender.com":
        server_url = DEFAULT_SERVER_URL
    player_id = String(data.get("player_id", ""))
    quality_level = clampi(int(data.get("quality_level", 2)), 0, 4)
    var saved_upgrades: Variant = data.get("upgrades", upgrade_levels)
    if saved_upgrades is Array:
        upgrade_levels = []
        for i in range(upgrade_specs.size()):
            var value: Variant = saved_upgrades[i] if i < saved_upgrades.size() else 0
            upgrade_levels.append(clampi(int(value), 0, 5))
    var saved_owned: Variant = data.get("owned_claws", owned_claws)
    if saved_owned is Array and saved_owned.size() == claw_specs.size():
        owned_claws = []
        for value in saved_owned:
            owned_claws.append(bool(value))
    owned_claws[0] = true
    var saved_claw_skins: Variant = data.get("owned_claw_skins", owned_claw_skins)
    if saved_claw_skins is Array and saved_claw_skins.size() == claw_skin_specs.size():
        owned_claw_skins = []
        for value in saved_claw_skins: owned_claw_skins.append(bool(value))
    var saved_toy_skins: Variant = data.get("owned_toy_skins", owned_toy_skins)
    if saved_toy_skins is Array and saved_toy_skins.size() == toy_skin_specs.size():
        owned_toy_skins = []
        for value in saved_toy_skins: owned_toy_skins.append(bool(value))
    var saved_machine_skins: Variant = data.get("owned_machine_skins", owned_machine_skins)
    if saved_machine_skins is Array and saved_machine_skins.size() == machine_skin_specs.size():
        owned_machine_skins = []
        for value in saved_machine_skins: owned_machine_skins.append(bool(value))
    if not owned_claw_skins.is_empty(): owned_claw_skins[0] = true
    if not owned_toy_skins.is_empty(): owned_toy_skins[0] = true
    if not owned_machine_skins.is_empty(): owned_machine_skins[0] = true
    selected_claw_skin = clampi(int(data.get("selected_claw_skin", 0)), 0, claw_skin_specs.size() - 1)
    selected_toy_skin = clampi(int(data.get("selected_toy_skin", 0)), 0, toy_skin_specs.size() - 1)
    selected_machine_skin = clampi(int(data.get("selected_machine_skin", 0)), 0, machine_skin_specs.size() - 1)
    var saved_vip: Variant = data.get("vip_owned", [])
    vip_owned.resize(vip_specs.size())
    for i in range(vip_owned.size()): vip_owned[i] = false
    if saved_vip is Array:
        for i in range(mini(saved_vip.size(), vip_owned.size())): vip_owned[i] = bool(saved_vip[i])
    vip_selected = clampi(int(data.get("vip_selected", 0)), 0, maxi(0, vip_specs.size() - 1))
    active_season_id = String(data.get("active_season_id", ""))
    var saved_chests: Variant = data.get("chest_inventory", chest_inventory)
    if saved_chests is Dictionary:
        for key in chest_inventory.keys(): chest_inventory[key] = maxi(0, int(saved_chests.get(key, 0)))
    chest_keys = maxi(0, int(data.get("chest_keys", 0)))
    var saved_ex_toys: Variant = data.get("chest_exclusive_toys", {})
    if saved_ex_toys is Dictionary: chest_exclusive_toys = saved_ex_toys
    var saved_ex_skins: Variant = data.get("chest_exclusive_skins", {})
    if saved_ex_skins is Dictionary: chest_exclusive_skins = saved_ex_skins
    chest_exclusive_reward_count = maxi(0, int(data.get("chest_exclusive_reward_count", 0)))
    var saved_counts: Variant = data.get("toy_inventory_counts", {})
    if saved_counts is Dictionary: toy_inventory_counts = saved_counts
    workshop_parts = maxi(0, int(data.get("workshop_parts", 0)))
    workshop_level = maxi(1, int(data.get("workshop_level", 1)))
    workshop_claw_power = clampi(int(data.get("workshop_claw_power", 0)), 0, 10)
    workshop_speed = clampi(int(data.get("workshop_speed", 0)), 0, 10)
    workshop_precision = clampi(int(data.get("workshop_precision", 0)), 0, 10)
    workshop_luck = clampi(int(data.get("workshop_luck", 0)), 0, 10)
    workshop_motor = clampi(int(data.get("workshop_motor", 0)), 0, 15)
    workshop_servo = clampi(int(data.get("workshop_servo", 0)), 0, 15)
    workshop_cable = clampi(int(data.get("workshop_cable", 0)), 0, 15)
    workshop_damper = clampi(int(data.get("workshop_damper", 0)), 0, 15)
    workshop_cooling = clampi(int(data.get("workshop_cooling", 0)), 0, 15)
    workshop_controller = clampi(int(data.get("workshop_controller", 0)), 0, 15)
    var saved_blueprints: Variant = data.get("workshop_blueprints", {})
    if saved_blueprints is Dictionary: workshop_blueprints = saved_blueprints
    workshop_calibration = clampi(int(data.get("workshop_calibration", 0)), 0, 5)
    workshop_overclock = bool(data.get("workshop_overclock", false))
    workshop_overclock_games = maxi(0, int(data.get("workshop_overclock_games", 0)))
    player_level = maxi(1, int(data.get("level", 1)))
    player_xp = maxi(0, int(data.get("xp", 0)))
    xp_to_next = maxi(xp_needed_for_level(player_level), int(data.get("xp_to_next", xp_needed_for_level(player_level))))
    total_games = maxi(0, int(data.get("games", 0)))
    total_prizes_won = maxi(0, int(data.get("total_prizes_won", 0)))
    total_chests_opened = maxi(0, int(data.get("total_chests_opened", 0)))
    total_keys_earned = maxi(0, int(data.get("total_keys_earned", 0)))
    total_daily_claims = maxi(0, int(data.get("total_daily_claims", 0)))
    total_weekly_claims = maxi(0, int(data.get("total_weekly_claims", 0)))
    var saved_rarity: Variant = data.get("rarity_wins", {})
    if saved_rarity is Dictionary: rarity_wins = saved_rarity
    var saved_ach: Variant = data.get("achievements", {})
    if saved_ach is Dictionary: unlocked_achievements = saved_ach
    last_daily_bonus_date = String(data.get("last_daily_bonus_date", ""))
    login_streak = maxi(0, int(data.get("login_streak", 0)))
    last_login_claim_date = String(data.get("last_login_claim_date", ""))
    active_event_id = String(data.get("active_event_id", ""))
    active_event_name = String(data.get("active_event_name", ""))
    active_event_end_unix = int(data.get("active_event_end_unix", 0))
    active_event_bonus = float(data.get("active_event_bonus", 0.0))
    active_event_reward_mult = float(data.get("active_event_reward_mult", 1.0))
    batch_type = String(data.get("batch_type", "ОБЫЧНАЯ ПАРТИЯ"))
    batch_index = int(data.get("batch_index", 0))
    language = String(data.get("language", "ru"))
    if language != "en": language = "ru"
    referral_code = String(data.get("referral_code", ""))
    referral_invites = maxi(0, int(data.get("referral_invites", 0)))
    referral_used = bool(data.get("referral_used", false))
    best_result = String(data.get("best_result", "—"))
    best_result_xp = maxi(0, int(data.get("best_result_xp", 0)))
    current_win_streak = maxi(0, int(data.get("current_win_streak", 0)))
    best_win_streak = maxi(0, int(data.get("best_win_streak", 0)))
    total_xp_earned = maxi(0, int(data.get("total_xp_earned", 0)))
    highest_reward_rubles = maxi(0, int(data.get("highest_reward_rubles", 0)))
    perfect_grabs = maxi(0, int(data.get("perfect_grabs", 0)))
    heavy_toy_wins = maxi(0, int(data.get("heavy_toy_wins", 0)))
    lucky_toy_wins = maxi(0, int(data.get("lucky_toy_wins", 0)))
    daily_mission_progress = maxi(0, int(data.get("daily_mission_progress", 0)))
    daily_mission_date = String(data.get("daily_mission_date", ""))
    daily_mission_claimed = bool(data.get("daily_mission_claimed", false))
    weekly_mission_progress = maxi(0, int(data.get("weekly_mission_progress", 0)))
    weekly_mission_key = String(data.get("weekly_mission_key", ""))
    weekly_mission_claimed = bool(data.get("weekly_mission_claimed", false))
    lucky_toy_index = clampi(int(data.get("lucky_toy_index", 0)), 0, toys.size() - 1)
    lucky_toy_date = String(data.get("lucky_toy_date", ""))
    var saved_completed: Variant = data.get("completed_collections", {})
    if saved_completed is Dictionary:
        completed_collections = saved_completed
    var saved_collection: Variant = data.get("collection", {})
    if saved_collection is Dictionary:
        collection = saved_collection
    var loaded_prizes: Variant = data.get("prizes", [])
    if loaded_prizes is Array:
        saved_prizes = loaded_prizes
        var toy_counts: Dictionary = {}
        var unique_toys := {}
        for saved in saved_prizes:
            if saved is Dictionary and String(saved.get("kind", "toy")) == "toy":
                var idx := int(saved.get("source_index", 0))
                toy_counts[idx] = int(toy_counts.get(idx, 0)) + 1
                unique_toys[idx] = true
        var too_many_duplicates := false
        for key in toy_counts.keys():
            if int(toy_counts[key]) > 3:
                too_many_duplicates = true
                break
        if unique_toys.size() < 24 or too_many_duplicates:
            saved_prizes.clear()
    var saved_claw_pos: Variant = data.get("claw_position", [])
    if saved_claw_pos is Array and saved_claw_pos.size() >= 3:
        claw_pos = Vector3(
            clampf(float(saved_claw_pos[0]), CLAW_MIN.x, CLAW_MAX.x),
            clampf(float(saved_claw_pos[1]), CLAW_MIN.y, CLAW_MAX.y),
            clampf(float(saved_claw_pos[2]), CLAW_MIN.z, CLAW_MAX.z)
        )
        claw_target = claw_pos
