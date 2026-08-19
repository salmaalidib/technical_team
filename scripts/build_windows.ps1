<#
    يبني نسخة ويندوز ويصنع المثبِّت، مع اشتقاق رقم الإصدار من pubspec.yaml
    كمصدر وحيد للحقيقة.

    سبب وجود هذا السكربت: كان الرقم مكتوباً يدوياً في ثلاثة مواضع (pubspec.yaml،
    MyAppVersion، OutputBaseFilename) فتباعدت. والأخطر أن رقم البناء لم يكن
    يصل إلى التطبيق إطلاقاً على ويندوز — راجع التعليق المطوّل في
    lib/features/app_update/di/injection.dart — فكان يُرسَل 0 دائماً وتتكرّر
    شاشة التحديث الإجباري بلا نهاية. تمرير APP_VERSION_CODE هنا هو ما يمنع ذلك.

    الاستخدام:
        powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1
        powershell ... -File scripts\build_windows.ps1 -Target lib\main_dev.dart -SkipInstaller
#>
[CmdletBinding()]
param(
    [string]$Target = 'lib/main_dev.dart',
    [switch]$SkipInstaller
)

$ErrorActionPreference = 'Stop'

# جذر المشروع = المجلد الأب لمجلد scripts، أياً كان مكان استدعاء السكربت منه.
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# ---- 1) اقرأ "version: X.Y.Z+N" من pubspec.yaml -----------------------------
$pubspec = Join-Path $projectRoot 'pubspec.yaml'
if (-not (Test-Path $pubspec)) { throw "pubspec.yaml غير موجود في $projectRoot" }

$versionLine = Select-String -Path $pubspec -Pattern '^version:\s*(.+)$' |
               Select-Object -First 1
if (-not $versionLine) { throw 'تعذّر العثور على سطر version في pubspec.yaml' }

$rawVersion = $versionLine.Matches[0].Groups[1].Value.Trim()
if ($rawVersion -notmatch '^(?<name>\d+\.\d+\.\d+)\+(?<code>\d+)$') {
    throw "صيغة الإصدار غير متوقَّعة: '$rawVersion' — المطلوب X.Y.Z+N (مثال 1.0.5+5)"
}
$versionName = $Matches['name']
$versionCode = [int]$Matches['code']

Write-Host "الإصدار: $versionName (version_code = $versionCode)" -ForegroundColor Cyan

# ---- 2) ابنِ التطبيق مع حقن رقم البناء --------------------------------------
Write-Host 'flutter pub get ...' -ForegroundColor Cyan
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw "فشل flutter pub get (رمز $LASTEXITCODE)" }

Write-Host 'flutter build windows ...' -ForegroundColor Cyan
& flutter build windows --release --target=$Target `
    --dart-define=APP_VERSION_CODE=$versionCode
if ($LASTEXITCODE -ne 0) { throw "فشل بناء ويندوز (رمز $LASTEXITCODE)" }

$exePath = Join-Path $projectRoot 'build\windows\x64\runner\Release\technical_team.exe'
if (-not (Test-Path $exePath)) { throw "لم يُنتَج الملف التنفيذي: $exePath" }
Write-Host "تم البناء: $exePath" -ForegroundColor Green

if ($SkipInstaller) {
    Write-Host 'تم تخطّي صنع المثبِّت (-SkipInstaller).' -ForegroundColor Yellow
    exit 0
}

# ---- 3) اصنع المثبِّت بنفس رقم الإصدار --------------------------------------
$iscc = Get-Command iscc.exe -ErrorAction SilentlyContinue
if (-not $iscc) {
    foreach ($candidate in @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )) {
        if (Test-Path $candidate) { $iscc = $candidate; break }
    }
} else {
    $iscc = $iscc.Source
}

if (-not $iscc) {
    Write-Warning 'Inno Setup (ISCC.exe) غير موجود — تم تخطّي صنع المثبِّت.'
    Write-Warning 'ثبّته من https://jrsoftware.org/isdl.php ثم أعد التشغيل.'
    exit 0
}

Write-Host 'صنع المثبِّت ...' -ForegroundColor Cyan
& $iscc "/DMyAppVersion=$versionName" (Join-Path $projectRoot 'installer\technical_team.iss')
if ($LASTEXITCODE -ne 0) { throw "فشل صنع المثبِّت (رمز $LASTEXITCODE)" }

$setupPath = Join-Path $projectRoot "dist\TechnicalTeam-Setup-$versionName.exe"
Write-Host "تم إنتاج المثبِّت: $setupPath" -ForegroundColor Green
Write-Host ''
Write-Host 'الخطوة التالية: ارفع الملف ثم سجّل الإصدار على الخادم بـ' -ForegroundColor Yellow
Write-Host "  version_name=$versionName  version_code=$versionCode" -ForegroundColor Yellow
