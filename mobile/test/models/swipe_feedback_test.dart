import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/enums.dart';
import 'package:kalori/models/swipe_feedback.dart';

void main() {
  test('SwipeFeedback.toJson backend alan adlarini uretir', () {
    const feedback = SwipeFeedback(
      action: FeedbackAction.begenmedim,
      reason: FeedbackReason.sevmedim,
      sessionId: 1,
    );

    final json = feedback.toJson();

    expect(json['action'], 'begenmedim');
    expect(json['reason'], 'sevmedim');
    expect(json['session_id'], 1);
  });

  test('SwipeFeedback.fromJson round-trip calisir', () {
    final json = {
      'action': 'begenmedim',
      'reason': 'cok_uzun',
      'session_id': 2,
      'missing_ingredient_id': null,
      'rating': null,
      'servings_cooked': null,
      'comment': null,
    };

    final feedback = SwipeFeedback.fromJson(json);

    expect(feedback.action, FeedbackAction.begenmedim);
    expect(feedback.reason, FeedbackReason.cokUzun);
  });
}