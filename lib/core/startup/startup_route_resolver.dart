import '../../features/auth/presentation/auth_controller.dart';
import '../platform/platform_settings.dart';
import '../router/app_router.dart';

/// Resolves the post-splash destination from auth + platform settings.
String? resolveStartupRoute({
  required AuthState authState,
  required PlatformSettings? platformSettings,
  bool onboardingCompleted = false,
}) {
  if (platformSettings?.maintenanceMode == true) {
    return AppRoutes.maintenance;
  }

  switch (authState.status) {
    case AuthStatus.authenticated:
      final user = authState.user;
      if (user != null && !user.isStudent) {
        return AppRoutes.login;
      }
      if (user != null && !user.isEmailVerified) {
        return '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(user.email)}';
      }
      return AppRoutes.home;
    case AuthStatus.unauthenticated:
    case AuthStatus.error:
      final pendingEmail = authState.pendingVerificationEmail;
      if (pendingEmail != null) {
        return '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(pendingEmail)}';
      }
      if (!onboardingCompleted) {
        return AppRoutes.onboarding;
      }
      return AppRoutes.login;
    case AuthStatus.initial:
    case AuthStatus.loading:
    case AuthStatus.authenticating:
      return null;
  }
}

bool isStartupAuthDecisionReady(AuthState authState) {
  switch (authState.status) {
    case AuthStatus.authenticated:
    case AuthStatus.unauthenticated:
    case AuthStatus.error:
      return true;
    case AuthStatus.initial:
    case AuthStatus.loading:
    case AuthStatus.authenticating:
      return false;
  }
}
