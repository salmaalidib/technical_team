import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

/// حركات موحّدة لواجهات بناء المعاملات.
///
/// الهدف أن تبدو كل الشاشات في هذه الميزة وكأنها تتحرّك بإيقاع واحد: مدد
/// قصيرة، منحنى واحد، وتتابع (stagger) محدود بسقف حتى لا تتأخر آخر بطاقة في
/// قائمة طويلة عن الظهور.
class AppMotion {
  AppMotion._();

  /// تحوّلات دقيقة داخل عنصر واحد (لون، دوران سهم، ظهور شارة).
  static const Duration fast = Duration(milliseconds: 180);

  /// المدّة الافتراضية: طيّ/فرد، تبديل محتوى، دخول بطاقة.
  static const Duration normal = Duration(milliseconds: 300);

  /// دخول عناصر الصفحة الأولى (ترويسة، شبكة بطاقات).
  static const Duration entrance = Duration(milliseconds: 420);

  /// الفارق الزمني بين كل عنصر والذي يليه في القوائم والشبكات.
  static const Duration stagger = Duration(milliseconds: 55);

  /// منحنى الدخول/الخروج الموحّد.
  static const Curve curve = Curves.easeOutCubic;

  /// تأخير العنصر رقم [index] مع سقف [cap] عنصراً، فالقوائم الطويلة تكتمل
  /// حركتها في وقت معقول بدل أن يظهر آخرها بعد ثوانٍ.
  static Duration delayFor(int index, {int cap = 10}) =>
      stagger * (index > cap ? cap : index);
}

/// دخول متتابع لعنصر داخل قائمة أو شبكة — صعوداً مع تلاشٍ.
///
/// [index] هو ترتيب العنصر، ومنه يُحسب التأخير.
class AppEnter extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration? duration;

  const AppEnter({
    super.key,
    required this.child,
    this.index = 0,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      from: 18,
      duration: duration ?? AppMotion.entrance,
      delay: AppMotion.delayFor(index),
      child: child,
    );
  }
}

/// دخول ترويسة الصفحة — هبوطاً من الأعلى، بلا تأخير.
class AppEnterHeader extends StatelessWidget {
  final Widget child;
  final int index;

  const AppEnterHeader({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      from: 14,
      duration: AppMotion.entrance,
      delay: AppMotion.delayFor(index),
      child: child,
    );
  }
}

/// تبديل ناعم بين حالات المحتوى (تحميل / خطأ / فارغ / بيانات).
///
/// يُشترط أن يحمل كل فرع مفتاحاً مختلفاً كي يلتقط [AnimatedSwitcher] التبديل.
class AppStateSwitcher extends StatelessWidget {
  final Widget child;

  const AppStateSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      // الافتراضي يكدّس الحالتين بمحاذاة المنتصف، وهو ما يقفز بالمحتوى أثناء
      // التبديل؛ التثبيت على الأعلى يُبقي الترويسة ثابتة.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previous,
          if (current != null) current,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// بطاقة ترتفع قليلاً عند المرور فوقها بالمؤشر — للأسطح القابلة للنقر على
/// سطح المكتب والويب. على اللمس لا يصدر حدث hover فتبقى البطاقة ساكنة.
class AppHoverLift extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  /// مقدار الارتفاع بالبكسل.
  final double lift;

  const AppHoverLift({
    super.key,
    required this.child,
    required this.borderRadius,
    this.lift = 3,
  });

  @override
  State<AppHoverLift> createState() => _AppHoverLiftState();
}

class _AppHoverLiftState extends State<AppHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        transform: Matrix4.translationValues(0, _hovered ? -widget.lift : 0, 0),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _hovered ? 0.10 : 0.0,
              ),
              blurRadius: _hovered ? 16 : 0,
              offset: Offset(0, _hovered ? 6 : 0),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
