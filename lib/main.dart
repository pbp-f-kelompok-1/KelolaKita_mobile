import 'package:flutter/material.dart';

import 'education_page.dart';

void main() => runApp(const KelolaKitaApp());

class KelolaKitaApp extends StatelessWidget {
  const KelolaKitaApp({super.key});

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
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: selected == 0
          ? const Center(child: Text('KelolaKita'))
          : const EducationPage(),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) => setState(() => selected = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Edukasi',
        ),
      ],
    ),
  );
}
