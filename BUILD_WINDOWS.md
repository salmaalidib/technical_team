# تعليمات بناء نسخة Windows من مشروع technical_team

> **إلى مساعد الـ AI الذي يقرأ هذا الملف:** هذه تعليمات مباشرة لك.
> المشروع هو تطبيق **Flutter** مُهيّأ بالكامل لسطح مكتب Windows. مهمتك: بناء
> ملف تنفيذي `.exe` يعمل على هذا الجهاز (Windows). نفّذ الخطوات بالترتيب،
> وبعد كل أمر تحقّق من النتيجة قبل الانتقال للخطوة التالية. عند أي خطأ راجع
> قسم "معالجة الأخطاء الشائعة" في نهاية الملف.

---

## معلومات المشروع (سياق مهم)

- **النوع:** Flutter desktop app (يدعم Windows / macOS / Linux).
- **نقاط الدخول (flavors):** المشروع لا يستخدم `lib/main.dart` مباشرة، بل:
  - `lib/main_dev.dart` — بيئة التطوير (تحمّل `env/dev.env`). ← **استخدم هذه افتراضياً.**
  - `lib/main_stage.dart` — بيئة الاختبار.
  - `lib/main_prod.dart` — بيئة الإنتاج.
- **ملف الإعدادات:** `env/dev.env` مُدرج كأصل (asset) في `pubspec.yaml` ويُحزَّم تلقائياً.
- **الاعتماديات على سطح المكتب:** نافذة (`window_manager`)، شريط النظام (`tray_manager`)،
  تخزين آمن (`flutter_secure_storage_windows`)، إشعارات محلية
  (`flutter_local_notifications_windows`) — كلها مدعومة على Windows.

---

## المتطلبات المسبقة — تحقّق منها أولاً

نفّذ:
```bat
flutter doctor -v
```

**شرط النجاح:** يجب أن يظهر `[√]` (أو ✓) أمام كلٍّ من:
- **Flutter**
- **Visual Studio** (النسخة 2022 مع حزمة "Desktop development with C++")
- **Windows Version**

إذا ظهر `[!]` أو `[X]` أمام **Visual Studio** → البناء لن ينجح. الحل:
ثبّت **Visual Studio 2022 Community** من https://visualstudio.microsoft.com/downloads/
واختر أثناء التثبيت حزمة **"Desktop development with C++"**، ثم أعد تشغيل `flutter doctor -v`.

---

## خطوات البناء (نفّذها بالترتيب من داخل مجلد المشروع)

### الخطوة 1 — تفعيل منصة Windows
```bat
flutter config --enable-windows-desktop
```
تحقّق: يطبع رسالة تأكيد. (غالباً مفعّلة أصلاً — لا مشكلة إن قال إنها مفعّلة.)

### الخطوة 2 — جلب الحزم
```bat
flutter pub get
```
**شرط النجاح:** ينتهي بـ `Got dependencies!` بدون أخطاء حمراء.

### الخطوة 3 — البناء
```bat
flutter build windows --release --target=lib/main_dev.dart
```
**شرط النجاح:** ينتهي بسطر يشبه:
```
√ Built build\windows\x64\runner\Release\technical_team.exe
```
> ملاحظة: البناء الأول قد يستغرق عدة دقائق (يجمّع كود C++). هذا طبيعي.

---

## التحقّق من الناتج

مكان التطبيق النهائي:
```
build\windows\x64\runner\Release\
```

تحقّق من وجود:
- `technical_team.exe` (الملف التنفيذي)
- `flutter_windows.dll` وملفات DLL أخرى
- مجلد `data\` (يحتوي الأصول وملف `env/dev.env`)

**اختبار سريع:** شغّل `technical_team.exe` بالنقر المزدوج — يجب أن تفتح نافذة التطبيق.

---

## ⚠️ التوزيع — نقطة حرجة

لتشغيل التطبيق على أي جهاز آخر، **يجب نسخ مجلد `Release` كاملاً**، وليس ملف
`.exe` وحده. الملف التنفيذي يعتمد على ملفات DLL ومجلد `data\` المجاورة له،
وبدونها لن يعمل ويظهر خطأ عند التشغيل.

### (اختياري) صنع مُثبِّت واحد للتوزيع الأسهل
```bat
flutter pub add --dev msix
flutter pub run msix:create
```
ينتج ملف `.msix` واحد قابل للتثبيت. (بديل آخر: أداة Inno Setup لصنع مثبّت `.exe`.)

---

## معالجة الأخطاء الشائعة

| الخطأ | السبب | الحل |
|------|-------|------|
| `Building with plugins requires symlink support` | Developer Mode غير مفعّل | نفّذ `start ms-settings:developers` وفعّل **Developer Mode**، ثم أعد البناء. |
| `Visual Studio not found` / خطأ CMake أو MSVC | حزمة C++ ناقصة | ثبّت "Desktop development with C++" في Visual Studio 2022. |
| `Unable to load asset: env/dev.env` عند التشغيل | ملف env مفقود | تأكد أن مجلد `env/` ومحتواه مُنقول مع المشروع، وأنه مُدرج في `pubspec.yaml`. |
| فشل في `flutter pub get` | نسخة Flutter قديمة | نفّذ `flutter upgrade` ثم أعد المحاولة. المشروع يتطلب Dart SDK `>=3.4.1`. |
| التطبيق يفتح ثم يُغلق فوراً | خطأ وقت تشغيل | شغّل الـ `.exe` من نافذة `cmd` لرؤية رسالة الخطأ، أو ابنِ نسخة `--debug` بدل `--release`. |

---

## ملاحظات وظيفية عن التطبيق (ليست مطلوبة للبناء)

- عند "إغلاق" النافذة يبقى التطبيق حيّاً في **شريط النظام (tray)** ليستمر استقبال الإشعارات.
- الإشعارات على Windows تصل عبر **WebSocket** (بديل FCM) — عنوان الخادم من `WS_URL` في `env/dev.env`.
- إذا لم تصل الإشعارات: تأكد أن الجهاز متصل بالإنترنت وأن الخادم في `WS_URL` يعمل.
