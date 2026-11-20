import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kelolakita_mobile/features/account/account_api.dart';
import 'package:kelolakita_mobile/features/account/account_profile.dart';
import 'package:kelolakita_mobile/features/account/session_store.dart';

class MemorySessionStore implements SessionStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

// Mirrors the selectors and Django form fields in accounts/profile.html.
const profileHtml = '''
<section><div><h2 data-profile-full-name>Rayna Kayla</h2><p>@rayna</p></div></section>
<dl><div><dt>Poin dampak</dt><dd>17</dd></div><div><dt>Peran</dt><dd>Pengguna</dd></div>
<div><dt>Profil diperbarui</dt><dd>20 November 2026</dd></div></dl>
<form data-profile-form><input name="csrfmiddlewaretoken" value="rotated-token">
<input name="first_name" value="Rayna"><input name="last_name" value="Kayla">
<input name="email" value="rayna@example.com"><input name="phone_number" value="08123456789">
<input name="avatar_url" value=""><textarea name="address">Depok &amp; Jakarta</textarea></form>
''';
const loginHtml =
    '<form><input name="csrfmiddlewaretoken" value="initial-token"><input name="password"></form>';

void main() {
  late MemorySessionStore store;
  setUp(() => store = MemorySessionStore());

  AccountApi api(
    Future<http.Response> Function(http.Request) handler, {
    String base = 'http://localhost:8000',
  }) => AccountApi(baseUrl: base, client: MockClient(handler), store: store);

  test('login uses Django CSRF, remember_me, rotated cookies and restores in a new instance', () async {
    final requests = <http.Request>[];
    final service = api((request) async {
      requests.add(request);
      if (request.url.path == '/accounts/profile/') {
        expect(request.headers['cookie'], contains('sessionid=session-secret'));
        return http.Response(profileHtml, 200);
      }
      if (request.method == 'GET') {
        return http.Response(
          loginHtml,
          200,
          headers: {'set-cookie': 'csrftoken=initial; Path=/'},
        );
      }
      expect(request.bodyFields['csrfmiddlewaretoken'], 'initial-token');
      expect(request.bodyFields['remember_me'], 'on');
      expect(request.bodyFields['password'], 'sensitive-password');
      expect(request.headers['cookie'], 'csrftoken=initial');
      expect(request.followRedirects, isFalse);
      return http.Response(
        '',
        302,
        headers: {
          'location': '/',
          'set-cookie': 'csrftoken=rotated; Path=/, sessionid=session-secret; expires=Fri, 04 Dec 2026 00:00:00 GMT; HttpOnly; Path=/',
        },
      );
    });
    final profile = await service.login('rayna', 'sensitive-password');
    expect(profile.fullName, 'Rayna Kayla');
    expect(profile.address, 'Depok & Jakarta');
    expect(profile.points, 17);
    expect(store.values.values.single, isNot(contains('sensitive-password')));
    final restored = await api((request) async {
      expect(request.headers['cookie'], contains('sessionid=session-secret'));
      return http.Response(profileHtml, 200);
    }).restore();
    expect(restored!.email, 'rayna@example.com');
    expect(requests.length, 3);
  });

  test(
    'registration submits the Django field names and saves its session',
    () async {
      final service = api((request) async {
        if (request.url.path.endsWith('/profile/')) {
          return http.Response(profileHtml, 200);
        }
        if (request.method == 'GET') {
          return http.Response(
            loginHtml.replaceAll('name="password"', 'name="password1"'),
            200,
          );
        }
        expect(request.url.path, '/accounts/register/');
        expect(request.bodyFields['password1'], 'strong-password');
        expect(request.bodyFields['password2'], 'strong-password');
        expect(request.bodyFields['last_name'], 'Kayla');
        return http.Response(
          '',
          302,
          headers: {'set-cookie': 'sessionid=new-session; Path=/'},
        );
      });
      await service.register({
        'username': 'rayna',
        'first_name': 'Rayna',
        'last_name': 'Kayla',
        'email': 'rayna@example.com',
        'password1': 'strong-password',
        'password2': 'strong-password',
      });
      expect(store.values.values.single, contains('new-session'));
    },
  );

  test('Django login and duplicate email errors reach the caller', () async {
    for (final errorHtml in [
      '<div role="alert"><p>Nama pengguna atau kata sandi salah.</p></div>',
      '<form><p class="mt-1.5 text-sm text-[#a33128]">Email sudah digunakan.</p></form>',
    ]) {
      final service = api(
        (request) async =>
            http.Response(request.method == 'GET' ? loginHtml : errorHtml, 200),
      );
      await expectLater(
        service.login('rayna', 'wrong'),
        throwsA(
          isA<AccountException>().having(
            (e) => e.message,
            'message',
            anyOf(contains('sandi salah'), contains('Email sudah')),
          ),
        ),
      );
      expect(store.values, isEmpty);
    }
  });

  test('expired saved session is deleted; network failure keeps the session for retry', () async {
    const key = 'kelolakita.account.v1.http://localhost:8000';
    store.values[key] = '{"sessionid":"old"}';
    final offline = api(
      (request) async => throw http.ClientException('offline'),
    );
    await expectLater(offline.restore(), throwsA(isA<AccountException>()));
    expect(store.values, isNotEmpty);
    final expired = api(
      (request) async => http.Response(
        '',
        302,
        headers: {'location': '/accounts/login/?next=/accounts/profile/'},
      ),
    );
    expect(await expired.restore(), isNull);
    expect(store.values, isEmpty);
  });

  test('malformed saved session is removed and different server does not restore it', () async {
    store.values['kelolakita.account.v1.http://localhost:8000'] = 'broken json';
    expect(
      await api((_) async => throw StateError('no network')).restore(),
      isNull,
    );
    expect(store.values, isEmpty);
    store.values['kelolakita.account.v1.http://localhost:8000'] =
        '{"sessionid":"old"}';
    expect(
      await api(
        (_) async => throw StateError('no network'),
        base: 'http://localhost:9000',
      ).restore(),
      isNull,
    );
  });

  test('profile update uses AJAX and fresh CSRF; role and points cannot be submitted', () async {
    var reads = 0;
    final service = api((request) async {
      if (request.method == 'GET') {
        reads++;
        return http.Response(profileHtml, 200);
      }
      expect(request.headers['X-Requested-With'], 'XMLHttpRequest');
      expect(request.headers['X-CSRFToken'], 'rotated-token');
      expect(request.bodyFields['role'], isNull);
      expect(request.bodyFields['points'], isNull);
      expect(request.bodyFields['first_name'], 'Baru');
      return http.Response(jsonEncode({'success': true}), 200);
    });
    await service.updateProfile({
      'first_name': 'Baru',
      'role': 'manager',
      'points': '999',
    });
    expect(reads, 2);
  });

  test(
    'nested Django validation errors are shown without losing the session',
    () async {
      final service = api(
        (request) async => http.Response(
          request.method == 'GET'
              ? profileHtml
              : jsonEncode({
                  'success': false,
                  'errors': {
                    'user': {
                      'email': ['Email sudah digunakan.'],
                    },
                    'profile': {
                      'avatar_url': ['URL tidak valid.'],
                    },
                  },
                  'non_field_errors': {'user': [], 'profile': []},
                }),
          request.method == 'GET' ? 200 : 400,
        ),
      );
      await expectLater(
        service.updateProfile({}),
        throwsA(
          isA<AccountException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Email sudah'), contains('URL tidak')),
          ),
        ),
      );
    },
  );

  test('logout is POST with CSRF and clears persisted credentials', () async {
    store.values['kelolakita.account.v1.http://localhost:8000'] =
        '{"sessionid":"old"}';
    final service = api((request) async {
      if (request.method == 'GET') return http.Response(profileHtml, 200);
      expect(request.url.path, '/accounts/logout/');
      expect(request.bodyFields['csrfmiddlewaretoken'], 'rotated-token');
      return http.Response('', 302);
    });
    await service.logout();
    expect(store.values, isEmpty);
  });

  test(
    'missing configuration, CSRF denial and server errors have useful messages',
    () async {
      await expectLater(
        api((_) async => http.Response('', 200), base: '').profile(),
        throwsA(
          isA<AccountException>().having(
            (e) => e.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
      for (final status in [403, 404, 500]) {
        await expectLater(
          api((_) async => http.Response('', status)).profile(),
          throwsA(isA<AccountException>()),
        );
      }
    },
  );
}
