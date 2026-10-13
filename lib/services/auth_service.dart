import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'storage.dart';

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Authentication backend. [LocalAuthService] keeps accounts on this device;
/// a cloud implementation (e.g. Firebase Auth or Supabase) can implement the
/// same interface to enable cross-device sync.
abstract class AuthService {
  Account? get currentAccount;
  Future<Account?> restoreSession();
  Future<Account> register({
    required String name,
    required String email,
    required String password,
  });
  Future<Account> login({required String email, required String password});
  Future<void> logout();
  Future<void> deleteAccount(String password);
}

/// Device-local accounts. Passwords are never stored: only a salted
/// PBKDF2-HMAC-SHA256 hash.
class LocalAuthService implements AuthService {
  LocalAuthService(this._store, {this.iterations = 60000});

  final KeyValueStore _store;
  final int iterations;
  Account? _current;

  static const _accountsKey = 'auth:accounts';
  static const _sessionKey = 'auth:session';

  @override
  Account? get currentAccount => _current;

  Map<String, dynamic> _accounts() {
    final raw = _store.getString(_accountsKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> _saveAccounts(Map<String, dynamic> accounts) =>
      _store.setString(_accountsKey, jsonEncode(accounts));

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'กรุณากรอกอีเมล';
    if (!_emailPattern.hasMatch(email.trim())) return 'รูปแบบอีเมลไม่ถูกต้อง';
    return null;
  }

  static String? validatePassword(String password) {
    if (password.length < 8) return 'รหัสผ่านอย่างน้อย 8 ตัวอักษร';
    return null;
  }

  Account _fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  @override
  Future<Account?> restoreSession() async {
    final id = _store.getString(_sessionKey);
    if (id == null) return null;
    for (final a in _accounts().values) {
      final j = (a as Map).cast<String, dynamic>();
      if (j['id'] == id) return _current = _fromJson(j);
    }
    await _store.remove(_sessionKey);
    return null;
  }

  @override
  Future<Account> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final e = normalizeEmail(email);
    final emailError = validateEmail(e);
    if (emailError != null) throw AuthException(emailError);
    final pwError = validatePassword(password);
    if (pwError != null) throw AuthException(pwError);
    if (name.trim().isEmpty) throw const AuthException('กรุณากรอกชื่อ');

    final accounts = _accounts();
    if (accounts.containsKey(e)) {
      throw const AuthException('อีเมลนี้มีบัญชีอยู่แล้วในอุปกรณ์นี้');
    }
    final salt = _randomBytes(16);
    final hash = pbkdf2(utf8.encode(password), salt, iterations);
    final account = Account(
      id: _randomId(),
      name: name.trim(),
      email: e,
      createdAt: DateTime.now(),
    );
    accounts[e] = {
      'id': account.id,
      'name': account.name,
      'email': e,
      'createdAt': account.createdAt.toIso8601String(),
      'salt': base64Encode(salt),
      'hash': base64Encode(hash),
      'iterations': iterations,
    };
    await _saveAccounts(accounts);
    await _store.setString(_sessionKey, account.id);
    return _current = account;
  }

  @override
  Future<Account> login({
    required String email,
    required String password,
  }) async {
    final e = normalizeEmail(email);
    final raw = _accounts()[e];
    const invalid = AuthException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    if (raw == null) throw invalid;
    final j = (raw as Map).cast<String, dynamic>();
    if (!_verify(j, password)) throw invalid;
    final account = _fromJson(j);
    await _store.setString(_sessionKey, account.id);
    return _current = account;
  }

  bool _verify(Map<String, dynamic> j, String password) {
    final salt = base64Decode(j['salt'] as String);
    final expected = base64Decode(j['hash'] as String);
    final rounds = (j['iterations'] as num?)?.toInt() ?? iterations;
    final actual = pbkdf2(utf8.encode(password), salt, rounds);
    return _constantTimeEquals(actual, expected);
  }

  @override
  Future<void> logout() async {
    _current = null;
    await _store.remove(_sessionKey);
  }

  @override
  Future<void> deleteAccount(String password) async {
    final account = _current;
    if (account == null) return;
    final accounts = _accounts();
    final raw = accounts[account.email];
    if (raw == null ||
        !_verify((raw as Map).cast<String, dynamic>(), password)) {
      throw const AuthException('รหัสผ่านไม่ถูกต้อง');
    }
    accounts.remove(account.email);
    await _saveAccounts(accounts);
    await logout();
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  static String _randomId() =>
      base64Url.encode(_randomBytes(12)).replaceAll('=', '');

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2-HMAC-SHA256 producing a single 32-byte block.
List<int> pbkdf2(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final out = List<int>.from(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}
