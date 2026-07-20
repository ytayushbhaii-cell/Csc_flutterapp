/// App-wide constants for CSC Smart Toolkit
class AppConstants {
  AppConstants._();

  static const String appName    = 'CSC Smart Toolkit';
  static const String packageName = 'com.csc.smarttoolkit';
  static const String version    = '1.0.0';

  // Asset paths
  static const String splashLogo = 'assets/splash_logo.png';
  static const String appIcon    = 'assets/app_icon.png';

  // Splash duration
  static const Duration splashDuration = Duration(seconds: 2);

  // SQLite database name
  static const String dbName = 'csc_toolkit.db';

  // SharedPreferences keys (kept for migration compatibility)
  static const String keyThemeMode    = 'theme_mode';
  static const String keyFavorites    = 'favorites';
  static const String keyHistory      = 'history';
  static const String keyRecentFiles  = 'recent_files';
  static const String keySearchHistory = 'search_history';
  static const String keyDbMigrated   = 'db_migrated_v1';

  // Output folder options
  static const List<String> outputFolders = ['Downloads', 'Pictures', 'Documents'];

  // History limits
  static const int maxHistoryEntries = 200;
  static const int maxRecentFiles    = 50;
  static const int maxExportHistory  = 500;
  static const int maxSearchHistory  = 12;
}
