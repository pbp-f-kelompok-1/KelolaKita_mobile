import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import 'account_client.dart'
    if (dart.library.js_interop) 'account_client_web.dart';
import 'account_profile.dart';
import 'session_store.dart';

/// Adapter for the existing Django session/form endpoints, including the JSON
/// profile update response. No speculative token or REST endpoints are used.
class AccountApi {
  AccountApi({
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
    http.Client? client,
    SessionStore? store,
  }) : _base = Uri.tryParse(baseUrl),
       _client = client ?? createAccountClient(),
       _store = store ?? const SecureSessionStore();

  final Uri? _base;
  final http.Client _client;
  final SessionStore _store;
  final Map<String, String> _cookies = {};
  String? _csrf;
  String get _sessionKey => 'kelolakita.account.v1.${_origin.origin}';

  Uri get _origin {
    final base = _base;
    if (base == null ||
        !base.hasAuthority ||
        !['http', 'https'].contains(base.scheme) ||
        base.userInfo.isNotEmpty) {
      throw const AccountException(
        'API_BASE_URL belum diatur. Jalankan aplikasi dengan URL Django.',
      );
    }
    return base;
  }

  Future<AccountProfile?> restore() async {
    final saved = await _store.read(_sessionKey);
    if (saved == null) return null;
    try {
      final values = (jsonDecode(saved) as Map).cast<String, String>();
      _cookies.addAll(values);
    } on FormatException {
      await clearSession();
      return null;
    } on TypeError {
      await clearSession();
      return null;
    }
    try {
      return await profile();
    } on AccountException catch (error) {
      if (!error.expired) rethrow;
      await clearSession();
      return null;
    }
  }

  Future<AccountProfile> login(String username, String password) async {
    await _form('login');
    final response = await _request('POST', 'login', {
      'username': username,
      'password': password,
      'remember_me': 'on',
    });
    _checkAuthForm(response);
    return _finishAuthentication();
  }

  Future<AccountProfile> register(Map<String, String> fields) async {
    await _form('register');
    final response = await _request('POST', 'register', {
      for (final key in const [
        'username',
        'first_name',
        'last_name',
        'email',
        'password1',
        'password2',
      ])
        key: fields[key] ?? '',
    });
    _checkAuthForm(response);
    return _finishAuthentication();
  }

  Future<AccountProfile> _finishAuthentication() async {
    final user = await profile();
    try {
      await _persist();
    } catch (_) {
      // Avoid leaving a hidden authenticated session when secure storage fails.
      try {
        await logout();
      } catch (_) {
        _cookies.clear();
        _csrf = null;
      }
      throw const AccountException(
        'Sesi belum dapat disimpan di perangkat. Periksa penyimpanan lalu masuk kembali.',
      );
    }
    return user;
  }

  Future<AccountProfile> profile() async {
    final response = await _request('GET', 'profile');
    if (response.statusCode == 302 || response.statusCode == 401) {
      throw const AccountException(
        'Sesi berakhir. Silakan masuk kembali.',
        expired: true,
      );
    }
    final document = html.parse(_body(response));
    if (document.querySelector('[name="password"]') != null) {
      throw const AccountException(
        'Sesi berakhir. Silakan masuk kembali.',
        expired: true,
      );
    }
    final form = document.querySelector('[data-profile-form]');
    final name = document.querySelector('[data-profile-full-name]');
    if (form == null || name == null) {
      throw const AccountException('Format profil Django tidak dikenali.');
    }
    _csrf = _token(document);
    String field(String key) {
      final element = form.querySelector('[name="$key"]');
      if (element == null) {
        throw const AccountException('Data profil Django tidak lengkap.');
      }
      return element.localName == 'textarea'
          ? element.text
          : element.attributes['value'] ?? '';
    }

    String summary(String title) {
      for (final term in document.querySelectorAll('dt')) {
        if (term.text.trim() == title) {
          return term.parent?.querySelector('dd')?.text.trim() ?? '';
        }
      }
      return '';
    }

    final username = name.parent?.querySelector('p')?.text.trim() ?? '';
    if (!username.startsWith('@') || username.length < 2) {
      throw const AccountException('Nama pengguna Django tidak dikenali.');
    }
    return AccountProfile(
      username: username.substring(1),
      firstName: field('first_name'),
      lastName: field('last_name'),
      email: field('email'),
      phoneNumber: field('phone_number'),
      address: field('address'),
      avatarUrl: field('avatar_url'),
      role: summary('Peran'),
      points: int.tryParse(summary('Poin dampak')) ?? 0,
      updatedAt: summary('Profil diperbarui'),
    );
  }

  Future<AccountProfile> updateProfile(Map<String, String> fields) async {
    // Read a fresh CSRF token and verify the session before sending changes.
    await profile();
    final response = await _request('POST', 'profile', {
      for (final key in const [
        'first_name',
        'last_name',
        'email',
        'phone_number',
        'address',
        'avatar_url',
      ])
        key: fields[key] ?? '',
    });
    if (response.statusCode == 302 || response.statusCode == 401) {
      throw const AccountException(
        'Sesi berakhir. Silakan masuk kembali.',
        expired: true,
      );
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(_body(response)) as Map<String, dynamic>;
    } catch (_) {
      throw const AccountException('Respons pembaruan profil tidak dikenali.');
    }
    if (data['success'] != true) {
      final messages = <String>[];
      void collect(dynamic value) {
        if (value is Map) {
          value.values.forEach(collect);
        } else if (value is List) {
          value.forEach(collect);
        } else if (value is String && value.isNotEmpty) {
          messages.add(value);
        }
      }

      collect(data['errors']);
      collect(data['non_field_errors']);
      throw AccountException(
        messages.isEmpty ? 'Profil belum dapat disimpan.' : messages.join('\n'),
      );
    }
    return profile();
  }

  Future<void> logout() async {
    try {
      await profile();
      final response = await _request('POST', 'logout', {});
      if (![200, 302, 303].contains(response.statusCode)) {
        throw const AccountException('Belum dapat keluar. Coba lagi.');
      }
    } on AccountException catch (error) {
      if (!error.expired) rethrow;
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    await _store.delete(_sessionKey);
    _cookies.clear();
    _csrf = null;
  }

  Future<void> _persist() => _store.write(_sessionKey, jsonEncode(_cookies));

  Future<void> _form(String path) async {
    var response = await _request('GET', path);
    var document = html.parse(_body(response));
    final passwordField = path == 'login' ? 'password' : 'password1';
    if ([302, 303].contains(response.statusCode) ||
        document.querySelector('[name="$passwordField"]') == null) {
      // Authenticate the entered credentials, even when a browser already has
      // a Django website session that the Flutter app has not restored.
      await profile();
      await _request('POST', 'logout', {});
      await clearSession();
      response = await _request('GET', path);
      document = html.parse(_body(response));
    }
    _csrf = _token(document);
  }

  String _token(Document document) {
    final token = document
        .querySelector('[name="csrfmiddlewaretoken"]')
        ?.attributes['value'];
    if (token == null || token.isEmpty) {
      throw const AccountException(
        'Token keamanan Django tidak tersedia. Coba lagi.',
      );
    }
    return token;
  }

  void _checkAuthForm(http.Response response) {
    if ([302, 303].contains(response.statusCode)) return;
    final document = html.parse(_body(response));
    final messages = document
        .querySelectorAll(
          '[role="alert"] p, p[role="alert"], .errorlist li, form p',
        )
        .where(
          (element) =>
              element.parent?.attributes['role'] == 'alert' ||
              element.attributes['role'] == 'alert' ||
              element.localName == 'li' ||
              element.classes.contains('text-[#a33128]'),
        )
        .map((element) => element.text.trim())
        .where((text) => text.isNotEmpty)
        .toSet();
    if (messages.isNotEmpty) throw AccountException(messages.join('\n'));
    if (document.querySelector('[name="password"], [name="password1"]') !=
        null) {
      throw const AccountException(
        'Data akun belum valid. Periksa isian dan coba lagi.',
      );
    }
  }

  String _body(http.Response response) => utf8.decode(response.bodyBytes);

  Future<http.Response> _request(
    String method,
    String path, [
    Map<String, String>? fields,
  ]) async {
    final uri = _origin.resolve('/accounts/$path/');
    final request = http.Request(method, uri)..followRedirects = kIsWeb;
    if (!kIsWeb) request.headers['Referer'] = uri.toString();
    if (!kIsWeb && _cookies.isNotEmpty) {
      request.headers['Cookie'] = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }
    if (fields != null) {
      request.bodyFields = {...fields, 'csrfmiddlewaretoken': _csrf ?? ''};
      request.headers['X-CSRFToken'] = _csrf ?? '';
      if (path == 'profile') {
        request.headers['X-Requested-With'] = 'XMLHttpRequest';
      }
    }
    try {
      final response = await (() async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 15));
      // Browser cookies (including HttpOnly sessionid) are managed by the browser.
      if (!kIsWeb) {
        final header = response.headers['set-cookie'];
        if (header != null) {
          for (final cookie in header.split(RegExp(r',(?=\s*[\w-]+=)'))) {
            final pair = cookie.split(';').first.trim();
            final index = pair.indexOf('=');
            if (index < 1) continue;
            final key = pair.substring(0, index);
            if (key == 'sessionid' || key == 'csrftoken') {
              _cookies[key] = pair.substring(index + 1);
            }
          }
        }
      }
      if (response.statusCode == 403) {
        throw const AccountException(
          'Permintaan ditolak Django. Coba lagi untuk memperbarui token keamanan.',
        );
      }
      if (response.statusCode >= 500 || response.statusCode == 404) {
        throw const AccountException(
          'Layanan akun Django belum tersedia. Coba lagi nanti.',
        );
      }
      return response;
    } on TimeoutException {
      throw const AccountException(
        'Koneksi terlalu lama. Periksa jaringan dan coba lagi.',
      );
    } on http.ClientException {
      throw const AccountException(
        'Tidak dapat terhubung ke Django. Periksa jaringan dan API_BASE_URL.',
      );
    }
  }

  void close() => _client.close();
}
