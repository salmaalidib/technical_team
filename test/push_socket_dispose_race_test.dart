import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technical_team/core/services/notification_service.dart';
import 'package:technical_team/core/services/push_socket.dart';
import 'package:technical_team/core/services/token_refresh_service.dart';
import 'package:technical_team/core/storage/secure_storage_service.dart';

/// تخزين وهمي يُبطئ قراءة التوكن كي نتحكّم بنافذة التعليق داخل `_connect()`.
class _SlowStorage extends SecureStorageService {
  _SlowStorage(this.delay);
  final Duration delay;

  @override
  Future<String?> getToken() async {
    await Future<void>.delayed(delay);
    return 'fake-token';
  }
}

/// خدمة عرض وهمية لا تلمس قنوات المنصّة الأصلية أثناء الاختبار.
class _NoopNotifications extends NotificationService {
  _NoopNotifications() : super.test();
}

/// خدمة تجديد وهمية لا تُجري أي شبكة (هذه الاختبارات لا تلمس مسار التجديد).
class _FakeRefresh extends TokenRefreshService {
  _FakeRefresh(SecureStorageService storage) : super(storage: storage);

  @override
  Future<bool> refresh() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late int port;
  var liveSockets = 0;

  setUp(() async {
    liveSockets = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = server.port;
    server.listen((req) async {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        liveSockets++;
        ws.listen((_) {}, onDone: () => liveSockets--, onError: (_) {});
      } else {
        req.response.statusCode = HttpStatus.badRequest;
        await req.response.close();
      }
    });
    dotenv.loadFromString(envString: 'WS_URL=ws://127.0.0.1:$port/ws');
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('dispose() أثناء _connect() المعلّق لا يترك اتصالًا/مؤقّتًا شبحيًّا', () async {
    final storage = _SlowStorage(const Duration(milliseconds: 300));
    final socket = PushSocket(
      storage: storage,
      refreshService: _FakeRefresh(storage),
      notifications: _NoopNotifications(),
    );

    // ابدأ الاتصال (سيعلّق على getToken لمدّة 300ms) ثم أوقفه أثناء التعليق.
    unawaited(socket.start());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await socket.dispose();

    // امنح المحاولة المعلّقة وقتًا لتستأنف بعد انقضاء تأخير التوكن.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // لو فاز السباق على dispose لبقي اتصال مفتوح على الخادم.
    expect(liveSockets, 0,
        reason: 'يجب ألّا يبقى أي WebSocket مفتوح بعد dispose أثناء الاتصال.');
  });

  test('dispose بعد اتصال ناجح يُغلق القناة', () async {
    final storage = _SlowStorage(Duration.zero);
    final socket = PushSocket(
      storage: storage,
      refreshService: _FakeRefresh(storage),
      notifications: _NoopNotifications(),
    );

    await socket.start();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(liveSockets, 1, reason: 'يجب أن يكون الاتصال قائمًا بعد start.');

    await socket.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(liveSockets, 0, reason: 'يجب أن يُغلق dispose القناة المفتوحة.');
  });
}
