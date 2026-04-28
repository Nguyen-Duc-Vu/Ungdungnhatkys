import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/diary_entry.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _idDailyReminder = 0;
  static const _idOnThisDay     = 1;
  static const _prefKeyLastShown = 'on_this_day_last_shown';

  // ── Init + xin permission ─────────────────────────────────────────────────

  static Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;

    await Permission.notification.request();

    final exactAlarm = await Permission.scheduleExactAlarm.status;
    if (!exactAlarm.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // ── Nhắc viết nhật ký tại ngày + giờ cụ thể ─────────────────────────────
  // ✅ Thay scheduleDailyReminder(hour, minute) → scheduleReminder(dateTime)
  static Future<void> scheduleReminder({required DateTime dateTime}) async {
    if (kIsWeb) return;

    await requestPermissions();
    await _plugin.cancel(_idDailyReminder);

    final scheduled = tz.TZDateTime.from(dateTime, tz.local);

    // Nếu thời gian đã qua thì không schedule (tránh lỗi)
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _plugin.zonedSchedule(
      _idDailyReminder,
      '📔 Nhật ký hôm nay',
      'Đừng quên ghi lại những khoảnh khắc của ngày hôm nay nhé!',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Nhắc nhở viết nhật ký',
          channelDescription: 'Nhắc nhở để viết nhật ký',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      // ✅ Không dùng matchDateTimeComponents → nhắc đúng 1 lần tại ngày+giờ cụ thể
      // Nếu muốn lặp lại hàng ngày cùng giờ, bật lại: matchDateTimeComponents: DateTimeComponents.time
    );
  }

  // ── Giữ lại hàm cũ để tương thích (gọi scheduleReminder bên trong) ───────
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, hour, minute);
    if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1));
    await scheduleReminder(dateTime: dt);
  }

  // ── Nhắc "Ký ức hôm nay" ─────────────────────────────────────────────────

  static Future<void> scheduleOnThisDay(List<DiaryEntry> entries) async {
    if (kIsWeb) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefKeyLastShown);
    if (lastShown == todayKey) return;

    DiaryEntry? memory;
    String memoryLabel = '';

    for (final e in entries) {
      final diffYears = now.year - e.date.year;
      final sameMonth = e.date.month == now.month;
      final sameDay   = e.date.day == now.day;

      if (diffYears >= 1 && sameMonth && sameDay) {
        if (memory == null || diffYears < (now.year - memory.date.year)) {
          memory = e;
          memoryLabel = diffYears == 1 ? '1 năm trước' : '$diffYears năm trước';
        }
      } else if (diffYears == 0 &&
          now.month - e.date.month == 1 &&
          sameDay &&
          memory == null) {
        memory = e;
        memoryLabel = '1 tháng trước';
      }
    }

    if (memory == null) {
      await _plugin.cancel(_idOnThisDay);
      return;
    }

    final excerpt = memory.content.isNotEmpty
        ? (memory.content.length > 80
        ? '${memory.content.substring(0, 80)}...'
        : memory.content)
        : 'Bạn đã ghi lại khoảnh khắc này $memoryLabel.';

    final bigBody = '${memory.mood}  ${memory.title}\n\n"$excerpt"';

    final morning8 = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 8, 0);
    final fireTime = morning8.isBefore(tz.TZDateTime.now(tz.local))
        ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3))
        : morning8;

    await _plugin.zonedSchedule(
      _idOnThisDay,
      '🕰️ Ký ức $memoryLabel',
      '${memory.mood} ${memory.title}',
      fireTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'on_this_day',
          'Ký ức hôm nay',
          channelDescription: 'Nhắc nhở về nhật ký trong quá khứ',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          styleInformation: BigTextStyleInformation(
            bigBody,
            contentTitle: '🕰️ Ký ức $memoryLabel',
            summaryText: 'Nhật ký của bạn',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
          subtitle: 'Ngày này trong quá khứ...',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    await prefs.setString(_prefKeyLastShown, todayKey);
  }

  // ── Test notification ngay lập tức ───────────────────────────────────────
  static Future<void> sendTestNotification() async {
    if (kIsWeb) return;
    await requestPermissions();
    await _plugin.show(
      99,
      '✅ Test thông báo',
      'Nếu bạn thấy cái này thì notification đang hoạt động!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test',
          channelDescription: 'Test notification',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  static Future<void> resetOnThisDayForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyLastShown);
  }
}