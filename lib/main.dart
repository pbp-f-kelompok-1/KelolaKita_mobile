import 'package:flutter/material.dart';

import 'education_page.dart';
import 'features/account/account_api.dart';
import 'features/account/account_controller.dart';
import 'features/account/account_page.dart';
import 'features/schedule/schedule_page.dart';
import 'submission_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KelolaKitaApp());
}

class KelolaKitaApp extends StatelessWidget {
  const KelolaKitaApp({super.key, this.accountController});

  final AccountController? accountController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KelolaKita',
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFFFBFD74),
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFFFBFD74),
              onPrimary: const Color(0xFF19270F),
              surface: const Color(0xFF101713),
              onSurface: const Color(0xFFF2F5ED),
              onSurfaceVariant: const Color(0xFFB1BEB1),
              secondaryContainer: const Color(0xFF26362B),
              onSecondaryContainer: const Color(0xFFD4EF70),
            ),
        scaffoldBackgroundColor: const Color(0xFF101713),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A251F),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF101713),
        ),
      ),
      home: _AppShell(accountController: accountController),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({this.accountController});

  final AccountController? accountController;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int selected = 0;
  late final AccountController _account;

  @override
  void initState() {
    super.initState();
    _account = widget.accountController ?? AccountController(AccountApi());
    _account.initialize();
  }

  @override
  void dispose() {
    if (widget.accountController == null) _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: switch (selected) {
        0 => const Center(child: Text('KelolaKita')),
        1 => const SubmissionPage(),
        2 => const SchedulePage(),
        3 => const EducationPage(),
        _ => AccountPage(controller: _account),
      },
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) => setState(() => selected = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Beranda',
        ),
        NavigationDestination(icon: _AddNavigationIcon(), label: 'Ajukan'),
        NavigationDestination(
          icon: Icon(Icons.event_outlined),
          label: 'Jadwal',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Edukasi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
    ),
  );
}

class _AddNavigationIcon extends StatelessWidget {
  const _AddNavigationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFFBFD74),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.add, color: Color(0xFF19270F), size: 24),
    );
  }
}
