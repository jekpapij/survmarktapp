import 'package:flutter_test/flutter_test.dart';
import 'package:survmarkt/features/researcher/domain/entities/survey_entity.dart';

/// Unit test buat `SurveyEntity.progressPercent` — logika bisnis utama
/// dashboard Researcher (dipakai buat progress bar & label "X/Y (Z%)" di
/// modal Kelola Survey). SENGAJA jadi getter TURUNAN dari
/// `respondentCount`/`targetCount` (bukan field mentah tersimpan sendiri —
/// "1 sumber kebenaran", lihat CLAUDE.md), jadi krusial dites biar nggak
/// ada regresi kalau logikanya diubah nanti.
void main() {
  SurveyEntity buildSurvey({required int respondentCount, required int targetCount}) {
    return SurveyEntity(
      id: 'survey-test',
      title: 'Survei Uji Coba',
      category: 'Testing',
      status: SurveyStatus.open,
      durationMinutes: 10,
      incentiveAmount: 15000,
      targetLabel: 'Semua Umur',
      deadlineDate: DateTime(2026, 12, 31),
      respondentCount: respondentCount,
      targetCount: targetCount,
      views: 0,
      conversionPercent: 0,
      metaKind: SurveyMetaKind.deadline,
      metaText: 'Deadline: 30 hari lagi',
    );
  }

  group('SurveyEntity.progressPercent', () {
    test('dibulatkan dari respondentCount/targetCount', () {
      final survey = buildSurvey(respondentCount: 130, targetCount: 200);
      expect(survey.progressPercent, 65);
    });

    test('targetCount 0 tidak menyebabkan pembagian error, hasilnya 0', () {
      final survey = buildSurvey(respondentCount: 0, targetCount: 0);
      expect(survey.progressPercent, 0);
    });

    test('respondentCount == targetCount menghasilkan 100%', () {
      final survey = buildSurvey(respondentCount: 300, targetCount: 300);
      expect(survey.progressPercent, 100);
    });

    test('hasil di-clamp maksimal 100 walau respondentCount lebih besar dari target', () {
      final survey = buildSurvey(respondentCount: 350, targetCount: 300);
      expect(survey.progressPercent, 100);
    });
  });

  group('SurveyEntity.copyWith', () {
    test('cuma field yang dikasih yang berubah, sisanya tetap sama', () {
      final original = buildSurvey(respondentCount: 100, targetCount: 200);
      final updated = original.copyWith(status: SurveyStatus.paused, metaText: 'Dijeda baru saja');

      expect(updated.status, SurveyStatus.paused);
      expect(updated.metaText, 'Dijeda baru saja');
      // Field lain (id, title, respondentCount, dst.) harus tetap identik.
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.respondentCount, original.respondentCount);
      expect(updated.targetCount, original.targetCount);
    });
  });
}
