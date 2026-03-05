/// Centralized string constants for the HoWealthy app.
///
/// All user-facing strings that were previously hardcoded across
/// multiple screens are now consolidated here for maintainability
/// and future i18n support.
class AppStrings {
  AppStrings._(); // Prevent instantiation

  // --- App Identity ---
  static const String appName = 'HoWealthy';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Making every Indian their own CFO';
  static const String oracleTitle = 'The Oracle';

  // --- Dashboard ---
  static const String drawerTitle = 'Howealthy Oracle';
  static const String versionDisplay = 'v$appVersion';

  // --- Error States ---
  static const String genericErrorTitle = 'Something went wrong';
  static const String genericErrorMessage =
      'We hit a snag loading your data. Please check your connection and try again.';
  static const String retryButton = 'Retry';

  // --- Empty States ---
  static const String noTransactionsTitle = 'No transactions yet';
  static const String noTransactionsMessage =
      'Grant SMS permissions to automatically track your spending, or add transactions manually.';
  static const String grantPermissions = 'Grant Permissions';

  // --- Settings ---
  static const String settingsTitle = 'Environmental Controls';
  static const String defaultUserName = 'User';

  // --- Login ---
  static const String loginSubtitle = 'Sync your data to the cloud';
  static const String signInWithGoogle = 'Sign in with Google';
}
