import 'package:flutter_test/flutter_test.dart';
import 'package:kelolakita_mobile/main.dart';

void main() {
  testWidgets('tab Jadwal membuka halaman Penyetoran & Penjemputan', (
    tester,
  ) async {
    await tester.pumpWidget(const KelolaKitaApp());
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Jadwal setor'), findsOneWidget);
    expect(find.text('Dijemput kurir'), findsOneWidget);
    expect(find.text('Antar sendiri'), findsOneWidget);

    await tester.tap(find.text('Edukasi'));
    await tester.pumpAndSettle();
    expect(find.text('Edukasi & komunitas'), findsOneWidget);
  });
}
