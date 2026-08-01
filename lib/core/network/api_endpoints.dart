class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/login';
  static const register = '/register';
  static const googleAuth = '/auth/google';
  static const appleAuth = '/auth/apple';
  static const verifyEmail = '/email/verify';
  static const resendVerificationEmail = '/email/resend';
  static const logout = '/logout';
  static const me = '/me';
  static const mySubjects = '/my-subjects';
  static const subjectsCatalog = '/subjects';

  static String subjectPurchaseRequest(int subjectId) =>
      '/subjects/$subjectId/purchase-request';

  static String subjectLessons(int subjectId) => '/subjects/$subjectId/lessons';

  static String lessonDetails(int lessonId) => '/lessons/$lessonId';

  static String videoDetails(int videoId) => '/videos/$videoId';

  static String videoProgress(int videoId) => '/videos/$videoId/progress';

  static String fileDetails(int fileId) => '/files/$fileId';

  static String fileAnnotations(int fileId) => '/files/$fileId/annotations';

  static const assignments = '/assignments';

  static String submitAssignment(int assignmentId) =>
      '/assignments/$assignmentId/submit';

  static const quizzes = '/quizzes';

  static String startQuiz(int quizId) => '/quizzes/$quizId/start';

  static String submitQuiz(int quizId) => '/quizzes/$quizId/submit';

  static const grades = '/grades';

  static String gradeDetails(int id) => '/grades/$id';

  static const notifications = '/notifications';

  static String markNotificationRead(int notificationId) =>
      '/notifications/$notificationId/read';

  static const announcements = '/announcements';

  static const publicSettings = '/settings/public';

  /// TODO: Endpoint عام لسياسة الخصوصية عند إضافته في لوحة الإدارة.
  static const privacyPolicy = '/settings/privacy-policy';

  /// TODO: Endpoint عام للشروط عند إضافته في لوحة الإدارة.
  static const termsAndConditions = '/settings/terms-and-conditions';

  static const studentTermsStatus = '/student/terms/status';
  static const studentTermsAccept = '/student/terms/accept';

  static const studentHelpContacts = '/student/help/contacts';
  static const studentHelpMessages = '/student/help/messages';

  static const studentSettings = '/student/settings';
  static const studentProfile = '/student/profile';
  static const studentAvatar = '/student/avatar';
  static const studentPassword = '/student/password';
  static const studentPreferences = '/student/preferences';
  static String studentDevice(int deviceId) => '/student/devices/$deviceId';
  static const studentLogoutAllDevices = '/student/logout-all-devices';
  static const studentDeleteAccount = '/student/account/delete';
}
