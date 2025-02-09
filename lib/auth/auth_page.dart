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
    setState(() => isLogin = !isLogin);
  }

  void handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    try {
      if (isLogin) {
        await widget.authService.signIn(email: email, password: password);
      } else {
        await widget.authService
            .signUp(email: email, password: password, username: username);
      }

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
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isLogin ? 'Login' : 'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5FB2FF),
                ),
              ),
              const SizedBox(height: 20),
              if (!isLogin)
                _buildTextField(
                    controller: usernameController, label: 'Username'),
              _buildTextField(
                  controller: emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress),
              _buildTextField(
                  controller: passwordController,
                  label: 'Password',
                  obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5FB2FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(isLogin ? 'Login' : 'Sign Up',
                    style: TextStyle(fontSize: 16)),
              ),
              TextButton(
                onPressed: toggleMode,
                child: Text(
                  isLogin
                      ? 'Don\'t have an account? Sign up'
                      : 'Already have an account? Login',
                  style: TextStyle(color: Color(0xFF5FB2FF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5FB2FF), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
