import 'package:flutter/material.dart';
import 'services/storage_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
