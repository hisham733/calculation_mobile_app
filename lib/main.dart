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
    return MaterialApp(
      title: 'Shared Expense',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
