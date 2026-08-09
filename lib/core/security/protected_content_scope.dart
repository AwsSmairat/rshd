import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'protected_content_overlay.dart';
import 'screen_protection_provider.dart';
import 'screen_protection_service.dart';

/// Enables native + Flutter screen protection for the subtree lifecycle.
class ProtectedContentScope extends ConsumerStatefulWidget {
  const ProtectedContentScope({super.key, required this.child, this.scopeId});

  final Widget child;

  /// Optional stable id for nested scopes (e.g. route path).
  final String? scopeId;

  @override
  ConsumerState<ProtectedContentScope> createState() =>
      _ProtectedContentScopeState();
}

class _ProtectedContentScopeState extends ConsumerState<ProtectedContentScope> {
  late final String _scopeId;
  bool _acquired = false;
  ScreenProtectionService? _service;

  @override
  void initState() {
    super.initState();
    _scopeId = widget.scopeId ?? UniqueKey().toString();
    WidgetsBinding.instance.addPostFrameCallback((_) => _acquire());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service ??= ref.read(screenProtectionServiceProvider);
  }

  @override
  void dispose() {
    if (_acquired) {
      _acquired = false;
      unawaited(_service?.release(_scopeId, silent: true));
    }
    super.dispose();
  }

  Future<void> _acquire() async {
    if (!mounted || _acquired) return;
    _acquired = true;
    final service = _service ?? ref.read(screenProtectionServiceProvider)!;
    await service.acquire(_scopeId);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldHide = ref.watch(
      screenProtectionServiceProvider.select(
        (service) => service.shouldHideContent,
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: shouldHide, child: widget.child),
        if (shouldHide) const Positioned.fill(child: ProtectedContentOverlay()),
      ],
    );
  }
}

/// Rebuilds only the subtree when protected-content visibility changes.
class ProtectedMediaGate extends ConsumerWidget {
  const ProtectedMediaGate({
    super.key,
    required this.builder,
    required this.hiddenPlaceholder,
  });

  final Widget Function(BuildContext context, bool isBlocked) builder;
  final Widget hiddenPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(
      screenProtectionServiceProvider.select(
        (service) => service.shouldHideContent,
      ),
    );

    if (blocked) {
      return hiddenPlaceholder;
    }

    return builder(context, blocked);
  }
}
