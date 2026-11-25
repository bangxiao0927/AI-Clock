import 'package:flutter/widgets.dart';

import '../di/provide.dart';
import 'feedback_service.dart';

/// Shortcuts for giving tap feedback from any widget. All of them do nothing
/// when no [FeedbackService] is provided.
extension FeedbackContext on BuildContext {
  /// Wraps [action] so the tap sound and haptic play first.
  VoidCallback tapped(VoidCallback action) => () {
    maybeRead<FeedbackService>()?.tap();
    action();
  };

  void tapFeedback() => maybeRead<FeedbackService>()?.tap();

  void toggleFeedback({required bool on}) =>
      maybeRead<FeedbackService>()?.toggle(on: on);

  void confirmFeedback() => maybeRead<FeedbackService>()?.confirm();
}
