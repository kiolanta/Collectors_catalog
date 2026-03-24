import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/artefacto_welcome_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/collections_provider.dart';
import 'providers/user_collections_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/app_page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://rvumqrizihvkyercdlss.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2dW1xcml6aWh2a3llcmNkbHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NzI0OTUsImV4cCI6MjA4MDM0ODQ5NX0.kJN7Yenghvtti_caYdMyQQkDJNuEifhTgqaLjy4ExfM', // Replace with your Supabase anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CollectionsProvider()), // items
        ChangeNotifierProvider(create: (_) => UserCollectionsProvider()),
      ],
      child: MaterialApp(
        title: 'Artefacto',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: SmoothPageTransitionsBuilder(),
              TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
              TargetPlatform.linux: SmoothPageTransitionsBuilder(),
              TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
              TargetPlatform.windows: SmoothPageTransitionsBuilder(),
            },
          ),
        ),
        home: const ArtefactoWelcomePage(),
      ),
    );
  }
}
