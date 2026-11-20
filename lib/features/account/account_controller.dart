import 'package:flutter/foundation.dart';

import 'account_api.dart';
import 'account_profile.dart';

class AccountController extends ChangeNotifier {
  AccountController(this.api);
  final AccountApi api;
  AccountProfile? profile;
  bool busy = false;
  bool initialized = false;
  String? error;
  bool _disposed = false;

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    _notify();
    try {
      await action();
      return true;
    } on AccountException catch (exception) {
      error = exception.message;
      if (exception.expired) {
        profile = null;
        try {
          await api.clearSession();
        } catch (_) {
          error = 'Sesi berakhir, tetapi penyimpanan sesi belum dapat dibersihkan. Coba lagi.';
        }
      }
      return false;
    } catch (_) {
      error = 'Akun belum dapat diproses. Periksa penyimpanan perangkat dan coba lagi.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> initialize() async {
    final result = await _run(() async => profile = await api.restore());
    initialized = true;
    _notify();
    return result;
  }

  Future<bool> login(String username, String password) =>
      _run(() async => profile = await api.login(username, password));

  Future<bool> register(Map<String, String> fields) =>
      _run(() async => profile = await api.register(fields));

  Future<bool> refresh() => _run(() async => profile = await api.profile());

  Future<bool> update(Map<String, String> fields) =>
      _run(() async => profile = await api.updateProfile(fields));

  Future<bool> logout() => _run(() async {
    await api.logout();
    profile = null;
  });

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    api.close();
    super.dispose();
  }
}
