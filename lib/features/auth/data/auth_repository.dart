import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/firestore_paths.dart';

part 'auth_repository.g.dart';

enum UserRole { owner, employee, readonly }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isActive;

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String? ?? '',
      role: _roleFromString(data['role'] as String? ?? 'readonly'),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  static UserRole _roleFromString(String role) {
    return switch (role) {
      'owner' => UserRole.owner,
      'employee' => UserRole.employee,
      _ => UserRole.readonly,
    };
  }
}

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchAppUser(user.uid);
  }

  Future<AppUser> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final appUser = await _fetchAppUser(uid);
    if (appUser == null) throw Exception('Kullanıcı profili bulunamadı.');
    return appUser;
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> _fetchAppUser(String uid) async {
    final doc = await _db.doc(FirestorePaths.userDoc(uid)).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
}

@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}
