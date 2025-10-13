import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:new_project/screens/home_page.dart';
import 'package:new_project/screens/login_page.dart';
import 'package:new_project/provider/pro_login.dart';
import 'package:new_project/provider/location_provider.dart';
import 'package:new_project/provider/lecture_provider.dart';
import 'package:new_project/provider/subcategory_provider.dart';
import 'package:new_project/provider/prayer_times_provider.dart';
import 'package:new_project/database/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // تهيئة قاعدة البيانات وإنشاء حساب مشرف افتراضي
  await _initializeFirebase();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(create: (context) => LectureProvider()),
        ChangeNotifierProvider(create: (context) => SubcategoryProvider()),
        ChangeNotifierProvider(create: (context) => PrayerTimesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// تهيئة Firebase وإنشاء حساب مشرف افتراضي
Future<void> _initializeFirebase() async {
  final firebaseService = FirebaseService();
  
  // تهيئة الفئات الفرعية الافتراضية
  await firebaseService.initializeDefaultSubcategories();
  
  // محاولة إنشاء حساب مشرف افتراضي للاختبار
  // username: admin, password: admin123
  await firebaseService.createAdminAccount(
    username: 'admin',
    email: 'admin@admin.com',
    password: 'admin123',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = true;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'محاضرات',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: const Color(0xFFE4E5D3),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          themeMode: _themeMode,
          home: authProvider.isLoggedIn
              ? HomePage(toggleTheme: toggleTheme)
              : LoginPage(toggleTheme: toggleTheme),
        );
      },
    );
  }
}
