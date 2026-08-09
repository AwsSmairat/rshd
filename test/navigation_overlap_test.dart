import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rshd/core/network/api_client.dart';
import 'package:rshd/core/network/async_load_guard.dart';
import 'package:rshd/core/router/route_page.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';
import 'package:rshd/core/widgets/loading_widget.dart';
import 'package:rshd/core/widgets/opaque_route_surface.dart';
import 'package:rshd/features/grades/data/grades_repository.dart';
import 'package:rshd/features/grades/presentation/grade_details_screen.dart';
import 'package:rshd/features/grades/presentation/grades_controller.dart';
import 'package:rshd/features/notifications/data/notifications_repository.dart';
import 'package:rshd/features/notifications/presentation/notifications_controller.dart';
import 'package:rshd/features/notifications/presentation/notifications_screen.dart';
import 'package:rshd/features/subjects/presentation/subjects_controller.dart';

class _GuardHarness with AsyncLoadGuard {
  int start() => beginLoad();
  bool isCurrent(int generation) => isCurrentLoad(generation);
}

void main() {
  group('OpaqueRouteSurface', () {
    testWidgets('covers the full route bounds with an opaque color', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OpaqueRouteSurface(child: SizedBox.expand(key: Key('inner'))),
        ),
      );

      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('inner')),
      );
      expect(box.size, tester.view.physicalSize / tester.view.devicePixelRatio);
    });
  });

  group('AsyncLoadGuard', () {
    test('ignores stale generations after a newer load starts', () {
      final guard = _GuardHarness();
      final first = guard.start();
      final second = guard.start();

      expect(guard.isCurrent(first), isFalse);
      expect(guard.isCurrent(second), isTrue);
    });
  });

  group('Route overlap regression', () {
    testWidgets(
      'grade details uses header layout instead of AppBar loading stack',
      (tester) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => buildAppRoutePage(
                state: state,
                child: const GradeDetailsScreen(gradeId: 7),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gradeDetailsControllerProvider(
                7,
              ).overrideWith((ref) => _LoadingGradeDetailsController()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pump();

        expect(find.byType(AppBar), findsNothing);
        expect(find.text('تفاصيل الدرجة'), findsOneWidget);
        expect(find.text('جاري تحميل تفاصيل الدرجة...'), findsNothing);
      },
    );

    testWidgets(
      'navigating away while grade load pending does not leave loading on next route',
      (tester) async {
        late GoRouter router;

        router = GoRouter(
          routes: [
            GoRoute(
              path: '/notifications',
              pageBuilder: (context, state) => buildAppRoutePage(
                state: state,
                child: const NotificationsScreen(),
              ),
            ),
            GoRoute(
              path: '/grades/:id',
              pageBuilder: (context, state) => buildAppRoutePage(
                state: state,
                child: GradeDetailsScreen(
                  gradeId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ),
          ],
          initialLocation: '/grades/7',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gradeDetailsControllerProvider(
                7,
              ).overrideWith((ref) => _LoadingGradeDetailsController()),
              notificationsListControllerProvider.overrideWith(
                (ref) => _LoadedNotificationsController(),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pump();
        router.go('/notifications');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(find.text('الإشعارات'), findsOneWidget);
        expect(find.text('جاري تحميل تفاصيل الدرجة...'), findsNothing);
        expect(find.byType(LoadingWidget), findsNothing);
      },
    );
  });
}

class _LoadingGradeDetailsController extends GradeDetailsController {
  _LoadingGradeDetailsController() : super(_FakeGradesRepository());

  @override
  Future<void> load(int gradeId, {cached}) async {
    beginLoad();
    state = state.copyWith(status: FeatureLoadStatus.loading);
  }
}

class _LoadedNotificationsController extends NotificationsListController {
  _LoadedNotificationsController() : super(_FakeNotificationsRepository());

  @override
  Future<void> load({bool refresh = false}) async {
    state = state.copyWith(
      status: FeatureLoadStatus.loaded,
      notifications: const [],
    );
  }
}

class _FakeGradesRepository extends GradesRepository {
  _FakeGradesRepository() : super(apiClient: _FakeApiClient());
}

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository() : super(apiClient: _FakeApiClient());
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(secureStorage: _FakeSecureStorage());

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}
