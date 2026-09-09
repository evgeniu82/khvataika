package com.clawneon.khvataika;

import android.app.AlarmManager;
import android.content.BroadcastReceiver;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Calendar;
import java.util.Map;

public class KhvataikaAlarmReceiver extends BroadcastReceiver {

    public static final String CHANNEL_ID = "khvataika_game";
    private static final String PREFS = "khvataika_background_notifications";
    private static final String KEY_PREFIX = "notification_";
    private static final int SERVER_POLL_ID = 1199;

    private static final String KEY_SERVER_URL = "server_url";
    private static final String KEY_PLAYER_ID = "player_id";
    private static final String KEY_PLAYER_TOKEN = "player_token";
    private static final String KEY_CURSOR = "server_cursor";

    @Override
    public void onReceive(Context context, Intent intent) {

        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())
                || Intent.ACTION_MY_PACKAGE_REPLACED.equals(intent.getAction())) {

            scheduleServerPoll(context);
            rescheduleAll(context);
            return;
        }

        int id = intent.getIntExtra("id", 0);

        if (id == SERVER_POLL_ID
                || "com.clawneon.khvataika.SERVER_POLL".equals(intent.getAction())) {

            pollServer(context);
            scheduleServerPoll(context);
            return;
        }

        if (id == 0) return;

        String title = intent.getStringExtra("title");
        String message = intent.getStringExtra("message");
        boolean daily = intent.getBooleanExtra("daily", false);

        if (title == null) {
            title = "Хватайка";
        }

        if (message == null) {
            message = "Зайди в игру — тебя ждёт награда!";
        }

        postNotification(context, id, title, message);

        if (daily) {

            SharedPreferences prefs =
                    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);

            long next =
                    prefs.getLong(
                            KEY_PREFIX + id + "trigger",
                            System.currentTimeMillis()
                    ) + 86400000L;

            while (next <= System.currentTimeMillis()) {
                next += 86400000L;
            }

            prefs.edit()
                    .putLong(KEY_PREFIX + id + "trigger", next)
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

        if (context == null || serverUrl == null || playerId == null) {
            return;
        }

        context.getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
        ).edit()
                .putString(KEY_SERVER_URL, serverUrl)
                .putString(KEY_PLAYER_ID, playerId)
                .putString(
                        KEY_PLAYER_TOKEN,
                        playerToken == null ? "" : playerToken
                )
                .apply();

        scheduleServerPoll(context);
    }

    public static void scheduleServerPoll(Context context) {

        if (context == null) return;

        AlarmManager am =
                (AlarmManager) context.getSystemService(
                        Context.ALARM_SERVICE
                );

        if (am == null) return;

        long when =
                System.currentTimeMillis()
                        + 15 * 60 * 1000L;

        PendingIntent pi =
                serverPollIntent(context, true);

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

        i.putExtra("id", SERVER_POLL_ID);

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

    private static void pollServer(final Context context) {

        final SharedPreferences prefs =
                context.getSharedPreferences(
                        PREFS,
                        Context.MODE_PRIVATE
                );

        final String base =
                prefs.getString(KEY_SERVER_URL, "");

        final String player =
                prefs.getString(KEY_PLAYER_ID, "");

        final String token =
                prefs.getString(KEY_PLAYER_TOKEN, "");

        if (base.isEmpty()
                || player.isEmpty()
                || token.isEmpty()) {
            return;
        }

        new Thread(() -> {

            HttpURLConnection c = null;

            try {

                String url =
                        base.replaceAll("/$", "")
                                + "/api/notifications/poll?player_id="
                                + enc(player)
                                + "&cursor="
                                + prefs.getLong(KEY_CURSOR, 0L);

                c =
                        (HttpURLConnection)
                                new URL(url).openConnection();

                c.setRequestMethod("GET");

                c.setRequestProperty(
                        "Authorization",
                        "Bearer " + token
                );

                c.setConnectTimeout(5000);
                c.setReadTimeout(7000);

                int code = c.getResponseCode();

                if (code < 200 || code >= 300) {
                    return;
                }

                String text =
                        read(c.getInputStream());

                JSONObject root =
                        new JSONObject(text);

                JSONArray items =
                        root.optJSONArray("notifications");

                long cursor =
                        root.optLong(
                                "next_cursor",
                                prefs.getLong(
                                        KEY_CURSOR,
                                        0L
                                )
                        );

                if (items != null) {

                    for (int i = 0;
                         i < items.length();
                         i++) {

                        JSONObject n =
                                items.optJSONObject(i);

                        if (n == null) continue;

                        postNotification(
                                context,
                                n.optInt(
                                        "id",
                                        (int)
                                                (System.currentTimeMillis()
                                                        / 1000)
                                ),
                                n.optString(
                                        "title",
                                        "Хватайка"
                                ),
                                n.optString(
                                        "message",
                                        "Зайди в игру!"
                                )
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

        }).start();
    }

    private static String enc(String x) {

        try {
            return java.net.URLEncoder.encode(
                    x,
                    "UTF-8"
            );
        } catch (Exception e) {
            return x;
        }
    }

    private static String read(InputStream in)
            throws Exception {

        BufferedReader r =
                new BufferedReader(
                        new InputStreamReader(
                                in,
                                "UTF-8"
                        )
                );

        StringBuilder b =
                new StringBuilder();

        String line;

        while ((line = r.readLine()) != null) {
            b.append(line);
        }

        r.close();

        return b.toString();
    }

    public static void schedule(
            Context context,
            long timestampMs,
            int id,
            String title,
            String message,
            boolean daily
    ) {

        if (context == null) return;

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

        if (context == null) return;

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

    public static void cancelAll(Context context) {

        if (context == null) return;

        SharedPreferences p =
                context.getSharedPreferences(
                        PREFS,
                        Context.MODE_PRIVATE
                );

        for (Map.Entry<String, ?> e :
                p.getAll().entrySet()) {

            String k = e.getKey();

            if (k.startsWith(KEY_PREFIX)
                    && !k.endsWith("title")
                    && !k.endsWith("message")
                    && !k.endsWith("daily")
                    && !k.endsWith("trigger")) {

                try {

                    cancel(
                            context,
                            Integer.parseInt(
                                    k.substring(
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

        if (context != null) {
            postNotification(
                    context,
                    id,
                    title,
                    message
            );
        }
    }

    private static void scheduleInternal(
            Context context,
            long t,
            int id,
            String title,
            String message,
            boolean daily
    ) {

        AlarmManager am =
                (AlarmManager)
                        context.getSystemService(
                                Context.ALARM_SERVICE
                        );

        if (am == null) return;

        PendingIntent p =
                pendingIntent(
                        context,
                        id,
                        true,
                        title,
                        message,
                        daily
                );

        if (p == null) return;

        am.cancel(p);

        if (Build.VERSION.SDK_INT >= 31
                && am.canScheduleExactAlarms()) {

            am.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    t,
                    p
            );

        } else if (Build.VERSION.SDK_INT >= 23) {

            am.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    t,
                    p
            );

        } else {

            am.set(
                    AlarmManager.RTC_WAKEUP,
                    t,
                    p
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
                "com.clawneon.khvataika.NOTIFY_" + id
        );

        i.putExtra("id", id);

        if (title != null) {
            i.putExtra("title", title);
        }

        if (message != null) {
            i.putExtra("message", message);
        }

        i.putExtra("daily", daily);

        int flags =
                PendingIntent.FLAG_IMMUTABLE
                        | (update
                        ? PendingIntent.FLAG_UPDATE_CURRENT
                        : PendingIntent.FLAG_NO_CREATE);

        return PendingIntent.getBroadcast(
                context,
                id,
                i,
                flags
        );
    }

    private static void rescheduleAll(
            Context context
    ) {

        SharedPreferences p =
                context.getSharedPreferences(
                        PREFS,
                        Context.MODE_PRIVATE
                );

        for (Map.Entry<String, ?> e :
                p.getAll().entrySet()) {

            String k = e.getKey();

            if (!k.startsWith(KEY_PREFIX)
                    || k.endsWith("title")
                    || k.endsWith("message")
                    || k.endsWith("daily")
                    || k.endsWith("trigger")) {
                continue;
            }

            try {

                int id =
                        Integer.parseInt(
                                k.substring(
                                        KEY_PREFIX.length()
                                )
                        );

                long t =
                        p.getLong(k, 0);

                String title =
                        p.getString(
                                KEY_PREFIX + id + "title",
                                "Хватайка"
                        );

                String msg =
                        p.getString(
                                KEY_PREFIX + id + "message",
                                "Зайди в игру — тебя ждёт награда!"
                        );

                boolean daily =
                        p.getBoolean(
                                KEY_PREFIX + id + "daily",
                                false
                        );

                if (daily) {
                    while (t <= System.currentTimeMillis()) {
                        t += 86400000L;
                    }
                }

                if (t > System.currentTimeMillis()) {

                    scheduleInternal(
                            context,
                            t,
                            id,
                            title,
                            msg,
                            daily
                    );
                }

            } catch (Exception ignored) {
            }
        }
    }

    private static void postNotification(
            Context context,
            int id,
            String title,
            String message
    ) {

        NotificationManager m =
                (NotificationManager)
                        context.getSystemService(
                                Context.NOTIFICATION_SERVICE
                        );

        if (m == null) return;

        if (Build.VERSION.SDK_INT >= 26) {

            NotificationChannel ch =
                    new NotificationChannel(
                            CHANNEL_ID,
                            "Хватайка",
                            NotificationManager.IMPORTANCE_DEFAULT
                    );

            ch.setDescription(
                    "Серверные уведомления игры"
            );

            m.createNotification
