import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pregnancy Tracker Tests', () {
    test('Calculate gestational age correctly', () {
      // Arrange
      final lastMenstrualPeriod = DateTime(2025, 1, 1);
      final currentDate = DateTime(2025, 3, 12); // 10 weeks later
      
      // Act
      final daysDifference = currentDate.difference(lastMenstrualPeriod).inDays;
      final gestationalWeeks = daysDifference ~/ 7;
      
      // Assert
      expect(gestationalWeeks, equals(10));
    });

    test('Calculate estimated due date correctly', () {
      // Arrange
      final lastMenstrualPeriod = DateTime(2025, 1, 1);
      final expectedDueDate = DateTime(2025, 10, 8); // 280 days later
      
      // Act
      final calculatedDueDate = lastMenstrualPeriod.add(const Duration(days: 280));
      
      // Assert
      expect(calculatedDueDate, equals(expectedDueDate));
    });

    test('Calculate weeks remaining until due date', () {
      // Arrange
      final dueDate = DateTime(2025, 10, 8);
      final currentDate = DateTime(2025, 3, 12);
      
      // Act
      final daysRemaining = dueDate.difference(currentDate).inDays;
      final weeksRemaining = daysRemaining ~/ 7;
      
      // Assert
      expect(weeksRemaining, equals(30));
    });

    test('Determine pregnancy trimester from weeks', () {
      // Arrange & Act & Assert
      expect(_getTrimmester(8), equals('First'));
      expect(_getTrimmester(15), equals('Second'));
      expect(_getTrimmester(28), equals('Third'));
    });

    test('Get milestone description for week', () {
      // Arrange
      final descriptions = {
        8: 'Heart starts beating',
        16: 'Baby begins to move',
        24: 'Viability milestone',
        32: 'Rapid growth continues',
      };
      
      // Act & Assert
      expect(descriptions[8], isNotNull);
      expect(descriptions[8], equals('Heart starts beating'));
      expect(descriptions.containsKey(24), isTrue);
    });

    test('Validate gestational age input', () {
      // Arrange & Act & Assert
      expect(_isValidGestationalAge(0), isFalse);
      expect(_isValidGestationalAge(15), isTrue);
      expect(_isValidGestationalAge(42), isTrue);
      expect(_isValidGestationalAge(43), isFalse);
      expect(_isValidGestationalAge(-5), isFalse);
    });
  });
}

// Helper functions for testing
String _getTrimmester(int weeks) {
  if (weeks <= 13) return 'First';
  if (weeks <= 26) return 'Second';
  return 'Third';
}

bool _isValidGestationalAge(int weeks) {
  return weeks > 0 && weeks <= 42;
}
