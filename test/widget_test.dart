import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survmarkt/core/widgets/metric_card.dart';

/// Widget smoke test buat `MetricCard` — widget reusable generik (dipakai
/// ulang di dashboard researcher/admin & wallet, lihat komentar di
/// `core/widgets/metric_card.dart`), zero dependency ke Provider/Riverpod/
/// network jadi bisa di-`pumpWidget` langsung di dalam `MaterialApp` polos
/// tanpa perlu `ProviderScope`/mocking apa pun. File ini gantiin
/// `test/widget_test.dart` bawaan `flutter create` yang sebelumnya kosong
/// (0 byte) — lihat CLAUDE.md bagian Unit Test.
void main() {
  testWidgets('MetricCard menampilkan label dan value yang diberikan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(label: 'TOTAL SURVEI', value: '12'),
        ),
      ),
    );

    expect(find.text('TOTAL SURVEI'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('MetricCard bisa dipakai berulang dengan value berbeda-beda', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MetricCard(label: 'RESPONDEN', value: '86'),
              MetricCard(label: 'PENDAPATAN', value: 'Rp 8.4jt'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('RESPONDEN'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.text('PENDAPATAN'), findsOneWidget);
    expect(find.text('Rp 8.4jt'), findsOneWidget);
  });
}
