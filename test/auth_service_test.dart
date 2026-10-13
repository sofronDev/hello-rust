import 'package:fitplan/services/auth_service.dart';
import 'package:fitplan/services/storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryStore store;
  late LocalAuthService auth;

  setUp(() {
    store = MemoryStore();
    auth = LocalAuthService(store, iterations: 1000);
  });

  test('register signs in and never stores the plain password', () async {
    final a = await auth.register(
        name: 'ต้น', email: ' Ton@Example.com ', password: 'secret123');
    expect(a.email, 'ton@example.com');
    expect(auth.currentAccount?.id, a.id);
    expect(store.data.values.join(), isNot(contains('secret123')));
  });

  test('login succeeds only with the right password', () async {
    await auth.register(name: 'a', email: 'a@b.co', password: 'secret123');
    await auth.logout();
    expect(auth.currentAccount, isNull);
    expect(
      () => auth.login(email: 'a@b.co', password: 'wrong-pass'),
      throwsA(isA<AuthException>()),
    );
    final a = await auth.login(email: 'A@B.CO', password: 'secret123');
    expect(a.email, 'a@b.co');
  });

  test('rejects duplicates, bad emails and short passwords', () async {
    await auth.register(name: 'a', email: 'a@b.co', password: 'secret123');
    expect(() => auth.register(name: 'b', email: 'a@b.co', password: 'secret123'),
        throwsA(isA<AuthException>()));
    expect(() => auth.register(name: 'b', email: 'nope', password: 'secret123'),
        throwsA(isA<AuthException>()));
    expect(() => auth.register(name: 'b', email: 'c@d.co', password: 'short'),
        throwsA(isA<AuthException>()));
  });

  test('session survives a restart', () async {
    final a =
        await auth.register(name: 'a', email: 'a@b.co', password: 'secret123');
    final again = LocalAuthService(store, iterations: 1000);
    expect((await again.restoreSession())?.id, a.id);
  });

  test('delete account requires the password', () async {
    await auth.register(name: 'a', email: 'a@b.co', password: 'secret123');
    expect(() => auth.deleteAccount('wrong-pass'),
        throwsA(isA<AuthException>()));
    await auth.deleteAccount('secret123');
    expect(auth.currentAccount, isNull);
    expect(() => auth.login(email: 'a@b.co', password: 'secret123'),
        throwsA(isA<AuthException>()));
  });

  test('pbkdf2 matches the RFC 7914 PBKDF2-HMAC-SHA256 test vector', () {
    // RFC 7914 §11: P="passwd", S="salt", c=1 (first 32 bytes of DK).
    final dk = pbkdf2('passwd'.codeUnits, 'salt'.codeUnits, 1);
    final hex = dk.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(hex,
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc');
  });
}
