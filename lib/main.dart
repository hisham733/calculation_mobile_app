import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage_provider.dart';
import 'screens/home_screen.dart';

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
  final themeMode = ThemeMode.values[prefs.getInt('theme_mode') ?? 0];
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
    SharedPreferences.getInstance().then((p) => p.setInt('theme_mode', mode.index));
  }

  @override
  Widget build(BuildContext context) {
    const cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
    const tileShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));

    final lightScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF2C3E50),
      onPrimary: Colors.white,
      secondary: const Color(0xFFC9A94E),
      onSecondary: const Color(0xFF2C1810),
      tertiary: const Color(0xFF8B6F47),
      onTertiary: Colors.white,
      error: const Color(0xFF8B0000),
      onError: Colors.white,
      surface: const Color(0xFFFAF6F0),
      onSurface: const Color(0xFF2C1810),
      surfaceContainerHighest: const Color(0xFFF0E8DC),
      onSurfaceVariant: const Color(0xFF5C5346),
      outline: const Color(0xFFC9C0B3),
      outlineVariant: const Color(0xFFE0D8CC),
      inverseSurface: const Color(0xFF2C1810),
      onInverseSurface: const Color(0xFFFAF6F0),
      inversePrimary: const Color(0xFF8DB4D6),
      shadow: const Color(0xFF2C1810),
      scrim: const Color(0xFF2C1810),
    );

    final darkScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF5D7A9E),
      onPrimary: Colors.white,
      secondary: const Color(0xFFD4B86A),
      onSecondary: const Color(0xFF2C1810),
      tertiary: const Color(0xFFC4956A),
      onTertiary: const Color(0xFF2C1810),
      error: const Color(0xFFD32F2F),
      onError: Colors.white,
      surface: const Color(0xFF1A1A1E),
      onSurface: const Color(0xFFE8E0D8),
      surfaceContainerHighest: const Color(0xFF2C2C30),
      onSurfaceVariant: const Color(0xFFB0A89C),
      outline: const Color(0xFF5C5346),
      outlineVariant: const Color(0xFF3C3428),
      inverseSurface: const Color(0xFFFAF6F0),
      onInverseSurface: const Color(0xFF2C1810),
      inversePrimary: const Color(0xFF2C3E50),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    ThemeData buildTheme(ColorScheme scheme) {
      final isDark = scheme.brightness == Brightness.dark;
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        cardTheme: CardThemeData(
          elevation: 0,
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 8),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: scheme.surface,
          indicatorColor: scheme.primary.withValues(alpha: 0.12),
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary);
            }
            return TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(size: 22, color: scheme.primary);
            }
            return IconThemeData(size: 22, color: scheme.onSurfaceVariant);
          }),
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
