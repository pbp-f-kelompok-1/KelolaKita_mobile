import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelolakita_mobile/main.dart';

void main() {
  testWidgets('Edukasi dapat dibuka dari navigasi dan kembali ke Beranda', (
    tester,
  ) async {
    await tester.pumpWidget(const KelolaKitaApp());
    await tester.tap(find.text('Edukasi'));
    await tester.pumpAndSettle();

    expect(find.text('Edukasi & komunitas'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.text('KelolaKita'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
