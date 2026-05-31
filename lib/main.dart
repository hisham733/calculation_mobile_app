import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage_provider.dart';
import 'screens/home_screen.dart';

const String kThemeMode = 'theme_mode';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyALtgNFmR2Vn-mIkg__fHg2by7enyPSuLE',
        authDomain: 'masaref-733.firebaseapp.com',
        projectId: 'masaref-733',
        storageBucket: 'masaref-733.firebasestorage.app',
        messagingSenderId: '380013981203',
        appId: '1:380013981203:web:e145ca557945af942d99e6',
        measurementId: 'G-ZNE34226HH',
      ),
    );
  } catch (_) {}
  final storage = createStorage();
  await storage.init();
  final prefs = await SharedPreferences.getInstance();
  final themeMode = ThemeMode.values[prefs.getInt(kThemeMode) ?? 0];
  runApp(SharedExpenseApp(storage: storage, initialTheme: themeMode));
}

class SharedExpenseApp extends StatefulWidget {
  final dynamic storage;
  final ThemeMode initialTheme;

  const SharedExpenseApp({super.key, this.storage, required this.initialTheme});

  static SharedExpenseAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<SharedExpenseAppState>();
  }

  @override
  State<SharedExpenseApp> createState() => SharedExpenseAppState();
}

class SharedExpenseAppState extends State<SharedExpenseApp> {
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    SharedPreferences.getInstance().then((p) => p.setInt(kThemeMode, mode.index));
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF006D77),
      onPrimary: Colors.white,
      secondary: const Color(0xFFFF8C42),
      onSecondary: Colors.white,
      tertiary: const Color(0xFF2D6A4F),
      onTertiary: Colors.white,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: const Color(0xFFFFFCFA),
      onSurface: const Color(0xFF1B1B1F),
      surfaceContainerHighest: const Color(0xFFF2EFE9),
      onSurfaceVariant: const Color(0xFF4A4A4E),
      outline: const Color(0xFF737376),
      outlineVariant: const Color(0xFFC5C3BE),
      inverseSurface: const Color(0xFF303034),
      onInverseSurface: const Color(0xFFF2F0F4),
      inversePrimary: const Color(0xFF8BD4D0),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
    );

    final darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF83C5BE),
      onPrimary: const Color(0xFF00373D),
      secondary: const Color(0xFFFFB07C),
      onSecondary: const Color(0xFF4A1C00),
      tertiary: const Color(0xFF52B788),
      onTertiary: const Color(0xFF003821),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      surface: const Color(0xFF1B1B1F),
      onSurface: const Color(0xFFE5E1E5),
      surfaceContainerHighest: const Color(0xFF2B2B2F),
      onSurfaceVariant: const Color(0xFFC5C3BE),
      outline: const Color(0xFF8F8D91),
      outlineVariant: const Color(0xFF454549),
      inverseSurface: const Color(0xFFE5E1E5),
      onInverseSurface: const Color(0xFF1B1B1F),
      inversePrimary: const Color(0xFF006D77),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
    );

    ThemeData buildTheme(ColorScheme scheme) {
      final isDark = scheme.brightness == Brightness.dark;
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        cardTheme: CardThemeData(
          elevation: 1.5,
          shadowColor: isDark ? Colors.black : scheme.primary.withValues(alpha: 0.12),
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 10),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 2,
          backgroundColor: scheme.surface,
          indicatorColor: scheme.primary,
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimary);
            }
            return TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(size: 22, color: scheme.onPrimary);
            }
            return IconThemeData(size: 22, color: scheme.onSurfaceVariant);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          selectedColor: scheme.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
          secondaryLabelStyle: TextStyle(color: scheme.primary, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        dividerTheme: DividerThemeData(
          space: 1,
          thickness: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            backgroundColor: scheme.surface,
            selectedBackgroundColor: scheme.primary,
            selectedForegroundColor: scheme.onPrimary,
            foregroundColor: scheme.onSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: scheme.inverseSurface,
          contentTextStyle: TextStyle(color: scheme.onInverseSurface),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return scheme.onSurfaceVariant;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary.withValues(alpha: 0.5);
            return scheme.outlineVariant;
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: scheme.primary,
          inactiveTrackColor: scheme.outlineVariant,
          thumbColor: scheme.primary,
          overlayColor: scheme.primary.withValues(alpha: 0.12),
          valueIndicatorColor: scheme.primary,
          valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary),
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      );
    }

    return MaterialApp(
      title: 'Shared Expense',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: buildTheme(lightScheme),
      darkTheme: buildTheme(darkScheme),
      home: const HomeScreen(),
    );
  }
}
