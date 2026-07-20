import 'package:flutter/material.dart';

/// Maps MaterialCommunityIcons names (used in the Expo app) to Flutter IconData.
const Map<String, IconData> _mciMap = {
  // Navigation
  'view-dashboard-outline': Icons.dashboard_outlined,
  'tools': Icons.construction_outlined,
  'image-multiple': Icons.photo_library_outlined,
  'magnify': Icons.search,
  'heart-outline': Icons.favorite_border,
  'heart': Icons.favorite,
  'clock-outline': Icons.access_time_outlined,
  'chart-bar': Icons.bar_chart,
  'history': Icons.history,
  'cog-outline': Icons.settings_outlined,
  'menu': Icons.menu,
  // Photo Tools
  'image-filter-none': Icons.image_outlined,
  'image-size-select-large': Icons.photo_size_select_large_outlined,
  'zip-box-outline': Icons.compress,
  'crop': Icons.crop,
  'rotate-left': Icons.rotate_left,
  'flip-horizontal': Icons.flip,
  'watermark': Icons.branding_watermark_outlined,
  'face-recognition': Icons.face_outlined,
  'color-filter-outline': Icons.color_lens_outlined,
  'magnify-plus-outline': Icons.zoom_in,
  'mirror': Icons.flip,
  'image-search-outline': Icons.image_search,
  'blur': Icons.blur_on,
  'transparent': Icons.layers_clear_outlined,
  'white-balance-sunny': Icons.wb_sunny_outlined,
  // Document & ID Tools
  'card-account-details': Icons.badge_outlined,
  'file-pdf-box': Icons.picture_as_pdf,
  'passport': Icons.airplane_ticket_outlined,
  'file-document-outline': Icons.description_outlined,
  'printer': Icons.print_outlined,
  'merge': Icons.merge,
  'scissors-cutting': Icons.content_cut,
  'lock-outline': Icons.lock_outlined,
  'lock-open-outline': Icons.lock_open_outlined,
  'page-next-outline': Icons.chevron_right,
  'rotate-right': Icons.rotate_right,
  'text-search': Icons.manage_search,
  'rename-box': Icons.drive_file_rename_outline_outlined,
  'delete-outline': Icons.delete_outlined,
  'information-outline': Icons.info_outlined,
  'ocr': Icons.document_scanner_outlined,
  // QR / Barcode
  'qrcode': Icons.qr_code,
  'qrcode-scan': Icons.qr_code_scanner,
  'barcode': Icons.view_week_outlined,
  'barcode-scan': Icons.document_scanner_outlined,
  // Signature / Stamp / Draw
  'draw': Icons.draw_outlined,
  'stamper': Icons.approval_outlined,
  'pencil-outline': Icons.edit_outlined,
  // Utility
  'calculator': Icons.calculate_outlined,
  'calendar': Icons.calendar_today_outlined,
  'percent': Icons.percent,
  'folder-outline': Icons.folder_outlined,
  // Settings
  'palette-outline': Icons.palette_outlined,
  'translate': Icons.translate,
  'printer-outline': Icons.print_outlined,
  'backup-restore': Icons.backup_outlined,
  'shield-check-outline': Icons.security,
  'wifi-off': Icons.wifi_off,
  'weather-night': Icons.dark_mode_outlined,
  'weather-sunny': Icons.light_mode_outlined,
  // Generic
  'rocket-launch-outline': Icons.rocket_launch_outlined,
  'database-outline': Icons.storage_outlined,
  'delete-sweep-outline': Icons.delete_sweep_outlined,
};

IconData mciIcon(String name, {IconData fallback = Icons.widgets_outlined}) =>
    _mciMap[name] ?? fallback;
