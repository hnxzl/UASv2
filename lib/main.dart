import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_service.dart';
import 'auth/auth_page.dart';
import 'pages/dashboard_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vurrrsixronhxfwewoxc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1cnJyc2l4cm9uaHhmd2V3b3hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgxMjI0NjgsImV4cCI6MjA1MzY5ODQ2OH0.dw3w7DC8npfyZA_JnFIKO1srbxDwiWGQXviGWACYAas',
  );

  final supabase = Supabase.instance.client;
  final authService = AuthService(supabase: supabase);

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TodoDo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthStateHandler(authService: authService),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  final AuthService authService;

  const AuthStateHandler({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final supabase = Supabase.instance.client;
    return session != null
        ? DashboardPage(authService: authService, supabase: supabase)
        : AuthPage(authService: authService);
  }
}
