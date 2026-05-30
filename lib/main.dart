import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
  runApp(SharedExpenseApp(storage: storage));
}

class SharedExpenseApp extends StatelessWidget {
  final dynamic storage;

  const SharedExpenseApp({super.key, this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Expense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
