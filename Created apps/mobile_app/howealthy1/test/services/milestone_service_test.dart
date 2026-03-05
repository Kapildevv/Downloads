import 'package:flutter_test/flutter_test.dart';
import 'package:howealthy1/services/milestone_service.dart';

void main() {
  group('MilestoneService Tests', () {
    test('checkNetWorthMilestones detects correct thresholds', () {
      final achieved = <String>{};

      // Test below first threshold
      var milestones =
          MilestoneService.checkNetWorthMilestones(50000, achieved);
      expect(milestones, isEmpty);

      // Test crossing ₹1 Lakh
      milestones = MilestoneService.checkNetWorthMilestones(150000, achieved);
      expect(milestones.length, 1);
      expect(milestones.first.type, MilestoneType.netWorth1L);
      expect(milestones.first.formattedValue, '₹1.0 L');

      // Add to achieved and test crossing ₹10 Lakh (skipping 5L)
      achieved.add(MilestoneType.netWorth1L.name);
      milestones = MilestoneService.checkNetWorthMilestones(1200000, achieved);

      // Should detect both 5L and 10L since they aren't in `achieved` yet
      expect(milestones.length, 2);
      expect(
          milestones.map((m) => m.type),
          containsAll([
            MilestoneType.netWorth5L,
            MilestoneType.netWorth10L,
          ]));
    });

    test('checkStreakMilestone detects 30-day streak', () {
      final achieved = <String>{};

      var streak = MilestoneService.checkStreakMilestone(29, achieved);
      expect(streak, isNull);

      streak = MilestoneService.checkStreakMilestone(30, achieved);
      expect(streak, isNotNull);
      expect(streak!.type, MilestoneType.streak30);
      expect(streak.formattedValue, '30 days');

      // Test when already achieved
      achieved.add(MilestoneType.streak30.name);
      streak = MilestoneService.checkStreakMilestone(35, achieved);
      expect(streak, isNull);
    });

    test('generateShareMessage formats text correctly', () {
      final milestone = Milestone(
        type: MilestoneType.netWorth1Cr,
        value: 10000000,
        achievedAt: DateTime(2026, 3, 1),
        formattedValue: '₹1.0 Cr',
      );

      final message =
          MilestoneService.generateShareMessage(milestone, 'https://link');

      expect(message, contains('🏅'));
      expect(message, contains('CROREPATI!'));
      expect(message, contains('1 Mar 2026'));
      expect(message, contains('https://link'));
      expect(message, contains('#HoWealthy'));
    });
  });
}
