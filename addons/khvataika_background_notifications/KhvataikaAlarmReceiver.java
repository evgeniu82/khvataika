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
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Map;

public class KhvataikaAlarmReceiver extends BroadcastReceiver {

    public static final String CHANNEL_ID = "khvataika_game";

    private static final String PREFS =
            "khvataika_background_notifications";

    private static final String KEY_PREFIX =
            "notification_";

    private static final int SERVER_POLL_ID = 1199;

    private static final String KEY_SERVER_URL =
            "server_url";

    private static final String KEY_PLAYER_ID =
            "player_id";

    private static final String KEY_PLAYER_TOKEN =
            "player_token";

    private static final String KEY_CURSOR =
            "server_cursor";

    @Override
    public void onReceive(
            Context context,
            Intent intent
    ) {

        if (context == null || intent == null) {
            return;
        }

        String action = intent.getAction();

        if (Intent.ACTION_BOOT_COMPLETED.equals(action)
                || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action)) {

            scheduleServerPoll(context);
            rescheduleAll(context);
            return;
        }

        int id = intent.getIntExtra("id", 0);

        if (id == SERVER_POLL_ID
                || "com.clawneon.khvataika.SERVER_POLL".equals(action)) {

            pollServer(context);
            scheduleServerPoll(context);
            return;
        }

        if (id == 0) {
            return;
        }

        String title =
                intent.getStringExtra("title");

        String message =
                intent.getStringExtra("message");

        boolean daily =
                intent.getBooleanExtra("daily", false);

        if (title == null || title.isEmpty()) {
            title = "Хватайка";
        }

        if (message == null || message.isEmpty()) {
            message =
                    "Зайди в игру — тебя ждёт награда!";
        }

        postNotification(
                context,
                id,
                title,
                message
        );

        if (daily) {

            SharedPreferences prefs =
                    context.getSharedPreferences(
                            PREFS,
                            Context.MODE_PRIVATE
                    );

            long next =
                    prefs.getLong(
                            KEY_PREFIX + id + "trigger",
                            System.currentTimeMillis()
                    );

            next += 86400000L;

            while (next <= System.currentTimeMillis()) {
                next += 86400000L;
            }

            prefs.edit()
                    .putLong(
                            KEY_PREFIX + id + "trigger",
                            next
                    )
                    .apply();

            scheduleInternal(
                    context,
                    next,
                    id,
                    title,
                    message,
                    true
            );

        } else {

            context.getSharedPreferences(
                    PREFS,
                    Context.MODE_PRIVATE
            )
                    .edit()
                    .remove(KEY_PREFIX + id)
                    .remove(KEY_PREFIX + id + "title")
                    .remove(KEY_PREFIX + id + "message")
                    .remove(KEY_PREFIX + id + "daily")
                    .remove(KEY_PREFIX + id + "trigger")
                    .apply();
        }
    }

    public static void registerServer(
            Context context,
            String serverUrl,
            String playerId,
            String playerToken
    ) {

        if (context == null
                || serverUrl == null
                || playerId == null) {
            return;
        }

        context.getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
        )
                .edit()
                .putString(
                        KEY_SERVER_URL,
                        serverUrl
                )
                .putString(
                        KEY_PLAYER_ID,
                        playerId
                )
                .putString(
                        KEY_PLAYER_TOKEN,
                        playerToken == null
                                ? ""
                                : playerToken
                )
                .apply();

        scheduleServerPoll(context);
    }

    public static void scheduleServerPoll(
            Context context
    ) {

        if (context == null) {
            return;
        }

        AlarmManager alarmManager =
                (AlarmManager)
                        context.getSystemService(
                                Context.ALARM_SERVICE
                        );

        if (alarmManager == null) {
            return;
        }

        long when =
                System.currentTimeMillis()
                        + 15L * 60L * 1000L;

        PendingIntent pendingIntent =
                serverPollIntent(
                        context,
                        true
                );

        if (Build.VERSION.SDK_INT >= 23) {

            alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    when,
                    pendingIntent
            );

        } else {

            alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    when,
                    pendingIntent
            );
        }
    }

    private static PendingIntent serverPollIntent(
            Context context,
            boolean update
    ) {

        Intent intent =
                new Intent(
                        context,
                        KhvataikaAlarmReceiver.class
                );

        intent.setAction(
                "com.clawneon.khvataika.SERVER_POLL"
        );

        intent.putExtra(
                "id",
                SERVER_POLL_ID
        );

        int flags =
                PendingIntent.FLAG_IMMUTABLE;

        if (update) {
            flags |=
                    PendingIntent.FLAG_UPDATE_CURRENT;
        } else {
            flags |=
                    PendingIntent.FLAG_NO_CREATE;
        }

        return PendingIntent.getBroadcast(
                context,
                SERVER_POLL_ID,
                intent,
                flags
        );
    }

    private static void pollServer(
            final Context context
    ) {

        final SharedPreferences prefs =
                context.getSharedPreferences(
                        PREFS,
                        Context.MODE_PRIVATE
                );

        final String serverUrl =
                prefs.getString(
                        KEY_SERVER_URL,
                        ""
                );

        final String playerId =
                prefs.getString(
                        KEY_PLAYER_ID,
                        ""
                );

        final String playerToken =
                prefs.getString(
                        KEY_PLAYER_TOKEN,
                        ""
                );

        if (serverUrl.isEmpty()
                || playerId.isEmpty()
                || playerToken.isEmpty()) {
            return;
                }
                Thread thread =
                new Thread(
                        new Runnable() {

                            @Override
                            public void run() {

                                HttpURLConnection connection =
                                        null;

                                try {

                                    String url =
                                            serverUrl
                                                    .replaceAll(
                                                            "/$",
                                                            ""
                                                    )
                                                    + "/api/notifications/poll"
                                                    + "?player_id="
                                                    + encode(playerId)
                                                    + "&cursor="
                                                    + prefs.getLong(
                                                            KEY_CURSOR,
                                                            0L
                                                    );

                                    connection =
                                            (HttpURLConnection)
                                                    new URL(url)
                                                            .openConnection();

                                    connection.setRequestMethod(
                                            "GET"
                                    );

                                    connection.setRequestProperty(
                                            "Authorization",
                                            "Bearer "
                                                    + playerToken
                                    );

                                    connection.setConnectTimeout(
                                            5000
                                    );

                                    connection.setReadTimeout(
                                            7000
                                    );

                                    int responseCode =
                                            connection.getResponseCode();

                                    if (responseCode < 200
                                            || responseCode >= 300) {
                                        return;
                                    }

                                    String response =
                                            read(
                                                    connection
                                                            .getInputStream()
                                            );

                                    JSONObject root =
                                            new JSONObject(
                                                    response
                                            );

                                    JSONArray notifications =
                                            root.optJSONArray(
                                                    "notifications"
                                            );

                                    long cursor =
                                            root.optLong(
                                                    "next_cursor",
                                                    prefs.getLong(
                                                            KEY_CURSOR,
                                                            0L
                                                    )
                                            );

                                    if (notifications != null) {

                                        for (
                                                int i = 0;
                                                i < notifications.length();
                                                i++
                                        ) {

                                            JSONObject notification =
                                                    notifications
                                                            .optJSONObject(i);

                                            if (notification == null) {
                                                continue;
                                            }

                                            int notificationId =
                                                    notification.optInt(
                                                            "id",
                                                            (int)
                                                                    (System.currentTimeMillis()
                                                                            / 1000L)
                                                    );

                                            String title =
                                                    notification.optString(
                                                            "title",
                                                            "Хватайка"
                                                    );

                                            String message =
                                                    notification.optString(
                                                            "message",
                                                            "Зайди в игру!"
                                                    );

                                            postNotification(
                                                    context,
                                                    notificationId,
                                                    title,
                                                    message
                                            );

                                            cursor =
                                                    Math.max(
                                                            cursor,
                                                            notification.optLong(
                                                                    "id",
                                                                    cursor
                                                            )
                                                    );
                                        }
                                    }

                                    prefs.edit()
                                            .putLong(
                                                    KEY_CURSOR,
                                                    cursor
                                            )
                                            .apply();

                                } catch (Exception ignored) {

                                } finally {

                                    if (connection != null) {
                                        connection.disconnect();
                                    }
                                }
                            }
                        }
                );

        thread.start();
    }

    private static String encode(
            String value
    ) {

        try {

            return URLEncoder.encode(
                    value,
                    "UTF-8"
            );

        } catch (Exception exception) {

            return value;
        }
    }

    private static String read(
            InputStream inputStream
    ) throws Exception {

        BufferedReader reader =
                new BufferedReader(
                        new InputStreamReader(
                                inputStream,
                                "UTF-8"
                        )
                );

        StringBuilder builder =
                new StringBuilder();

        String line;

        while (
                (line = reader.readLine()) != null
        ) {

            builder.append(line);
        }

        reader.close();

        return builder.toString();
    }

    public static void schedule(
            Context context,
            long timestampMs,
            int id,
            String title,
            String message,
            boolean daily
    ) {

        if (context == null) {
            return;
        }

        context.getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
        )
                .edit()
                .putLong(
                        KEY_PREFIX + id,
                        timestampMs
                )
                .putString(
                        KEY_PREFIX + id + "title",
                        title
                )
                .putString(
                        KEY_PREFIX + id + "message",
                        message
                )
                .putBoolean(
                        KEY_PREFIX + id + "daily",
                        daily
                )
                .putLong(
                        KEY_PREFIX + id + "trigger",
                        timestampMs
                )
                .apply();

        scheduleInternal(
                context,
                timestampMs,
                id,
                title,
                message,
                daily
        );
    }

    public static void cancel(
            Context context,
            int id
    ) {

        if (context == null) {
            return;
        }

        AlarmManager alarmManager =
                (AlarmManager)
                        context.getSystemService(
                                Context.ALARM_SERVICE
                        );

        if (alarmManager != null) {

            PendingIntent pendingIntent =
                    pendingIntent(
                            context,
                            id,
                            false
                    );

            if (pendingIntent != null) {
                alarmManager.cancel(
                        pendingIntent
                );
            }
        }

        context.getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
        )
                .edit()
                .remove(KEY_PREFIX + id)
                .remove(KEY_PREFIX + id + "title")
                .remove(KEY_PREFIX + id + "message")
                .remove(KEY_PREFIX + id + "daily")
                .remove(KEY_PREFIX + id + "trigger")
                .apply();
    }

    public static void cancelAll(
            Context context
    ) {

        if (context == null) {
            return;
        }

        SharedPreferences prefs =
                context.getSharedPreferences(
                        PREFS,
                        Context.MODE_PRIVATE
                );

        for (
                Map.Entry<String, ?> entry :
                prefs.getAll().entrySet()
        ) {

            String key =
                    entry.getKey();

            if (!key.startsWith(KEY_PREFIX)) {
                continue;
            }

            if (key.endsWith("title")
                    || key.endsWith("message")
                    || key.endsWith("daily")
                    || key.endsWith("trigger")) {
                continue;
            }

            try {

                int id =
                        Integer.parseInt(
                                key.substring(
                                        KEY_PREFIX.length()
                                )
                        );

                cancel(
                        context,
                        id
                );

            } catch (Exception ignored) {
            }
        }
    }

    public static void postNow(
            Context context,
            String title,
            String message,
            int id
    ) {

        if (context == null) {
            return;
        }

        postNotification(
                context,
                id,
                title,
                message
        );
    }    private static void scheduleInternal(
            Context context,
            long timestampMs,
            int id,
            String title,
            String message,
            boolean daily
    ) {

        if (context == null) {
            return;
        }

        AlarmManager alarmManager =
                (AlarmManager)
                        context.getSystemService(
                                Context.ALARM_SERVICE
                        );

        if (alarmManager == null) {
            return;
        }

        PendingIntent pendingIntent =
                pendingIntent(
                        context,
                        id,
                        true,
                        title,
                        message,
                        daily
                );

        if (pendingIntent == null) {
            return;
        }

        alarmManager.cancel(
                pendingIntent
        );

        if (Build.VERSION.SDK_INT >= 31
                && alarmManager.canScheduleExactAlarms()) {

            alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timestampMs,
                    pendingIntent
            );

        } else if (Build.VERSION.SDK_INT >= 23) {

            alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timestampMs,
                    pendingIntent
            );

        } else {

            alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    timestampMs,
                    pendingIntent
            );
        }
    }

    private static PendingIntent pendingIntent(
            Context context,
            int id,
            boolean update
    ) {

        return pendingIntent(
                context,
                id,
                update,
                null,
                null,
                false
        );
    }

    private static PendingIntent pendingIntent(
            Context context,
            int id,
            boolean update,
            String title,
            String message,
            boolean daily
    ) {

        Intent intent =
                new Intent(
                        context,
                        KhvataikaAlarmReceiver.class
                );

        intent.setAction(
                "com.clawneon.khvataika.NOTIFY_"
                        + id
        );

        intent.putExtra(
                "id",
                id
        );

        if (title != null) {

            intent.putExtra(
                    "title",
                    title
            );
        }

        if (message != null) {

            intent.putExtra(
                    "message",
                    message
            );
        }

        intent.putExtra(
                "daily",
                daily
        );

        int flags =
                PendingIntent.FLAG_IMMUTABLE;

        if (update) {

            flags |=
                    PendingIntent.FLAG_UPDATE_CURRENT;

        } else {

            flags |=
                    PendingIntent.FLAG_NO_CREATE;
        }

        return PendingIntent.getBroadcast(
                context,
                id,
                intent,
                flags
        );
    }

    private static void rescheduleAll(
            Context context
    ) {

        if (context == null) {
            return;
        }

        SharedPreferences prefs =
                context.getSharedPreferences(
                        PREFS,
                        Context.MODE_PRIVATE
                );

        for (
                Map.Entry<String, ?> entry :
                prefs.getAll().entrySet()
        ) {

            String key =
                    entry.getKey();

            if (!key.startsWith(KEY_PREFIX)
                    || key.endsWith("title")
                    || key.endsWith("message")
                    || key.endsWith("daily")
                    || key.endsWith("trigger")) {

                continue;
            }

            try {

                int id =
                        Integer.parseInt(
                                key.substring(
                                        KEY_PREFIX.length()
                                )
                        );

                long timestamp =
                        prefs.getLong(
                                key,
                                0L
                        );

                String title =
                        prefs.getString(
                                KEY_PREFIX
                                        + id
                                        + "title",
                                "Хватайка"
                        );

                String message =
                        prefs.getString(
                                KEY_PREFIX
                                        + id
                                        + "message",
                                "Зайди в игру — тебя ждёт награда!"
                        );

                boolean daily =
                        prefs.getBoolean(
                                KEY_PREFIX
                                        + id
                                        + "daily",
                                false
                        );

                if (daily) {

                    while (
                            timestamp
                                    <= System.currentTimeMillis()
                    ) {

                        timestamp +=
                                86400000L;
                    }

                    prefs.edit()
                            .putLong(
                                    key,
                                    timestamp
                            )
                            .putLong(
                                    KEY_PREFIX
                                            + id
                                            + "trigger",
                                    timestamp
                            )
                            .apply();
                }

                if (
                        timestamp
                                > System.currentTimeMillis()
                ) {

                    scheduleInternal(
                            context,
                            timestamp,
                            id,
                            title,
                            message,
                            daily
                    );
                }

            } catch (Exception ignored) {
            }
        }
    }    private static void postNotification(
            Context context,
            int id,
            String title,
            String message
    ) {

        if (context == null) {
            return;
        }

        NotificationManager manager =
                (NotificationManager)
                        context.getSystemService(
                                Context.NOTIFICATION_SERVICE
                        );

        if (manager == null) {
            return;
        }

        if (Build.VERSION.SDK_INT >= 26) {

            NotificationChannel channel =
                    new NotificationChannel(
                            CHANNEL_ID,
                            "Хватайка",
                            NotificationManager.IMPORTANCE_DEFAULT
                    );

            channel.setDescription(
                    "Серверные уведомления игры"
            );

            manager.createNotificationChannel(
                    channel
            );
        }

        Intent launchIntent =
                context.getPackageManager()
                        .getLaunchIntentForPackage(
                                context.getPackageName()
                        );

        PendingIntent contentIntent =
                null;

        if (launchIntent != null) {

            launchIntent.addFlags(
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                            | Intent.FLAG_ACTIVITY_SINGLE_TOP
            );

            contentIntent =
                    PendingIntent.getActivity(
                            context,
                            id,
                            launchIntent,
                            PendingIntent.FLAG_IMMUTABLE
                                    | PendingIntent.FLAG_UPDATE_CURRENT
                    );
        }

        Notification.Builder builder;

        if (Build.VERSION.SDK_INT >= 26) {

            builder =
                    new Notification.Builder(
                            context,
                            CHANNEL_ID
                    );

        } else {

            builder =
                    new Notification.Builder(
                            context
                    );
        }

        builder.setContentTitle(
                title == null
                        ? "Хватайка"
                        : title
        );

        builder.setContentText(
                message == null
                        ? "Зайди в игру — тебя ждёт награда!"
                        : message
        );

        builder.setSmallIcon(
                android.R.drawable.ic_dialog_info
        );

        builder.setAutoCancel(
                true
        );

        builder.setPriority(
                Notification.PRIORITY_DEFAULT
        );

        if (contentIntent != null) {

            builder.setContentIntent(
                    contentIntent
            );
        }

        int thumbnailId =
                context.getResources()
                        .getIdentifier(
                                "khvataika_notification",
                                "drawable",
                                context.getPackageName()
                        );

        if (thumbnailId != 0) {

            Bitmap thumbnail =
                    BitmapFactory.decodeResource(
                            context.getResources(),
                            thumbnailId
                    );

            if (thumbnail != null) {

                builder.setLargeIcon(
                        thumbnail
                );
            }
        }

        manager.notify(
                id,
                builder.build()
        );
    }    }
