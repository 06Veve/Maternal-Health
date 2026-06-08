import 'package:flutter/material.dart';
import 'package:bebezen/admin/admin_dashboard.dart';

// 🔐 Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 💾 Optionnel : "Remember me"
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with TickerProviderStateMixin {
  // ========= CONFIG FIREBASE / ROLES (adaptez si besoin) =========
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection des profils
  static const String _userCollection = 'users';

  // Rôles autorisés pour entrer dans le dashboard
  static const Set<String> _allowedRoles = {'admin', };

  // Si vous utilisez une "clé rôle" côté Firestore (champ role_key),
  // changez la valeur ci-dessous. Si le champ n’existe pas sur l’utilisateur,
  // on ne bloque PAS (fallback permissif).


  // ================================================================

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;


  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Demo credentials (uniquement pour le bouton "Show Demo Credentials")
  final String _adminEmail = 'eyanamaeva@gmail.com';
  final String _adminPassword = 'admin123';
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    _animationController.forward();

    _loadRememberedEmail(); // ne change pas le design, juste la logique
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('admin_saved_email');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _emailController.text = saved;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('admin_saved_email', _emailController.text.trim());
    } else {
      await prefs.remove('admin_saved_email');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1) Auth Firebase
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'unknown',
          message: 'Utilisateur introuvable.',
        );
      }

      // 2) Récup profil Firestore
      final doc = await _db.collection(_userCollection).doc(uid).get();

      if (!doc.exists) {
        _showErrorSnackBar(
          "Compte non autorisé (profil absent). Contactez l’administrateur.",
        );
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      final role = (data['role'] as String?)?.toLowerCase();
      final roleKey = data['role_key'] as String?;
      final isActive = (data['is_active'] as bool?) ?? true;

      final hasAllowedRole = role != null && _allowedRoles.contains(role);


      if (!isActive) {
        _showErrorSnackBar("Votre compte est désactivé. Contactez l’admin.");
        setState(() => _isLoading = false);
        return;
      }

      if (!hasAllowedRole ) {
        _showErrorSnackBar("Accès refusé : rôle ou clé invalide.");
        setState(() => _isLoading = false);
        return;
      }

      // 3) Remember me (optionnel)
      await _saveRememberedEmail();

      // 4) Navigation
      if (!mounted) return;
      // 4) Navigation to AdminDashboard
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      switch (e.code) {
        case 'user-not-found':
          _showErrorSnackBar("Aucun compte trouvé avec cet e-mail.");
          break;
        case 'wrong-password':
          _showErrorSnackBar("Mot de passe incorrect.");
          break;
        case 'invalid-email':
          _showErrorSnackBar("E-mail invalide.");
          break;
        case 'user-disabled':
          _showErrorSnackBar("Ce compte est désactivé.");
          break;
        case 'too-many-requests':
          _showErrorSnackBar(
              "Trop de tentatives. Réessayez plus tard ou réinitialisez le mot de passe.");
          break;
        default:
          _showErrorSnackBar(e.message ?? "Échec de connexion.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Erreur inattendue : ${e.toString()}");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDemoCredentials() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Demo Credentials'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Use these credentials to access the admin dashboard:'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: $_adminEmail', style: TextStyle(fontFamily: 'monospace')),
                  Text('Password: $_adminPassword', style: TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _emailController.text = _adminEmail;
              _passwordController.text = _adminPassword;
            },
            child: Text('Fill Form'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚠ DESIGN INCHANGÉ — uniquement correction null-safety (Colors.white)
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade100,
              Colors.pinkAccent,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Card(
                      elevation: 20,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo and Title
                              Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.white, Colors.pink[200]!], // fix null-safety
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pinkAccent.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset("assets/images/rmbglogo1.png", width: 800, height: 210),
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    ' Admin <Dashboard',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Sign in to manage health content',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 40),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),

                              // Remember Me & Forgot Password
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.green,
                                  ),
                                  Text('Remember me'),
                                  Spacer(),
                                  TextButton(
                                    onPressed: () async {
                                      final email = _emailController.text.trim();
                                      if (email.isEmpty || !email.contains('@')) {
                                        _showInfoSnackBar(
                                            'Saisissez un e-mail valide pour réinitialiser.');
                                        return;
                                      }
                                      try {
                                        await _auth.sendPasswordResetEmail(email: email);
                                        _showInfoSnackBar(
                                            'Email de réinitialisation envoyé à $email');
                                      } on FirebaseAuthException catch (e) {
                                        _showErrorSnackBar(
                                            e.message ?? 'Échec d’envoi de l’e-mail.');
                                      }
                                    },
                                    child: Text('Forgot Password?'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),

                              // Login Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink.shade200,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: _isLoading
                                      ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Text('Signing in...', style: TextStyle(fontSize: 16)),
                                    ],
                                  )
                                      : Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              SizedBox(height: 24),

                              // Demo Credentials Button
                              OutlinedButton.icon(
                                onPressed: _showDemoCredentials,
                                icon: Icon(Icons.info_outline),
                                label: Text('Show Demo Credentials'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: BorderSide(color: Colors.green),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}