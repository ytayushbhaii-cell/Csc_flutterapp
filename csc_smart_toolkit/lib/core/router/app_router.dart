import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../widgets/common/app_shell.dart';
// Photo Tools
import '../../screens/photo_tools/photo_tools_screen.dart';
import '../../screens/photo_tools/background_remove_screen.dart';
import '../../screens/photo_tools/passport_photo_screen.dart';
import '../../screens/photo_tools/resize_screen.dart';
import '../../screens/photo_tools/compress_screen.dart';
import '../../screens/photo_tools/enhance_screen.dart';
import '../../screens/photo_tools/rotate_screen.dart';
import '../../screens/photo_tools/crop_screen.dart';
import '../../screens/photo_tools/face_center_screen.dart';
import '../../screens/photo_tools/batch_resize_screen.dart';
import '../../screens/photo_tools/color_bg_screen.dart';
import '../../screens/photo_tools/transparent_png_screen.dart';
import '../../services/background_remove_service.dart';
// Document Tools
import '../../screens/document_tools/document_tools_screen.dart';
import '../../screens/document_tools/card_category_screen.dart';
import '../../screens/document_tools/card_crop_screen.dart';
import '../../screens/document_tools/card_copies_screen.dart';
import '../../screens/document_tools/card_front_back_screen.dart';
import '../../screens/document_tools/card_color_correct_screen.dart';
import '../../screens/document_tools/card_from_pdf_screen.dart';
import '../../services/card_service.dart';
// PDF Tools
import '../../screens/document_tools/pdf/pdf_tools_screen.dart';
import '../../screens/document_tools/pdf/merge_pdf_screen.dart';
import '../../screens/document_tools/pdf/split_pdf_screen.dart';
import '../../screens/document_tools/pdf/compress_pdf_screen.dart';
import '../../screens/document_tools/pdf/rotate_pdf_screen.dart';
import '../../screens/document_tools/pdf/extract_pages_screen.dart';
import '../../screens/document_tools/pdf/image_to_pdf_screen.dart';
import '../../screens/document_tools/pdf/pdf_to_image_screen.dart';
import '../../screens/document_tools/pdf/ocr_screen.dart';

// ── Aadhaar category tools ─────────────────────────────────────────────────

const _aadhaarTools = [
  CardToolEntry('Aadhaar Crop', Icons.crop_outlined, Color(0xFF1D4ED8),
      '/document-tools/aadhaar/crop'),
  CardToolEntry('Auto Detect Front', Icons.flip_to_front_outlined,
      Color(0xFF1D4ED8), '/document-tools/aadhaar/auto-front'),
  CardToolEntry('Auto Detect Back', Icons.flip_to_back_outlined,
      Color(0xFF1D4ED8), '/document-tools/aadhaar/auto-back'),
  CardToolEntry('2 Copies (A4)', Icons.copy_outlined, Color(0xFF1D4ED8),
      '/document-tools/aadhaar/2-copies'),
  CardToolEntry('4 Copies (A4)', Icons.copy_all_outlined, Color(0xFF1D4ED8),
      '/document-tools/aadhaar/4-copies'),
  CardToolEntry('6 Copies (A4)', Icons.grid_on_outlined, Color(0xFF1D4ED8),
      '/document-tools/aadhaar/6-copies'),
  CardToolEntry('8 Copies (A4)', Icons.grid_4x4_outlined, Color(0xFF1D4ED8),
      '/document-tools/aadhaar/8-copies'),
  CardToolEntry('A4 Layout', Icons.print_outlined, Color(0xFF1D4ED8),
      '/document-tools/aadhaar/a4-layout'),
  CardToolEntry('Color Correction', Icons.color_lens_outlined,
      Color(0xFF1D4ED8), '/document-tools/aadhaar/color-correct'),
  CardToolEntry('PDF to Aadhaar', Icons.picture_as_pdf_outlined,
      Color(0xFF1D4ED8), '/document-tools/aadhaar/from-pdf'),
  CardToolEntry('Image to Aadhaar', Icons.image_outlined, Color(0xFF1D4ED8),
      '/document-tools/aadhaar/from-image'),
];

const _panTools = [
  CardToolEntry('PAN Crop', Icons.crop_outlined, Color(0xFFD97706),
      '/document-tools/pan/crop'),
  CardToolEntry('Auto Size', Icons.auto_fix_high_outlined, Color(0xFFD97706),
      '/document-tools/pan/auto-size'),
  CardToolEntry('A4 Print', Icons.print_outlined, Color(0xFFD97706),
      '/document-tools/pan/a4-layout'),
  CardToolEntry('Multiple Copies', Icons.copy_all_outlined, Color(0xFFD97706),
      '/document-tools/pan/copies'),
];

const _voterTools = [
  CardToolEntry('Voter ID Crop', Icons.crop_outlined, Color(0xFF059669),
      '/document-tools/voter/crop'),
  CardToolEntry('Voter ID Print (A4)', Icons.print_outlined, Color(0xFF059669),
      '/document-tools/voter/a4-layout'),
];

const _dlTools = [
  CardToolEntry('DL Crop', Icons.crop_outlined, Color(0xFF7C3AED),
      '/document-tools/driving-license/front-crop'),
  CardToolEntry('DL Print (A4)', Icons.print_outlined, Color(0xFF7C3AED),
      '/document-tools/driving-license/a4-layout'),
];

const _passportTools = [
  CardToolEntry('Passport Crop', Icons.crop_outlined, Color(0xFF0891B2),
      '/document-tools/passport/crop'),
  CardToolEntry('Passport Photo Size', Icons.badge_outlined, Color(0xFF0891B2),
      '/document-tools/passport/photo-size'),
  CardToolEntry('Passport Print', Icons.print_outlined, Color(0xFF0891B2),
      '/document-tools/passport/print'),
];

// ── Router ────────────────────────────────────────────────────────────────

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  routes: [
    // ── Splash ────────────────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen()),
    ),

    // ── Search (no shell) ─────────────────────────────────────────────────
    GoRoute(
      path: '/search',
      pageBuilder: (_, __) => const NoTransitionPage(child: SearchScreen()),
    ),

    // ── Photo Tools ───────────────────────────────────────────────────────
    GoRoute(
      path: '/photo-tools',
      pageBuilder: (_, __) =>
          const NoTransitionPage(child: PhotoToolsScreen()),
      routes: [
        GoRoute(
          path: 'background-remove',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: BackgroundRemoveScreen()),
        ),
        GoRoute(
          path: 'passport-photo',
          pageBuilder: (_, __) => const NoTransitionPage(
              child: PassportPhotoScreen(initialTab: 0)),
        ),
        GoRoute(
          path: 'visa-photo',
          pageBuilder: (_, __) => const NoTransitionPage(
              child: PassportPhotoScreen(initialTab: 1)),
        ),
        GoRoute(
          path: 'stamp-photo',
          pageBuilder: (_, __) => const NoTransitionPage(
              child: PassportPhotoScreen(initialTab: 2)),
        ),
        GoRoute(
          path: 'resize',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: ResizeScreen()),
        ),
        GoRoute(
          path: 'compress',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: CompressScreen()),
        ),
        GoRoute(
          path: 'enhance',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: EnhanceScreen(initialTab: 0)),
        ),
        GoRoute(
          path: 'brightness',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: EnhanceScreen(initialTab: 0)),
        ),
        GoRoute(
          path: 'contrast',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: EnhanceScreen(initialTab: 0)),
        ),
        GoRoute(
          path: 'sharpen',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: EnhanceScreen(initialTab: 0)),
        ),
        GoRoute(
          path: 'rotate',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: RotateScreen(initialTab: 0)),
        ),
        GoRoute(
          path: 'mirror',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: RotateScreen(initialTab: 1)),
        ),
        GoRoute(
          path: 'crop',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: CropScreen()),
        ),
        GoRoute(
          path: 'face-center',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: FaceCenterScreen()),
        ),
        GoRoute(
          path: 'batch-resize',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: BatchResizeScreen()),
        ),
        GoRoute(
          path: 'white-background',
          pageBuilder: (_, __) => const NoTransitionPage(
              child: ColorBgScreen(bgFill: BgFill.white)),
        ),
        GoRoute(
          path: 'blue-background',
          pageBuilder: (_, __) => const NoTransitionPage(
              child: ColorBgScreen(bgFill: BgFill.blue)),
        ),
        GoRoute(
          path: 'red-background',
          pageBuilder: (_, __) => const NoTransitionPage(
              child: ColorBgScreen(bgFill: BgFill.red)),
        ),
        GoRoute(
          path: 'transparent-png',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: TransparentPngScreen()),
        ),
      ],
    ),

    // ── Document Tools ────────────────────────────────────────────────────
    GoRoute(
      path: '/document-tools',
      pageBuilder: (_, __) =>
          const NoTransitionPage(child: DocumentToolsScreen()),
      routes: [
        // ── Aadhaar ─────────────────────────────────────────────────────
        GoRoute(
          path: 'aadhaar',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: CardCategoryScreen(
              title: 'Aadhaar Tools',
              color: Color(0xFF1D4ED8),
              tools: _aadhaarTools,
            ),
          ),
          routes: [
            GoRoute(
              path: 'crop',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCropScreen(
                  title: 'Aadhaar Crop',
                  toolId: 'aadhaar-crop',
                  cardType: CardType.aadhaar,
                ),
              ),
            ),
            GoRoute(
              path: 'auto-front',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardFrontBackScreen(
                  title: 'Auto Detect Front & Back',
                  toolId: 'aadhaar-auto-front',
                  cardType: CardType.aadhaar,
                ),
              ),
            ),
            GoRoute(
              path: 'auto-back',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardFrontBackScreen(
                  title: 'Auto Detect Back & Front',
                  toolId: 'aadhaar-auto-back',
                  cardType: CardType.aadhaar,
                ),
              ),
            ),
            GoRoute(
              path: 'front-back',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardFrontBackScreen(
                  title: 'Aadhaar Front & Back',
                  toolId: 'aadhaar-front-back',
                  cardType: CardType.aadhaar,
                ),
              ),
            ),
            GoRoute(
              path: '2-copies',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Aadhaar 2 Copies',
                  toolId: 'aadhaar-2-copies',
                  cardType: CardType.aadhaar,
                  initialCopies: 2,
                ),
              ),
            ),
            GoRoute(
              path: '4-copies',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Aadhaar 4 Copies',
                  toolId: 'aadhaar-4-copies',
                  cardType: CardType.aadhaar,
                  initialCopies: 4,
                ),
              ),
            ),
            GoRoute(
              path: '6-copies',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Aadhaar 6 Copies',
                  toolId: 'aadhaar-6-copies',
                  cardType: CardType.aadhaar,
                  initialCopies: 6,
                ),
              ),
            ),
            GoRoute(
              path: '8-copies',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Aadhaar 8 Copies',
                  toolId: 'aadhaar-8-copies',
                  cardType: CardType.aadhaar,
                  initialCopies: 8,
                ),
              ),
            ),
            GoRoute(
              path: 'a4-layout',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Aadhaar A4 Layout',
                  toolId: 'aadhaar-a4',
                  cardType: CardType.aadhaar,
                  initialCopies: 4,
                ),
              ),
            ),
            GoRoute(
              path: 'color-correct',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardColorCorrectScreen(
                  title: 'Aadhaar Color Correction',
                  toolId: 'aadhaar-color-correct',
                  cardType: CardType.aadhaar,
                ),
              ),
            ),
            GoRoute(
              path: 'from-pdf',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardFromPdfScreen(
                  title: 'PDF to Aadhaar',
                  toolId: 'aadhaar-from-pdf',
                  cardType: CardType.aadhaar,
                ),
              ),
            ),
            GoRoute(
              path: 'from-image',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCropScreen(
                  title: 'Image to Aadhaar',
                  toolId: 'aadhaar-from-image',
                  cardType: CardType.aadhaar,
                  processLabel: 'Extract Aadhaar',
                ),
              ),
            ),
          ],
        ),

        // ── PAN ──────────────────────────────────────────────────────────
        GoRoute(
          path: 'pan',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: CardCategoryScreen(
              title: 'PAN Card Tools',
              color: Color(0xFFD97706),
              tools: _panTools,
            ),
          ),
          routes: [
            GoRoute(
              path: 'crop',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCropScreen(
                  title: 'PAN Card Crop',
                  toolId: 'pan-crop',
                  cardType: CardType.pan,
                ),
              ),
            ),
            GoRoute(
              path: 'auto-size',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCropScreen(
                  title: 'PAN Auto Size',
                  toolId: 'pan-auto-size',
                  cardType: CardType.pan,
                  processLabel: 'Auto Size to PAN',
                ),
              ),
            ),
            GoRoute(
              path: 'a4-layout',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'PAN A4 Print',
                  toolId: 'pan-a4',
                  cardType: CardType.pan,
                  initialCopies: 4,
                ),
              ),
            ),
            GoRoute(
              path: 'copies',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'PAN Multiple Copies',
                  toolId: 'pan-copies',
                  cardType: CardType.pan,
                  initialCopies: 4,
                ),
              ),
            ),
          ],
        ),

        // ── Voter ─────────────────────────────────────────────────────────
        GoRoute(
          path: 'voter',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: CardCategoryScreen(
              title: 'Voter ID Tools',
              color: Color(0xFF059669),
              tools: _voterTools,
            ),
          ),
          routes: [
            GoRoute(
              path: 'crop',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCropScreen(
                  title: 'Voter ID Crop',
                  toolId: 'voter-crop',
                  cardType: CardType.voter,
                ),
              ),
            ),
            GoRoute(
              path: 'a4-layout',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Voter ID A4 Layout',
                  toolId: 'voter-a4',
                  cardType: CardType.voter,
                  initialCopies: 4,
                ),
              ),
            ),
          ],
        ),

        // ── Driving License ───────────────────────────────────────────────
        GoRoute(
          path: 'driving-license',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: CardCategoryScreen(
              title: 'Driving License',
              color: Color(0xFF7C3AED),
              tools: _dlTools,
            ),
          ),
          routes: [
            GoRoute(
              path: 'front-crop',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCropScreen(
                  title: 'DL Crop',
                  toolId: 'dl-crop',
                  cardType: CardType.drivingLicense,
                ),
              ),
            ),
            GoRoute(
              path: 'a4-layout',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'DL A4 Layout',
                  toolId: 'dl-a4',
                  cardType: CardType.drivingLicense,
                  initialCopies: 4,
                ),
              ),
            ),
          ],
        ),

        // ── Passport ─────────────────────────────────────────────────────
        GoRoute(
          path: 'passport',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: CardCategoryScreen(
              title: 'Passport Tools',
              color: Color(0xFF0891B2),
              tools: _passportTools,
            ),
          ),
          routes: [
            GoRoute(
              path: 'crop',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCropScreen(
                  title: 'Passport Crop',
                  toolId: 'passport-crop',
                  cardType: CardType.passport,
                ),
              ),
            ),
            GoRoute(
              path: 'a4-layout',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Passport A4 Layout',
                  toolId: 'passport-a4',
                  cardType: CardType.passport,
                  initialCopies: 4,
                ),
              ),
            ),
            GoRoute(
              path: 'photo-size',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Passport Photo Size',
                  toolId: 'passport-photo-size',
                  cardType: CardType.passport,
                  initialCopies: 2,
                ),
              ),
            ),
            GoRoute(
              path: 'print',
              pageBuilder: (_, __) => const NoTransitionPage(
                child: CardCopiesScreen(
                  title: 'Passport Print',
                  toolId: 'passport-print',
                  cardType: CardType.passport,
                  initialCopies: 4,
                ),
              ),
            ),
          ],
        ),

        // ── PDF Tools ─────────────────────────────────────────────────────
        GoRoute(
          path: 'pdf',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: PDFToolsScreen()),
          routes: [
            GoRoute(
              path: 'merge',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: MergePDFScreen()),
            ),
            GoRoute(
              path: 'split',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SplitPDFScreen()),
            ),
            GoRoute(
              path: 'compress',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: CompressPDFScreen()),
            ),
            GoRoute(
              path: 'rotate',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: RotatePDFScreen()),
            ),
            GoRoute(
              path: 'extract',
              pageBuilder: (_, __) => const NoTransitionPage(
                  child: ExtractPagesScreen(deleteMode: false)),
            ),
            GoRoute(
              path: 'delete-pages',
              pageBuilder: (_, __) => const NoTransitionPage(
                  child: ExtractPagesScreen(deleteMode: true)),
            ),
            GoRoute(
              path: 'from-image',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: ImageToPDFScreen()),
            ),
            GoRoute(
              path: 'to-image',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: PDFToImageScreen()),
            ),
            GoRoute(
              path: 'ocr',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: OCRScreen()),
            ),
          ],
        ),
      ],
    ),

    // ── Main shell ────────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/favorites',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: FavoritesScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/history',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ]),
      ],
    ),
  ],
);
