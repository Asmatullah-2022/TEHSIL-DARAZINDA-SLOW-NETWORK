import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps Firebase Auth. Guest usage never calls this at all — guest
/// mode simply skips authentication and measurements are tagged with an
/// anonymous device identifier instead of a `userId` (see
/// `DeviceIdentity`). Architecture leaves room for phone auth later by
/// adding a sibling method here without touching call sites.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth? _auth;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  Future<AuthResult> signInWithEmail(String email, String password) async {
    if (_auth == null) return AuthResult.failure('firebase_not_configured');
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(e.code);
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password) async {
    if (_auth == null) return AuthResult.failure('firebase_not_configured');
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}

class AuthResult {
  AuthResult._(this.isSuccess, this.errorCode);
  factory AuthResult.success() => AuthResult._(true, null);
  factory AuthResult.failure(String code) => AuthResult._(false, code);

  final bool isSuccess;
  final String? errorCode;
}

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  FirebaseAuth? auth;
  try {
    auth = FirebaseAuth.instance;
  } catch (_) {
    auth = null; // Firebase not initialized — guest mode still works.
  }
  return AuthRepository(auth);
});

final StreamProvider<User?> authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
