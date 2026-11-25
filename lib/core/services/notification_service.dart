/// Schedules system notifications, so alarms, timers and reminders still alert
/// the user when the app is in the background or closed.
///
/// Ids are chosen by the callers (each tool owns a range) so a notification
/// can be replaced or cancelled later.
abstract class NotificationService {
  /// Prepares the platform plugin. Safe to call more than once.
  Future<void> init();

  /// Asks the user for permission to show notifications. Returns whether it
  /// was granted. Call it when the user first creates something that alerts,
  /// not at launch.
  Future<bool> requestPermission();

  /// Whether notifications are currently allowed.
  Future<bool> isPermitted();

  /// Shows a notification at [at]. When [repeatsWeekly] is true it repeats
  /// every week on the same weekday and wall-clock time.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    String? body,
    bool repeatsWeekly = false,
  });

  /// Removes the pending notification with [id] and any shown one.
  Future<void> cancel(int id);
}

/// A scheduled notification as recorded by [InMemoryNotificationService].
class RecordedNotification {
  const RecordedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.repeatsWeekly,
  });

  final int id;
  final DateTime at;
  final String title;
  final String? body;
  final bool repeatsWeekly;
}

/// Keeps notifications in memory instead of showing them. Used in tests and
/// anywhere the platform plugin is unavailable.
class InMemoryNotificationService implements NotificationService {
  InMemoryNotificationService({this.permitted = true});

  /// What [isPermitted] and [requestPermission] report.
  bool permitted;

  final Map<int, RecordedNotification> scheduled = {};
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permitted;
  }

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    String? body,
    bool repeatsWeekly = false,
  }) async {
    scheduled[id] = RecordedNotification(
      id: id,
      at: at,
      title: title,
      body: body,
      repeatsWeekly: repeatsWeekly,
    );
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }
}
