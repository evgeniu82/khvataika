package com.clawneon.khvataika;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.provider.Settings;
import android.os.Build;

import java.util.Calendar;
import java.util.Map;

/**
 * Receives AlarmManager broadcasts after the Godot process has been killed.
 * No Godot runtime is required when the alarm fires.
 */
public class KhvataikaAlarmReceiver extends BroadcastReceiver {
    public static final String CHANNEL_ID = "khvataika_game";
    private static final String PREFS = "khvataika_background_notifications";
    private static final String KEY_PREFIX = "notification_";
    private static final String EXTRA_ID = "id";
    private static final String EXTRA_TITLE = "title";
    private static final String EXTRA_MESSAGE = "message";
    private static final String EXTRA_DAILY = "daily";
    private static final String EXTRA_TRIGGER = "trigger";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction()) ||
                Intent.ACTION_MY_PACKAGE_REPLACED.equals(intent.getAction())) {
            rescheduleAll(context);
            return;
        }

        int id = intent.getIntExtra(EXTRA_ID, 0);
        if (id == 0) {
            return;
        }
        String title = intent.getStringExtra(EXTRA_TITLE);
        String message = intent.getStringExtra(EXTRA_MESSAGE);
        boolean daily = intent.getBooleanExtra(EXTRA_DAILY, false);
        if (title == null) title = "Хватайка";
        if (message == null) message = "Зайди в игру — тебя ждёт награда!";

        postNotification(context, id, title, message);

        if (daily) {
            SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
            long previous = prefs.getLong(KEY_PREFIX + id + EXTRA_TRIGGER, System.currentTimeMillis());
            long next = previous + 86400000L;
            while (next <= System.currentTimeMillis()) next += 86400000L;
            prefs.edit().putLong(KEY_PREFIX + id + EXTRA_TRIGGER, next).apply();
            scheduleInternal(context, next, id, title, message, true, false);
        } else {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    .remove(KEY_PREFIX + id).remove(KEY_PREFIX + id + EXTRA_TITLE)
                    .remove(KEY_PREFIX + id + EXTRA_MESSAGE).remove(KEY_PREFIX + id + EXTRA_DAILY)
                    .remove(KEY_PREFIX + id + EXTRA_TRIGGER).apply();
        }
    }

    public static void schedule(Context context, long timestampMs, int id, String title, String message, boolean daily) {
        if (context == null) return;
        SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        prefs.edit()
                .putLong(KEY_PREFIX + id, timestampMs)
                .putString(KEY_PREFIX + id + EXTRA_TITLE, title)
                .putString(KEY_PREFIX + id + EXTRA_MESSAGE, message)
                .putBoolean(KEY_PREFIX + id + EXTRA_DAILY, daily)
                .putLong(KEY_PREFIX + id + EXTRA_TRIGGER, timestampMs)
                .apply();
        scheduleInternal(context, timestampMs, id, title, message, daily, true);
    }

    public static void cancel(Context context, int id) {
        if (context == null) return;
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager != null) {
            PendingIntent pending = pendingIntent(context, id, false);
            if (pending != null) alarmManager.cancel(pending);
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .remove(KEY_PREFIX + id).remove(KEY_PREFIX + id + EXTRA_TITLE)
                .remove(KEY_PREFIX + id + EXTRA_MESSAGE).remove(KEY_PREFIX + id + EXTRA_DAILY)
                .remove(KEY_PREFIX + id + EXTRA_TRIGGER).apply();
    }

    public static void cancelAll(Context context) {
        if (context == null) return;
        SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        for (Map.Entry<String, ?> entry : prefs.getAll().entrySet()) {
            String key = entry.getKey();
            if (key.startsWith(KEY_PREFIX) && !key.endsWith(EXTRA_TITLE) &&
                    !key.endsWith(EXTRA_MESSAGE) && !key.endsWith(EXTRA_DAILY) && !key.endsWith(EXTRA_TRIGGER)) {
                try { cancel(context, Integer.parseInt(key.substring(KEY_PREFIX.length()))); } catch (Exception ignored) { }
            }
        }
    }

    public static void postNow(Context context, String title, String message, int id) {
        if (context == null) return;
        postNotification(context, id, title, message);
    }

    private static void scheduleInternal(Context context, long timestampMs, int id, String title,
                                         String message, boolean daily, boolean replace) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) return;
        PendingIntent pending = pendingIntent(context, id, true, title, message, daily);
        if (pending == null) return;
        alarmManager.cancel(pending);
        // Prefer an exact wake-up when Android grants exact-alarm access.
        // On devices where that special access is unavailable, use the more
        // widely permitted allow-while-idle alarm instead of failing.
        if (Build.VERSION.SDK_INT >= 31 && alarmManager.canScheduleExactAlarms()) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestampMs, pending);
        } else if (Build.VERSION.SDK_INT >= 23) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestampMs, pending);
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, timestampMs, pending);
        }
    }

    private static PendingIntent pendingIntent(Context context, int id, boolean update) {
        return pendingIntent(context, id, update, null, null, false);
    }

    private static PendingIntent pendingIntent(Context context, int id, boolean update,
                                               String title, String message, boolean daily) {
        Intent intent = new Intent(context, KhvataikaAlarmReceiver.class);
        intent.setAction("com.clawneon.khvataika.NOTIFY_" + id);
        intent.putExtra(EXTRA_ID, id);
        if (title != null) intent.putExtra(EXTRA_TITLE, title);
        if (message != null) intent.putExtra(EXTRA_MESSAGE, message);
        intent.putExtra(EXTRA_DAILY, daily);
        int flags = PendingIntent.FLAG_IMMUTABLE;
        if (update) flags |= PendingIntent.FLAG_UPDATE_CURRENT;
        else flags |= PendingIntent.FLAG_NO_CREATE;
        return PendingIntent.getBroadcast(context, id, intent, flags);
    }

    private static void rescheduleAll(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        for (Map.Entry<String, ?> entry : prefs.getAll().entrySet()) {
            String key = entry.getKey();
            if (!key.startsWith(KEY_PREFIX) || key.endsWith(EXTRA_TITLE) || key.endsWith(EXTRA_MESSAGE) ||
                    key.endsWith(EXTRA_DAILY) || key.endsWith(EXTRA_TRIGGER)) continue;
            try {
                int id = Integer.parseInt(key.substring(KEY_PREFIX.length()));
                long trigger = prefs.getLong(key, 0L);
                String title = prefs.getString(KEY_PREFIX + id + EXTRA_TITLE, "Хватайка");
                String message = prefs.getString(KEY_PREFIX + id + EXTRA_MESSAGE, "Зайди в игру — тебя ждёт награда!");
                boolean daily = prefs.getBoolean(KEY_PREFIX + id + EXTRA_DAILY, false);
                if (daily) {
                    while (trigger <= System.currentTimeMillis()) trigger += 86400000L;
                }
                if (trigger > System.currentTimeMillis()) scheduleInternal(context, trigger, id, title, message, daily, true);
            } catch (Exception ignored) { }
        }
    }

    private static long nextDay(long fromMs) {
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeInMillis(fromMs);
        calendar.add(Calendar.DAY_OF_YEAR, 1);
        return calendar.getTimeInMillis();
    }

    private static void postNotification(Context context, int id, String title, String message) {
        NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) return;
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Хватайка", NotificationManager.IMPORTANCE_DEFAULT);
            channel.setDescription("Полезные уведомления игры: ежедневные награды и события");
            manager.createNotificationChannel(channel);
        }
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission("android.permission.POST_NOTIFICATIONS") != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        if (Build.VERSION.SDK_INT >= 24 && !manager.areNotificationsEnabled()) {
            return;
        }
        Notification.Builder builder = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(context, CHANNEL_ID)
                : new Notification.Builder(context);
        builder.setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(new Notification.BigTextStyle().bigText(message))
                .setAutoCancel(true)
                .setCategory(Notification.CATEGORY_GAME)
                .setPriority(Notification.PRIORITY_DEFAULT);
        Intent launch = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            PendingIntent click = PendingIntent.getActivity(context, id + 500000, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            builder.setContentIntent(click);
        }
        manager.notify(id, builder.build());
    }
}
