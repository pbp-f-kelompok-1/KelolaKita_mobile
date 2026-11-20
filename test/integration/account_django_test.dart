import 'package:flutter_test/flutter_test.dart';
import 'package:kelolakita_mobile/features/account/account_api.dart';
import 'package:kelolakita_mobile/features/account/account_profile.dart';

import '../features/account/account_api_test.dart' show MemorySessionStore;

const testUrl = String.fromEnvironment('ACCOUNT_TEST_URL');

void main() {
  test(
    'real Django: register, restore, edit, logout, wrong password and login',
    () async {
      final store = MemorySessionStore();
      final api = AccountApi(baseUrl: testUrl, store: store);
      final username = 'flutter_${DateTime.now().microsecondsSinceEpoch}';
      const password = 'Kk!test-dampak-4827';
      final fields = {
        'username': username,
        'first_name': 'Flutter',
        'last_name': 'Pengujian',
        'email': '$username@example.com',
        'password1': password,
        'password2': password,
      };
      final registered = await api.register(fields);
      expect(registered.username, username);
      expect(registered.fullName, 'Flutter Pengujian');
      expect(store.values.values.single, isNot(contains(password)));
      final reopened = AccountApi(baseUrl: testUrl, store: store);
      expect((await reopened.restore())!.username, username);
      final updated = await reopened.updateProfile({
        ...registered.editableFields,
        'first_name': 'Nama Baru',
        'phone_number': '08123456789',
        'address': 'Depok & Jakarta',
      });
      expect(updated.firstName, 'Nama Baru');
      expect(updated.address, 'Depok & Jakarta');
      await expectLater(
        reopened.updateProfile({
          ...updated.editableFields,
          'avatar_url': 'bukan-url',
        }),
        throwsA(isA<AccountException>()),
      );
      await reopened.logout();
      expect(store.values, isEmpty);
      // The original client's old cookie was invalidated on the server as well.
      await expectLater(
        api.profile(),
        throwsA(
          isA<AccountException>().having((e) => e.expired, 'expired', true),
        ),
      );
      await expectLater(
        reopened.login(username, 'wrong-password'),
        throwsA(isA<AccountException>()),
      );
      expect((await reopened.login(username, password)).firstName, 'Nama Baru');
      await reopened.logout();
      api.close();
      reopened.close();
    },
    skip: testUrl.isEmpty
        ? 'Set ACCOUNT_TEST_URL to the isolated Django test server.'
        : false,
  );
}
