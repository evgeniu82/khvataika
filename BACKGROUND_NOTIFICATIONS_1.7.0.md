# Фоновые уведомления — Хватайка 1.7.0

В проект добавлен editor-плагин `Хватайка Background Notifications`.

Он автоматически добавляет в Gradle Android template Java BroadcastReceiver, который использует Android AlarmManager и NotificationManager. Godot 4.7 поддерживает Gradle Android build template для модификации Android Java-проекта.

## Один раз в Godot

1. Открой `project.godot`.
2. Если папки `res://android/build` ещё нет: **Проект → Установить шаблон сборки Android**.
3. Открой **Проект → Настройки → Плагины** и убедись, что `Хватайка Background Notifications` включён.
4. В Android Export preset оставь **Gradle Build → Use Gradle Build = true**.
5. Собирай AAB как обычно.

Плагин автоматически создаёт:
- `KhvataikaAlarmReceiver.java`;
- разрешение `RECEIVE_BOOT_COMPLETED`;
- receiver для `BOOT_COMPLETED` и `MY_PACKAGE_REPLACED`.

В игре расписания создаются автоматически:
- 12:00 — ежедневная награда;
- 20:00 — серия входов.

Используется `setAndAllowWhileIdle`, поэтому специальное разрешение exact alarms не требуется; время может быть немного сдвинуто системой Android для экономии батареи.
