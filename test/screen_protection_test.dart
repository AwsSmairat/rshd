import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/security/protected_content_overlay.dart';
import 'package:rshd/core/security/protected_content_scope.dart';
import 'package:rshd/core/security/screen_protection_platform.dart';
import 'package:rshd/core/security/screen_protection_provider.dart';
import 'package:rshd/core/security/screen_protection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenProtectionService', () {
    late FakeScreenProtectionPlatform fakePlatform;
    late ScreenProtectionService service;

    setUp(() {
      fakePlatform = FakeScreenProtectionPlatform();
      configureScreenProtectionPlatformForTests(fakePlatform);
      service = ScreenProtectionService(platform: fakePlatform);
    });

    tearDown(() {
      service.dispose();
      fakePlatform.dispose();
      configureScreenProtectionPlatformForTests(
        MethodChannelScreenProtectionPlatform(),
      );
    });

    test('acquire enables secure flag once and release disables at zero', () async {
      expect(fakePlatform.secureEnabled, isFalse);

      await service.acquire('video:1');
      expect(fakePlatform.secureEnabled, isTrue);
      expect(service.isProtectionActive, isTrue);

      await service.acquire('pdf:2');
      expect(fakePlatform.secureEnabled, isTrue);

      await service.release('video:1');
      expect(fakePlatform.secureEnabled, isTrue);

      await service.release('pdf:2');
      expect(fakePlatform.secureEnabled, isFalse);
      expect(service.isProtectionActive, isFalse);
    });

    test('capture started hides protected content while active', () async {
      await service.acquire('video:1');
      expect(service.shouldHideContent, isFalse);

      fakePlatform.emit(
        const ScreenProtectionEvent(ScreenProtectionEventType.captureStarted),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.shouldHideContent, isTrue);
      expect(service.isScreenCaptured, isTrue);

      fakePlatform.emit(
        const ScreenProtectionEvent(ScreenProtectionEventType.captureEnded),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.shouldHideContent, isFalse);
      expect(service.isScreenCaptured, isFalse);
    });

    test('privacy overlay appears on inactive lifecycle when protected', () async {
      await service.acquire('pdf:1');

      service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(service.shouldHideContent, isTrue);

      service.clearPrivacyOverlayForResume();
      expect(service.shouldHideContent, isFalse);
    });
  });

  group('ProtectedContentScope', () {
    late FakeScreenProtectionPlatform fakePlatform;
    late ScreenProtectionService service;

    setUp(() {
      fakePlatform = FakeScreenProtectionPlatform();
      configureScreenProtectionPlatformForTests(fakePlatform);
      service = ScreenProtectionService(platform: fakePlatform);
    });

    tearDown(() {
      fakePlatform.dispose();
      configureScreenProtectionPlatformForTests(
        MethodChannelScreenProtectionPlatform(),
      );
    });

    testWidgets('shows overlay when capture is detected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            screenProtectionServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: ProtectedContentScope(
              scopeId: 'video:1',
              child: Text('protected-body'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('protected-body'), findsOneWidget);
      expect(find.text('المحتوى محمي'), findsNothing);

      fakePlatform.emit(
        const ScreenProtectionEvent(ScreenProtectionEventType.captureStarted),
      );
      await tester.pumpAndSettle();

      expect(find.text('المحتوى محمي'), findsOneWidget);
    });

    testWidgets('nested scopes keep protection until all released', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            screenProtectionServiceProvider.overrideWith((ref) => service),
          ],
          child: MaterialApp(
            home: ProtectedContentScope(
              scopeId: 'outer',
              child: ProtectedContentScope(
                scopeId: 'inner',
                child: const Text('nested'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(fakePlatform.secureEnabled, isTrue);
      expect(service.state.activeScopeCount, 2);
    });
  });

  group('ProtectedContentOverlay', () {
    testWidgets('renders Arabic protection copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProtectedContentOverlay(),
        ),
      );

      expect(find.text('المحتوى محمي'), findsOneWidget);
      expect(
        find.text('أوقف تسجيل أو مشاركة الشاشة لعرض المحتوى.'),
        findsOneWidget,
      );
    });
  });
}
