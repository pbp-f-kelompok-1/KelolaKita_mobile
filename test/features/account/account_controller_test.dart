import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kelolakita_mobile/features/account/account_api.dart';
import 'package:kelolakita_mobile/features/account/account_controller.dart';
import 'package:kelolakita_mobile/features/account/account_profile.dart';

const user = AccountProfile(
  username: 'rayna',
  firstName: 'Rayna',
  lastName: 'Kayla',
  email: 'rayna@example.com',
);

class ControlledApi extends AccountApi {
  Completer<AccountProfile>? loginResult;
  AccountException? failure;
  int cleared = 0;
  int calls = 0;
  @override
  Future<AccountProfile?> restore() async => user;
  @override
  Future<AccountProfile> login(String username, String password) async {
    calls++;
    return loginResult!.future;
  }

  @override
  Future<AccountProfile> profile() async {
    if (failure != null) throw failure!;
    return user;
  }

  @override
  Future<void> logout() async {
    if (failure != null) throw failure!;
  }

  @override
  Future<void> clearSession() async => cleared++;
}

void main() {
  test(
    'pending login blocks duplicate submissions and exposes busy state',
    () async {
      final api = ControlledApi()..loginResult = Completer<AccountProfile>();
      final controller = AccountController(api);
      final pending = controller.login('rayna', 'secret');
      expect(controller.busy, isTrue);
      expect(await controller.login('rayna', 'secret'), isFalse);
      expect(api.calls, 1);
      api.loginResult!.complete(user);
      expect(await pending, isTrue);
      expect(controller.busy, isFalse);
      expect(controller.profile, user);
      controller.dispose();
    },
  );

  test('network failure preserves profile, expiry removes profile and stored session', () async {
    final api = ControlledApi();
    final controller = AccountController(api);
    await controller.initialize();
    api.failure = const AccountException('Offline');
    expect(await controller.refresh(), isFalse);
    expect(controller.profile, user);
    expect(api.cleared, 0);
    api.failure = const AccountException('Sesi berakhir', expired: true);
    expect(await controller.refresh(), isFalse);
    expect(controller.profile, isNull);
    expect(api.cleared, 1);
    controller.dispose();
  });

  test('failed server logout stays signed in and can be retried', () async {
    final api = ControlledApi();
    final controller = AccountController(api);
    await controller.initialize();
    api.failure = const AccountException('Offline');
    expect(await controller.logout(), isFalse);
    expect(controller.profile, user);
    api.failure = null;
    expect(await controller.logout(), isTrue);
    expect(controller.profile, isNull);
    controller.dispose();
  });
}
