import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/task.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (kIsWeb) return;
    if (task.id == null || task.reminderDate == null) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(
      task.reminderDate!,
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Recordatorios de tareas',
        channelDescription: 'Avisos programados para tareas pendientes',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: task.id!,
      title: 'Tarea pendiente',
      body: task.title,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: taskId);
  }
}
