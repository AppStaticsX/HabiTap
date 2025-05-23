import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitap/database/habit_database.dart';
import 'package:habitap/pages/welcome_page.dart';
import 'package:habitap/pages/home_page.dart';
import 'package:habitap/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and HabitDatabase
  await HabitDatabase.initialize();

  // Create a HabitDatabase instance
  final habitDb = HabitDatabase();

  // Save first launch date (for heatmap)
  await habitDb.saveFirstLaunchDate();

  // Explicitly read habits from database on app start
  await habitDb.readHabits();

  // Set Only Portrait Orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => habitDb),
          ChangeNotifierProvider(create: (context) => ThemeProvider())
        ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
  }

  Future<void> _checkWelcomeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final welcomeShown = prefs.getBool('welcomeShown') ?? false;

    // Add a small delay to prevent flashing
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      if (welcomeShown) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while checking welcome status
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}