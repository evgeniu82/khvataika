package com.clawneon.khvataika;

import android.app.AlarmManager;
import android.app.BroadcastReceiver;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
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
                || "com.clawneon.khvataika.SERVER_POLL"
                .equals(action)) {

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
                    ) + 86400000L;

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
            ).edit()
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
        ).edit()
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

        AlarmManager am =
                (AlarmManager) context.getSystemService(
                        Context.ALARM_SERVICE
                );

        if (am == null) {
            return;
        }

        long when =
                System.currentTimeMillis()
                        + 15 * 60 * 1000L;

        PendingIntent pi =
                serverPollIntent(
                        context,
                        true
                );

        if (Build.VERSION.SDK_INT >= 23) {

            am.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    when,
                    pi
            );

        } else {

            am.set(
                    AlarmManager.RTC_WAKEUP,
                    when,
                    pi
            );
        }
    }

    private static PendingIntent serverPollIntent(
            Context context,
            boolean update
    ) {

        Intent i =
                new Intent(
                        context,
                        KhvataikaAlarmReceiver.class
                );

        i.setAction(
                "com.clawneon.khvataika.SERVER_POLL"
        );

        i.putExtra(
                "id",
                SERVER_POLL_ID
        );

        int flags =
                PendingIntent.FLAG_IMMUTABLE
                        | (update
                        ? PendingIntent.FLAG_UPDATE_CURRENT
                        : PendingIntent.FLAG_NO_CREATE);

        return PendingIntent.getBroadcast(
                context,
                SERVER_POLL_ID,
                i,
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

        final String base =
                prefs.getString(
                        KEY_SERVER_URL,
                        ""
                );

        final String player =
                prefs.getString(
                        KEY_PLAYER_ID,
                        ""
                );

        final String token =
                prefs.getString(
                        KEY_PLAYER_TOKEN,
                        ""
                );

        if (base.isEmpty()
                || player.isEmpty()
                || token.isEmpty()) {
            return;
        }

        new Thread(
                () -> {

                    HttpURLConnection c = null;

                    try {

                        String url =
                                base.replaceAll(
                                        "/$",
                                        ""
                                )
                                        + "/api/notifications/poll"
                                        + "?player_id="
                                        + enc(player)
                                        + "&cursor="
                                        + prefs.getLong(
                                        KEY_CURSOR,
                                        0L
                                );

                        c =
                                (HttpURLConnection)
                                        new URL(url)
                                                .openConnection();

                        c.setRequestMethod("GET");

                        c.setRequestProperty(
                                "Authorization",
                                "Bearer " + token
                        );

                        c.setConnectTimeout(5000);
                        c.setReadTimeout(7000);

                        int code =
                                c.getResponseCode();

                        if (code < 200
                                || code >= 300) {
                            return;
                        }

                        String text =
                                read(
                                        c.getInputStream()
                                );

                        JSONObject root =
                                new JSONObject(text);

                        JSONArray items =
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

                        if (items != null) {

                            for (
                                    int i = 0;
                                    i < items.length();
                                    i++
                            ) {

                                JSONObject n =
                                        items.optJSONObject(i);

                                if (n == null) {
                                    continue;
                                }

                                int notificationId =
                                        n.optInt(
                                                "id",
                                                (int)
                                                        (System.currentTimeMillis()
                                                                / 1000)
                                        );

                                String title =
                                        n.optString(
                                                "title",
                                                "Хватайка"
                                        );

                                String message =
                                        n.optString(
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
                                                n.optLong(
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

                        if (c != null) {
                            c.disconnect();
                        }
                    }

                }
        ).start();
    }

    private static String enc(
            String value
    ) {

        try {

            return java.net.URLEncoder.encode(
                    value,
                    "UTF-8"
            );

        } catch (Exception e) {

            return value;
        }
    }

    private static String read(
            InputStream in
    ) throws Exception {

        BufferedReader reader =
                new BufferedReader(
                        new InputStreamReader(
                                in,
                                "UTF-8"
                        )
                );

        StringBuilder builder =
                new StringBuilder();

        String line;

        while (
                (line = reader.readLine())
                        != null
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
        ).edit()
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

        AlarmManager am =
                (AlarmManager)
                        context.getSystemService(
                                Context.ALARM_SERVICE
                        );

        if (am != null) {

            PendingIntent p =
                    pendingIntent(
                            context,
                            id,
                            false
                    );

            if (p != null) {
                am.cancel(p);
            }
        }

        context.getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
        ).edit()
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

            if (key.startsWith(KEY_PREFIX)
                    && !key.endsWith("title")
                    && !key.endsWith("message")
                    && !key.endsWith("daily")
                    && !key.endsWith("trigger")) {

                try {

                    cancel(
                            context,
                            Integer.parseInt(
                                    key.substring(
                                            KEY_PREFIX.length()
                                    )
                            )
                    );

                } catch (Exception ignored) {
                }
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
    }

    private static void scheduleInternal(
            Context context,
            long timestamp,
            int id,
            String title,
            String message,
            boolean daily
    ) {

        if (context == null) {
            return;
        }

        AlarmManager am =
                (AlarmManager)
                        context.getSystemService(
                                Context.ALARM_SERVICE
                        );

        if (am == null) {
            return;
        }

        PendingIntent pending =
                pendingIntent(
                        context,
                        id,
                        true,
                        title,
                        message,
                        daily
                );

        if (pending == null) {
            return;
        }

        am.cancel(pending);

        if (Build.VERSION.SDK_INT >= 31
                && am.canScheduleExactAlarms()) {

            am.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timestamp,
                    pending
            );

        } else if (Build.VERSION.SDK_INT >= 23) {

            am.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timestamp,
                    pending
            );

        } else {

            am.set(
                    AlarmManager.RTC_WAKEUP,
                    timestamp,
                    pending
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

        Intent i =
                new Intent(
                        context,
                        KhvataikaAlarmReceiver.class
                );

        i.setAction(
                "com.clawneon.khvataika.NOTIFY_"
                        + id
        );

        i.putExtra(
                "id",
                id
        );

        if (title != null) {

            i.putExtra(
                    "title",
                    title
            );
        }

        if (message != null) {

            i.putExtra(
           
