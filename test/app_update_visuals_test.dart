import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/features/app_update/presentation/widgets/update_visuals.dart';

void main() {
  group('formatFileSize', () {
    test('null / zero / negative → null (no empty chip)', () {
      expect(formatFileSize(null), isNull);
      expect(formatFileSize(0), isNull);
      expect(formatFileSize(-5), isNull);
    });

    test('the real apk_size from the bloc comment', () {
      expect(formatFileSize(31845806), '30.4 م.ب');
    });

    test('scales across units', () {
      expect(formatFileSize(512), '512 بايت');
      expect(formatFileSize(4096), '4 ك.ب');
      expect(formatFileSize(5 * 1024 * 1024), '5.0 م.ب');
      expect(formatFileSize(3 * 1024 * 1024 * 1024), '3.0 غ.ب');
    });
  });

  group('ChangelogPanel line parsing', () {
    List<String> lines(String s) => ChangelogPanel(changelog: s).linesForTest;

    test('splits on newlines and drops blanks', () {
      expect(lines('أولاً\n\nثانياً\r\nثالثاً'),
          ['أولاً', 'ثانياً', 'ثالثاً']);
    });

    test('strips pre-existing bullets so they do not double up', () {
      expect(lines('- إصلاح\n• تحسين\n* إضافة\n+ تسريع'),
          ['إصلاح', 'تحسين', 'إضافة', 'تسريع']);
    });

    test('whitespace-only changelog yields nothing', () {
      expect(lines('   \n\n  \r\n '), isEmpty);
    });

    test('single unbulleted line survives intact', () {
      expect(lines('تحسينات عامة على الأداء'), ['تحسينات عامة على الأداء']);
    });
  });
}
