import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('protected content routes are registered with screen protection', () {
    final inventory =
        jsonDecode(
              File(
                'security/inventory/protected-features.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    final routes = (inventory['routes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(routes.length, greaterThanOrEqualTo(6));

    for (final route in routes) {
      expect(route['screen_protection'], isTrue);
      expect(route['path'], isNotEmpty);
    }
  });

  test('app router wraps protected routes with ProtectedContentScope', () {
    final routerSource = File(
      'lib/core/router/app_router.dart',
    ).readAsStringSync();

    expect(routerSource.contains('ProtectedContentScope'), isTrue);
    expect(routerSource.contains('_protectedContent('), isTrue);
    expect(
      RegExp(r'_protectedContent\(').allMatches(routerSource).length,
      greaterThanOrEqualTo(6),
    );
  });
}
