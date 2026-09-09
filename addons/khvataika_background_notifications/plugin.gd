@tool
extends EditorPlugin

const JAVA_RELATIVE := "app/src/main/java/com/clawneon/khvataika/KhvataikaAlarmReceiver.java"
const MANIFEST_RELATIVE := "app/src/main/AndroidManifest.xml"
const JAVA_TEMPLATE := "res://addons/khvataika_background_notifications/KhvataikaAlarmReceiver.java"
const NOTIFICATION_THUMBNAIL := "res://addons/khvataika_background_notifications/notification_thumbnail.png"

func _enter_tree() -> void:
    set_process(true)
    _patch_android_template()

func _process(_delta: float) -> void:
    if _patch_android_template():
        set_process(false)

func _patch_android_template() -> bool:
    var root := ProjectSettings.globalize_path("res://android/build")
    var manifest_path := root.path_join(MANIFEST_RELATIVE)
    var java_path := root.path_join(JAVA_RELATIVE)
    if not FileAccess.file_exists(manifest_path):
        return false
    var source := FileAccess.get_file_as_string(JAVA_TEMPLATE)
    var res_dir := root.path_join("app/src/main/res/drawable")
    DirAccess.make_dir_recursive_absolute(res_dir)
    if FileAccess.file_exists(NOTIFICATION_THUMBNAIL):
        var thumb := FileAccess.get_file_as_bytes(NOTIFICATION_THUMBNAIL)
        var thumb_file := FileAccess.open(res_dir.path_join("khvataika_notification.png"), FileAccess.WRITE)
        if thumb_file:
            thumb_file.store_buffer(thumb)
            thumb_file.close()
    var java_dir := java_path.get_base_dir()
    DirAccess.make_dir_recursive_absolute(java_dir)
    var java_file := FileAccess.open(java_path, FileAccess.WRITE)
    if java_file:
        java_file.store_string(source)
        java_file.close()
    var mf := FileAccess.open(manifest_path, FileAccess.READ)
    if not mf:
        return false
    var manifest := mf.get_as_text()
    mf.close()
    var changed := false
    var open_end := manifest.find(">")
    if "android.permission.INTERNET" not in manifest and open_end >= 0:
        manifest = manifest.insert(open_end + 1, "\n    <uses-permission android:name=\"android.permission.INTERNET\" />")
        changed = true
    if "android.permission.RECEIVE_BOOT_COMPLETED" not in manifest and open_end >= 0:
        manifest = manifest.insert(open_end + 1, "\n    <uses-permission android:name=\"android.permission.RECEIVE_BOOT_COMPLETED\" />")
        changed = true
    if "android.permission.SCHEDULE_EXACT_ALARM" not in manifest:
        open_end = manifest.find(">")
        if open_end >= 0:
            manifest = manifest.insert(open_end + 1, "\n    <uses-permission android:name=\"android.permission.SCHEDULE_EXACT_ALARM\" />")
            changed = true
    if "KhvataikaAlarmReceiver" not in manifest:
        var receiver := "\n        <receiver\n            android:name=\"com.clawneon.khvataika.KhvataikaAlarmReceiver\"\n            android:enabled=\"true\"\n            android:exported=\"false\">\n            <intent-filter>\n                <action android:name=\"android.intent.action.BOOT_COMPLETED\" />\n                <action android:name=\"android.intent.action.MY_PACKAGE_REPLACED\" />\n            </intent-filter>\n        </receiver>\n"
        var pos := manifest.rfind("</application>")
        if pos >= 0:
            manifest = manifest.insert(pos, receiver)
            changed = true
    if changed:
        var out := FileAccess.open(manifest_path, FileAccess.WRITE)
        if out:
            out.store_string(manifest)
            out.close()
    return true
