import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bebezen/manage_navigation.dart';
import 'package:bebezen/signup2.dart';
import 'package:bebezen/services/logger.dart';

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

  // --- Persistence ---
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

    // Web: applique la persistance Firebase selon le choix
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(
        _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    }

    // Si un user est déjà connecté
    final current = FirebaseAuth.instance.currentUser;

    if (current != null) {
      if (_rememberMe) {
        // Auto-redirect (post-frame pour éviter le setState pendant build)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ManageNavigation()),
                (_) => false,
          );
        });
      } else {
        // Flag = false : on évite la reconnexion auto
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  // --- UI helpers ---
  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // --- Network check without extra deps (skipped on Web) ---
  Future<bool> _hasConnection() async {
    if (kIsWeb) return true;
    try {
      final res = await InternetAddress.lookup('one.one.one.one'); // Cloudflare
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
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
      case 'user-disabled':
        return "This account has been disabled.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      case 'network-request-failed':
        return "Network error. Check your internet connection.";
      case 'operation-not-allowed':
        return "This sign-in method is not enabled.";
      case 'weak-password':
        return "Password too weak.";
      case 'email-already-in-use':
        return "An account with this email already exists.";
      case 'account-exists-with-different-credential':
        return "Try a different sign-in method for this email.";
      default:
        return "Login failed. Please try again or contact support.";
    }
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Email required.";
    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(value);
    if (!ok) return "Enter a valid email address.";
    return null;
  }

  String? _pwdValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Password required.";
    if (value.length < 6) return "At least 6 characters.";
    return null;
  }

  Future<void> _resetPassword() async {
    final email = _emailCtl.text.trim();
    if (email.isEmpty) {
      _showDialog('Forgot Password', 'Please enter your email first.');
      return;
    }
    if (_emailValidator(email) != null) {
      _showDialog('Forgot Password', 'Please enter a valid email.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _showDialog('Reset Error', _mapAuthError(e.code));
    } catch (_) {
      _showDialog('Reset Error', 'Unexpected error. Please try again.');
    }
  }

  Future<void> _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate
    if (!_formKey.currentState!.validate()) return;

    // Optional quick connectivity hint
    if (!await _hasConnection()) {
      _toast("No internet connection.");
      // We still try: Firebase will throw a clear error if truly offline.
    }

    setState(() => _isLoading = true);
    final email = _emailCtl.text.trim();
    final pwd = _pwdCtl.text.trim();

    try {
      // Web: applique la persistance avant login selon le choix
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(
          _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pwd,
      );

      final user = cred.user;
      if (user != null && !user.emailVerified) {
        _toast('Email not verified. Some features may be limited.');
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ManageNavigation()),
            (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = _mapAuthError(e.code);
      _showDialog('Login Error', msg);
      AppLogger.error('Firebase auth error: ${e.code}', tag: 'Login', exception: e.message);
    } catch (e, st) {
      if (!mounted) return;
      _showDialog('Login Error', 'Unexpected error. Please try again.');
      AppLogger.error('Unexpected login error', tag: 'Login', exception: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFFFFE4E9),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    const SizedBox(height: 90),
                    Image.asset("assets/images/rmbglogo1.png", width: 300, height: 150),
                    const Text(
                      "Login",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: const Text(
                              "Sign In",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 150,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => Signup()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: const Text("Sign Up", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.mail, color: Colors.pink),
                        hintText: "Enter your email",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _pwdCtl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isLoading ? null : _login(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.pink),
                        hintText: "Enter your password",
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      validator: _pwdValidator,
                    ),

                    // --- Remember me ---
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _rememberMe,
                      onChanged: _isLoading
                          ? null
                          : (v) async {
                        final val = v ?? true;
                        setState(() => _rememberMe = val);
                        await _prefs.setBool('remember_me', val);
                        if (kIsWeb) {
                          await FirebaseAuth.instance.setPersistence(
                            val ? Persistence.LOCAL : Persistence.SESSION,
                          );
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Keep me signed in'),
                    ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 2)),
                        TextButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: const Text(
                            "Forgot Password",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 2)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                            : const Text("Sign In", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.g_mobiledata, size: 40, color: Colors.black),
                        SizedBox(width: 16),
                        Icon(Icons.apple, size: 30, color: Colors.black),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.pink)),
              ),
            ),
        ],
      ),
    );
  }
}