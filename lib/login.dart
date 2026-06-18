import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/services/input_validator.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bebezen/manage_navigation.dart';
import 'package:bebezen/signup2.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _pwdCtl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  late SharedPreferences _prefs;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _initPersistence();
  }

  Future<void> _initPersistence() async {
    _prefs = await SharedPreferences.getInstance();
    _rememberMe = _prefs.getBool('remember_me') ?? true;
    if (mounted) setState(() {});

    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(
        _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
        return "Incorrect password or credentials.";
      case 'user-not-found':
        return "No user found with this email.";
      case 'invalid-email':
        return "Invalid email address format.";
      case 'network-request-failed':
        return "Network error. Check your connection.";
      default:
        return "Login failed. Please try again.";
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _pwdCtl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ManageNavigation()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(_mapAuthError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final controller = TextEditingController(text: _emailCtl.text.trim());
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            validator: InputValidator.validateEmail,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || !mounted) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Password reset link sent to $email.');
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e.code));
    }
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _pwdCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(gradient: BebezenPalette.softGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: "logo",
                    child: Image.asset(
                      "assets/images/img.png",
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back",
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  Text(
                    "Sign in to continue your journey",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),

                  BZInput(
                    label: "Email Address",
                    hint: "your@email.com",
                    controller: _emailCtl,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: InputValidator.validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BebezenPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pwdCtl,
                        obscureText: _obscure,
                        validator: (value) {
                          if ((value ?? '').isEmpty)
                            return 'Password is required';
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: BebezenPalette.textSecondary,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: BebezenPalette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  BZButton(
                    label: "Sign In",
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Signup()),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: BebezenPalette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
