import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://urkhxwbrcypgmgkzluto.supabase.co',
    anonKey: 'sb_publishable_bgUp9-NHt4VOSVPtqwu1mQ_doA_O1UW',
  );

  runApp(
    const ProviderScope(
      child: SocialSyncApp(),
    ),
  );
}

class SocialSyncApp extends StatelessWidget {
  const SocialSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocialSync AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: const Color(0xFF0A84FF), // Muted Electric Blue
          tertiary: const Color(0xFFBF5AF2), // Muted Purple Glow
          background: Colors.black,
          surface: const Color(0xFF0A0A0A),
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

