import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/pages/dashboard_pages.dart';

class AuthPage extends StatefulWidget {
  final AuthService authService;

  const AuthPage({super.key, required this.authService});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool isLogin = true;

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void handleAuth() async {
    final email = emailController.text;
    final password = passwordController.text;
    final username = usernameController.text;

    try {
      if (isLogin) {
        await widget.authService.signIn(email: email, password: password);
      } else {
        await widget.authService
            .signUp(email: email, password: password, username: username);
      }

      // Setelah login, pindah ke DashboardPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              authService: widget.authService,
              supabase: Supabase.instance.client,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isLogin)
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleAuth,
              child: Text(isLogin ? 'Login' : 'Sign Up'),
            ),
            TextButton(
              onPressed: toggleMode,
              child: Text(isLogin
                  ? 'Don\'t have an account? Sign up'
                  : 'Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
