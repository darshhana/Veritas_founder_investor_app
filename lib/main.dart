import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/dual_login_screen.dart';
import 'screens/auth/founder_login_screen.dart';
import 'screens/founder_dashboard/founder_dashboard_screen.dart';
import 'screens/investor_dashboard/investor_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'VERITAS',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => DualLoginScreen(),
          '/founderLogin': (context) => FounderLoginScreen(),
          '/investorLogin': (context) => DualLoginScreen(),
          '/founderDashboard': (context) => FounderDashboardScreen(),
          '/investorDashboard': (context) => InvestorDashboardScreen(),
        },
      ),
    );
  }
}
