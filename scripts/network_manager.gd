extends Node
## Хватайка — Stage 1 Network Manager
##
## Purpose of this stage:
## - background server health check;
## - retry with backoff;
## - connection telemetry only; authenticated game requests are owned by main.gd.
## - never blocks gameplay or waits in the main game loop.
##
## Deliberately NOT implemented here:
## - authoritative game actions;
## - economy writes;
## - player snapshot replacement;
## - catalog/config application.
## Those responsibilities belong to the main game network layer.

signal status_changed(status: String, detail: String)
signal connected_to_server(server_version: String, schema: int)
signal player_registered(player_id: String)
signal disconnected_from_server(reason: String)

const STATUS_OFFLINE := "offline"
const STATUS_CHECKING := "checking"
const STATUS_ONLINE := "online"
const STATUS_REGISTERING := "registering"
const STATUS_ERROR := "error"

var enabled: bool = false
var server_url: String = ""
var timeout_sec: float = 3.0
var player_id: String = ""
var player_name: String = "ИГРОК"
var player_token: String = ""
var status: String = STATUS_OFFLINE
var detail: String = "Сетевое подключение отключено"
var server_version: String = ""
var server_schema: int = 0
var retry_index: int = 0
var retry_timer: float = 0.0
var health_timer: float = 0.0
var request_kind: String = ""
var http: HTTPRequest

func _ready() -> void:
    enabled = bool(ProjectSettings.get_setting("application/config/online_stage1_enabled", false))
    server_url = String(ProjectSettings.get_setting("application/config/online_stage1_server_url", "")).strip_edges().trim_suffix("/")
    timeout_sec = clampf(float(ProjectSettings.get_setting("application/config/online_stage1_timeout", 3.0)), 1.0, 5.0)
    if not enabled or server_url == "":
        _set_status(STATUS_OFFLINE, "Офлайн-режим: серверный слой Stage 1 выключен")
        return
    http = HTTPRequest.new()
    http.name = "Stage1NetworkHTTP"
    http.timeout = timeout_sec
    add_child(http)
    http.request_completed.connect(_on_request_completed)
    _set_status(STATUS_CHECKING, "Проверяем сервер в фоне…")
    call_deferred("_begin_health_check")

func configure_player(id: String, name: String = "ИГРОК") -> void:
    player_id = id.strip_edges()
    player_name = name.strip_edges()
    if player_name == "":
        player_name = "ИГРОК"
    # Registration/authentication is intentionally handled by main.gd so there
    # is only one authenticated session/request queue for the game.
    if enabled and server_url != "" and status == STATUS_ONLINE:
        _set_status(STATUS_ONLINE, "Сервер доступен; игровая сессия запускается отдельно")

func _process(delta: float) -> void:
    if not enabled or not is_instance_valid(http):
        return
    if retry_timer > 0.0:
        retry_timer = maxf(0.0, retry_timer - delta)
        if retry_timer <= 0.0 and request_kind == "":
            _begin_health_check()
    if health_timer > 0.0:
        health_timer = maxf(0.0, health_timer - delta)
        if health_timer <= 0.0 and request_kind == "":
            _begin_health_check()

func _begin_health_check() -> void:
    if request_kind != "" or server_url == "" or not is_instance_valid(http):
        return
    request_kind = "health"
    _set_status(STATUS_CHECKING, "Проверяем связь…")
    var err := http.request(server_url + "/api/game/ping")
    if err != OK:
        request_kind = ""
        _schedule_retry("Не удалось запустить запрос")

func _register_player() -> void:
    if request_kind != "" or player_id == "" or not is_instance_valid(http):
        return
    request_kind = "register"
    _set_status(STATUS_REGISTERING, "Регистрируем сессию игрока в фоне…")
    var headers := PackedStringArray(["Content-Type: application/json"])
    var payload := {"player_id": player_id, "name": player_name}
    var err := http.request(server_url + "/api/player/register", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        request_kind = ""
        _schedule_retry("Не удалось запустить регистрацию")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var kind := request_kind
    request_kind = ""
    var ok_transport := result == HTTPRequest.RESULT_SUCCESS
    var ok_http := response_code >= 200 and response_code < 300
    var data: Dictionary = {}
    if ok_transport and body.size() > 0:
        var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
        if parsed is Dictionary:
            data = parsed
    if not ok_transport or not ok_http or data.is_empty():
        var reason := "Нет ответа от сервера"
        if ok_transport and not ok_http:
            reason = "Сервер ответил HTTP %d" % response_code
        elif ok_transport and body.size() > 0 and data.is_empty():
            reason = "Некорректный ответ сервера"
        _schedule_retry(reason)
        return

    retry_index = 0
    retry_timer = 0.0
    health_timer = 30.0
    server_version = String(data.get("app_version", data.get("server_version", "")))
    server_schema = int(data.get("schema", 0))

    if kind == "health":
        _set_status(STATUS_ONLINE, "Сервер доступен; игра продолжает работать локально")
        connected_to_server.emit(server_version, server_schema)
    elif kind == "register":
        if String(data.get("token", "")) != "":
            player_token = String(data.get("token"))
        _set_status(STATUS_ONLINE, "Сервер подключен; сессия игрока подтверждена")
        player_registered.emit(player_id)

func _schedule_retry(reason: String) -> void:
    retry_index = mini(retry_index + 1, 6)
    var delays := [2.0, 5.0, 15.0, 30.0, 60.0, 120.0]
    retry_timer = delays[retry_index - 1]
    _set_status(STATUS_ERROR, reason + " • следующая проверка через %.0f сек" % retry_timer)
    disconnected_from_server.emit(reason)

func _set_status(next_status: String, next_detail: String) -> void:
    status = next_status
    detail = next_detail
    status_changed.emit(status, detail)

func is_online() -> bool:
    return status == STATUS_ONLINE or status == STATUS_REGISTERING

func get_status_text() -> String:
    return detail
