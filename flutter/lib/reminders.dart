import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'store.dart';

abstract class ReminderEngine {
  Future<bool> prepare({required bool requestPermission});

  Future<void> schedule(int hour, int minute);
  Future<void> cancel();
}

class LocalReminderEngine implements ReminderEngine {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const id = 1001;

  @override
  Future<bool> prepare({required bool requestPermission}) async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      throw UnsupportedError('Lembretes disponíveis em Android e iOS.');
    }
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    if (!_initialized) {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!;
      if (requestPermission) {
        return await android.requestNotificationsPermission() ?? false;
      }
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()!;
    if (requestPermission) {
      return await ios.requestPermissions(
            alert: true,
            sound: true,
            badge: false,
          ) ??
          false;
    }
    final permissions = await ios.checkPermissions();
    return permissions?.isAlertEnabled ?? false;
  }

  static tz.TZDateTime nextTime(tz.TZDateTime now, int hour, int minute) {
    var next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    return next;
  }

  @override
  Future<void> schedule(int hour, int minute) => plugin.zonedSchedule(
    id: id,
    title: 'Hora da sua leitura',
    body: 'Reserve um momento para ler a Bíblia hoje.',
    scheduledDate: nextTime(tz.TZDateTime.now(tz.local), hour, minute),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reading',
        'Lembrete de leitura',
        channelDescription: 'Seu lembrete diário para ler a Bíblia',
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
  @override
  Future<void> cancel() => plugin.cancel(id: id);
}

class ReminderService {
  ReminderService({required this.engine});
  static final i = ReminderService(engine: LocalReminderEngine());
  final ReminderEngine engine;
  final ValueNotifier<String?> error = ValueNotifier(null);
  bool _busy = false;

  bool enabled(AppState state) =>
      state.prefs.getBool('reminder_enabled') ?? false;
  int hour(AppState state) =>
      (state.prefs.getInt('reminder_hour') ?? 8).clamp(0, 23);
  int minute(AppState state) =>
      (state.prefs.getInt('reminder_minute') ?? 0).clamp(0, 59);

  Future<void> restore(AppState state) async {
    if (!enabled(state) || _busy) {
      return;
    }
    try {
      if (!await engine.prepare(requestPermission: false)) {
        throw StateError(
          'Autorize as notificações nas configurações do aparelho.',
        );
      }
      await engine.schedule(hour(state), minute(state));
      error.value = null;
    } catch (_) {
      error.value = 'O lembrete não está ativo. Verifique as permissões do aparelho e tente ativá-lo novamente.';
    }
  }

  Future<void> configure(
    AppState state, {
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (!state.storageAvailable) {
      throw StateError('Armazenamento indisponível.');
    }
    if (_busy) throw StateError('Aguarde a atualização do lembrete.');
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Horário inválido.');
    }
    _busy = true;
    final oldEnabled = this.enabled(state);
    final oldHour = this.hour(state);
    final oldMinute = this.minute(state);
    try {
      if (enabled) {
        if (!await engine.prepare(requestPermission: true)) {
          throw StateError('Permissão de notificações não concedida.');
        }
        await engine.schedule(hour, minute);
      } else {
        await engine.cancel();
      }
      if (!await state.prefs.setInt('reminder_hour', hour) ||
          !await state.prefs.setInt('reminder_minute', minute) ||
          !await state.prefs.setBool('reminder_enabled', enabled)) {
        throw StateError('Não foi possível salvar o lembrete.');
      }
      error.value = null;
      state.preferencesChanged();
    } catch (e) {
      await state.prefs.setInt('reminder_hour', oldHour);
      await state.prefs.setInt('reminder_minute', oldMinute);
      await state.prefs.setBool('reminder_enabled', oldEnabled);
      try {
        if (oldEnabled && await engine.prepare(requestPermission: false)) {
          await engine.schedule(oldHour, oldMinute);
        } else {
          await engine.cancel();
        }
      } catch (_) {
        /* A interface mostra a falha de agendamento. */
      }
      error.value = e.toString();
      rethrow;
    } finally {
      _busy = false;
    }
  }
}
