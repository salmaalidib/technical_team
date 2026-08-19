import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:technical_team/features/app_update/di/injection.dart';

/// اختبار انحدار لعطل «التحديث لا يعمل».
///
/// العطل: على ويندوز يقرأ package_info_plus حقل `ProductVersion` من داخل الـ
/// .exe ويقسمه على '+' لاستخراج buildNumber، لكن Flutter يكتب هناك اسم النسخة
/// وحده ("1.0.5") بلا "+5" — لأن رقم البناء يذهب منفصلاً إلى
/// FLUTTER_VERSION_BUILD. فالنتيجة buildNumber = "" ثم currentVersionCode = 0
/// دائماً، فيردّ الخادم «يوجد تحديث» على أي نسخة مهما كانت حديثة، وتتكرّر شاشة
/// التحديث الإجباري بلا نهاية.
///
/// الإصلاح: حقن APP_VERSION_CODE وقت الترجمة. هذه الاختبارات تثبّت السلوك.
/// قيمة الحقن الفعلية أثناء تشغيل الاختبار. الافتراضي 0 (بلا حقن)، لكن تشغيل
/// الاختبار بـ --dart-define=APP_VERSION_CODE=N يجعل الحقن يتقدّم على كل شيء —
/// وهو السلوك المقصود، فتُكتب التوقّعات أدناه بدلالته لا برقم ثابت.
const int _injected = int.fromEnvironment('APP_VERSION_CODE', defaultValue: 0);

PackageInfo _info({required String version, required String buildNumber}) {
  return PackageInfo(
    appName: 'technical_team',
    packageName: 'technical_team',
    version: version,
    buildNumber: buildNumber,
    buildSignature: '',
  );
}

void main() {
  group('resolveCurrentVersionCode', () {
    test('يرجع 0 حين يكون buildNumber فارغاً بلا حقن — وهو عين العطل', () {
      // ما يحدث حرفياً على ويندوز: "1.0.5".split('+') طوله 1 → getOrNull(1)=null.
      expect(
        resolveCurrentVersionCode(_info(version: '1.0.5', buildNumber: '')),
        _injected > 0 ? _injected : 0,
        reason:
            'بلا --dart-define=APP_VERSION_CODE يُرسَل 0 وتتكرّر شاشة التحديث. '
            'شغّل هذا الاختبار بـ --dart-define=APP_VERSION_CODE=5 ليتحقق الإصلاح.',
      );
    });

    test('يعتمد buildNumber حين يصل صحيحاً (أندرويد/iOS)', () {
      expect(
        resolveCurrentVersionCode(_info(version: '1.0.5', buildNumber: '5')),
        _injected > 0 ? _injected : 5,
      );
    });

    test('لا ينهار على buildNumber غير رقمي', () {
      expect(
        resolveCurrentVersionCode(_info(version: '1.0.5', buildNumber: 'abc')),
        _injected > 0 ? _injected : 0,
      );
    });

    test('يتجاهل المسافات حول buildNumber', () {
      expect(
        resolveCurrentVersionCode(_info(version: '1.0.5', buildNumber: ' 7 ')),
        _injected > 0 ? _injected : 7,
      );
    });
  });

  group('أولوية الحقن', () {
    test('الحقن يتقدّم على buildNumber الفارغ — جوهر الإصلاح', () {
      final resolved =
          resolveCurrentVersionCode(_info(version: '1.0.5', buildNumber: ''));
      if (_injected > 0) {
        expect(resolved, _injected);
      } else {
        // بلا حقن يظهر العطل الأصلي؛ شغّل بـ --dart-define للتحقق من الإصلاح.
        expect(resolved, 0);
      }
    });
  });

  group('سلوك package_info_plus على ويندوز (توثيق تنفيذي للسبب الجذري)', () {
    // نسخة طبق الأصل من منطق المكتبة:
    //   final versions = info.productVersion.split('+');
    //   buildNumber: versions.getOrNull(1) ?? '';
    String windowsBuildNumber(String productVersion) {
      final parts = productVersion.split('+');
      return parts.length > 1 ? parts[1] : '';
    }

    test('ProductVersion الذي يكتبه Flutter بلا "+" ينتج buildNumber فارغاً', () {
      expect(windowsBuildNumber('1.0.5'), '');
      expect(windowsBuildNumber('1.0.2'), '');
    });

    test('لو احتوى "+" لعمل — وهذا ما لا يفعله Flutter على ويندوز', () {
      expect(windowsBuildNumber('1.0.5+5'), '5');
    });
  });
}
