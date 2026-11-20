import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelolakita_mobile/features/account/account_api.dart';
import 'package:kelolakita_mobile/features/account/account_controller.dart';
import 'package:kelolakita_mobile/features/account/account_profile.dart';
import 'package:kelolakita_mobile/main.dart';

const user = AccountProfile(
  username: 'rayna',
  firstName: 'Rayna',
  lastName: 'Kayla',
  email: 'rayna@example.com',
  points: 17,
);

class FakeAccountApi extends AccountApi {
  AccountProfile? current;
  String? password;
  int loginCalls = 0;
  @override
  Future<AccountProfile?> restore() async => current;
  @override
  Future<AccountProfile> login(String username, String password) async {
    loginCalls++;
    this.password = password;
    return current = user;
  }

  @override
  Future<AccountProfile> register(Map<String, String> fields) async =>
      current = user;
  @override
  Future<AccountProfile> updateProfile(Map<String, String> fields) async =>
      current = AccountProfile(
        username: user.username,
        firstName: fields['first_name']!,
        lastName: fields['last_name']!,
        email: fields['email']!,
      );
  @override
  Future<void> logout() async => current = null;
}

void main() {
  Future<AccountController> open(
    WidgetTester tester,
    FakeAccountApi api,
  ) async {
    final controller = AccountController(api);
    await tester.pumpWidget(KelolaKitaApp(accountController: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    addTearDown(controller.dispose);
    return controller;
  }

  testWidgets(
    'login validates required fields and displays the signed-in profile',
    (tester) async {
      final api = FakeAccountApi();
      await open(tester, api);
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Masuk ke KelolaKita'));
      await tester.tap(find.text('Masuk ke KelolaKita'));
      await tester.pumpAndSettle();
      expect(find.text('Nama pengguna wajib diisi.'), findsOneWidget);
      expect(api.loginCalls, 0);
      await tester.enterText(find.byKey(const ValueKey('username')), 'rayna');
      await tester.enterText(
        find.byKey(const ValueKey('password1')),
        ' secret pass ',
      );
      await tester.ensureVisible(find.text('Masuk ke KelolaKita'));
      await tester.tap(find.text('Masuk ke KelolaKita'));
      await tester.pumpAndSettle();
      expect(find.text('Rayna Kayla'), findsOneWidget);
      expect(find.text('17 poin dampak'), findsOneWidget);
      expect(api.password, ' secret pass ');
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );

  testWidgets(
    'restored account can edit its profile and logout after confirmation',
    (tester) async {
      final api = FakeAccountApi()..current = user;
      await open(tester, api);
      await tester.ensureVisible(find.text('Edit profil'));
      await tester.tap(find.text('Edit profil'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('first_name')),
        'Nama Baru',
      );
      await tester.ensureVisible(find.text('Simpan perubahan'));
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pumpAndSettle();
      expect(find.text('Nama Baru Kayla'), findsOneWidget);
      await tester.ensureVisible(find.text('Keluar dari akun'));
      await tester.tap(find.text('Keluar dari akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(api.current, isNotNull);
      await tester.tap(find.text('Keluar dari akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(find.text('Akun kamu'), findsOneWidget);
      expect(api.current, isNull);
    },
  );

  testWidgets(
    'registration supports a narrow screen and validates password confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, FakeAccountApi());
      await tester.tap(find.text('Daftar akun'));
      await tester.pumpAndSettle();
      for (final entry in {
        'username': 'rayna',
        'first_name': 'Rayna',
        'last_name': 'Kayla',
        'email': 'rayna@example.com',
        'password1': 'strong-password',
        'password2': 'different-password',
      }.entries) {
        await tester.ensureVisible(find.byKey(ValueKey(entry.key)));
        await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
      }
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Buat akun KelolaKita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat akun KelolaKita'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi kata sandi tidak cocok.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('password2')),
        'strong-password',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Buat akun KelolaKita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat akun KelolaKita'));
      await tester.pumpAndSettle();
      expect(find.text('Rayna Kayla'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
