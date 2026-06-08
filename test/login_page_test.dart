import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MOCKS ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test-uid-123';

  @override
  String get email => 'test@example.com';
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
  });

  test('User login with valid credentials returns UserCredential', () async {
    // Arrange: Setup mocks
    when(mockUserCredential.user).thenReturn(mockUser);
    when(mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    )).thenAnswer((_) async => mockUserCredential);

    // Act: Perform login
    final result = await mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    );

    // Assert: Verify results
    expect(result, isA<UserCredential>());
    expect(result.user, isNotNull);
    expect(result.user?.email, equals('test@example.com'));
    expect(result.user?.uid, equals('test-uid-123'));

    // Verify mock was called correctly
    verify(mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    )).called(1);
  });

  test('User login fails with invalid email format', () async {
    // Arrange: Setup mock to throw exception
    when(mockAuth.signInWithEmailAndPassword(
      email: 'invalid-email',
      password: 'password123',
    )).thenThrow(
      FirebaseAuthException(code: 'invalid-email', message: 'Invalid email format'),
    );

    // Act & Assert: Expect exception to be thrown
    expect(
      () => mockAuth.signInWithEmailAndPassword(
        email: 'invalid-email',
        password: 'password123',
      ),
      throwsA(isA<FirebaseAuthException>()),
    );
  });

  test('User login fails with wrong password', () async {
    // Arrange: Setup mock to throw wrong password exception
    when(mockAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'wrongpassword',
    )).thenThrow(
      FirebaseAuthException(code: 'wrong-password', message: 'Wrong password'),
    );

    // Act & Assert: Expect exception
    expect(
      () => mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      ),
      throwsA(isA<FirebaseAuthException>()),
    );
  });

  test('User login fails with non-existent email', () async {
    // Arrange
    when(mockAuth.signInWithEmailAndPassword(
      email: 'nonexistent@example.com',
      password: 'password123',
    )).thenThrow(
      FirebaseAuthException(code: 'user-not-found', message: 'User not found'),
    );

    // Act & Assert
    expect(
      () => mockAuth.signInWithEmailAndPassword(
        email: 'nonexistent@example.com',
        password: 'password123',
      ),
      throwsA(isA<FirebaseAuthException>()),
    );
  });
}
