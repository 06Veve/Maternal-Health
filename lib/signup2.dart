import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bebezen/manage_navigation.dart';
import 'package:bebezen/login.dart';
import 'package:bebezen/services/logger.dart';
import 'package:bebezen/services/input_validator.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agree = false;

  final _nameController = TextEditingController();
  final _gestationalAgeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- Helpers ---
  String? _nameValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Name is required";
    if (value.length < 2) return "Please enter a valid name";
    return null;
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Email is required";
    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(value);
    if (!ok) return "Please enter a valid email";
    return null;
  }

  String? _gaValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Gestational age is required";
    final n = int.tryParse(value);
    if (n == null) return "Enter a number between 1 and 42";
    if (n < 1 || n > 42) return "Gestational age must be 1–42 weeks";
    return null;
  }

  String? _pwdValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Password is required";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  String? _confirmPwdValidator(String? v) {
    final value = (v ?? '').trim();
    if (value != _passwordController.text.trim()) return "Passwords do not match";
    return null;
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'weak-password': return "The password provided is too weak";
      case 'email-already-in-use': return "An account already exists for this email";
      case 'invalid-email': return "Please enter a valid email address";
      case 'operation-not-allowed': return "This sign-up method is not enabled";
      case 'too-many-requests': return "Too many attempts. Try again later";
      default: return "Sign up error: $code";
    }
  }

  // Compute LMP and EDD from gestational age at signup
  DateTime _computeLmp(int gaWeeks, DateTime ref) => ref.subtract(Duration(days: gaWeeks * 7));
  DateTime _computeEddFromLmp(DateTime lmp) => lmp.add(const Duration(days: 280));

  Future<void> signup(BuildContext context) async {
    // Cacher le clavier
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must agree to the terms")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) Création compte
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2) Optionnel: définir displayName
      final sanitizedName = InputValidator.sanitizeInput(_nameController.text);
      await cred.user?.updateDisplayName(sanitizedName);

      // 3) Préparation des métadonnées grossesse
      final now = DateTime.now();
      final ga = int.parse(_gestationalAgeController.text.trim()); // validé plus haut
      final lmp = _computeLmp(ga, now);                 // Date des dernières règles estimée
      final edd = _computeEddFromLmp(lmp);              // Date d’accouchement estimée

      // 4) Écriture Firestore (timestamps côté client + serverTimestamp pour traçabilité)
      final uid = cred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': sanitizedName,
        'email': _emailController.text.trim(),
        'profileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),

        // Champs directs utiles pour des requêtes simples
        'gestationalAgeWeeks': ga,
        'gestationalReferenceDate': Timestamp.fromDate(now),

        // Bloc pregnancy structuré pour évoluer plus tard
        'pregnancy': {
          'gestationalAgeAtSignupWeeks': ga,
          'referenceDate': Timestamp.fromDate(now),
          'lmpEstimated': Timestamp.fromDate(lmp),
          'eddEstimated': Timestamp.fromDate(edd),
          'source': 'user_signup_ga_weeks', // pour savoir d’où vient l’info
        },
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text("Your account has been created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // 5) Navigation
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ManageNavigation()),
            (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = _mapAuthError(e.code);
      AppLogger.error('Signup error: ${e.code}', tag: 'Signup', exception: e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ));
    } catch (e, st) {
      if (!mounted) return;
      AppLogger.error(
        'Unexpected signup error',
        tag: 'Signup',
        exception: e,
        stackTrace: st,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gestationalAgeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E9),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/images/rmbglogo1.png", width: 300, height: 150),
                  const SizedBox(height: 16),
                  const Text(
                    "Create an Account",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_circle, color: Colors.pink),
                      hintText: "Enter your name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    validator: _nameValidator,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail, color: Colors.pink),
                      hintText: "Enter your email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 16),

                  // Gestational Age (1–42 weeks) avec UX renforcée
                  TextFormField(
                    controller: _gestationalAgeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.pregnant_woman, color: Colors.pink),
                      hintText: "Gestational Age",
                      helperText: "Enter weeks of pregnancy (1–42) to personalize your experience",
                      suffixText: "weeks",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    validator: _gaValidator,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.pink),
                      hintText: "Create Password (min 6 characters)",
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    validator: _pwdValidator,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isLoading ? null : signup(context),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
                      hintText: "Confirm Password",
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    validator: _confirmPwdValidator,
                  ),

                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _agree,
                    onChanged: _isLoading ? null : (v) => setState(() => _agree = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text("I agree to the Terms and Privacy Policy"),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => signup(context),
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
                          : const Text("Sign Up", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.pink)),
              ),
            ),
        ],
      ),
    );
  }
}