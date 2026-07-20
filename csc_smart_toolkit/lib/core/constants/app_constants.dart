/// App-wide constants for CSC Smart Toolkit
class AppConstants {
  AppConstants._();

  static const String appName = 'CSC Smart Toolkit';
  static const String packageName = 'com.csc.smarttoolkit';
  static const String version = '1.0.0';

  // Asset paths
  static const String splashLogo = 'assets/splash_logo.png';
  static const String appIcon = 'assets/app_icon.png';

  // Splash duration
  static const Duration splashDuration = Duration(seconds: 2);

  // SharedPreferences keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyFavorites = 'favorites';
  static const String keyHistory = 'history';
  static const String keyRecentFiles = 'recent_files';
}
