import 'package:bebezen/admin/admin_dashboard.dart';
import 'package:bebezen/admin/admin_service.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAccessGate extends StatelessWidget {
  const AdminAccessGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const _AdminLoading();
        }
        final user = auth.data;
        if (user == null) return const AdminLoginPage();
        return FutureBuilder<bool>(
          future: AdminService().isCurrentUserAdmin(),
          builder: (context, access) {
            if (access.connectionState != ConnectionState.done) {
              return const _AdminLoading();
            }
            if (access.hasError || access.data != true) {
              return _UnauthorizedAccount(
                email: user.email ?? 'Unknown',
                uid: user.uid,
                error: access.error,
              );
            }
            return const AdminDashboard();
          },
        );
      },
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberEmail = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _restoreEmail();
  }

  Future<void> _restoreEmail() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString('admin_saved_email');
    if (!mounted || email == null) return;
    setState(() {
      _emailController.text = email;
      _rememberEmail = true;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final preferences = await SharedPreferences.getInstance();
      if (_rememberEmail) {
        await preferences.setString(
          'admin_saved_email',
          _emailController.text.trim(),
        );
      } else {
        await preferences.remove('admin_saved_email');
      }
    } on FirebaseAuthException catch (error) {
      _showError(_authMessage(error));
    } catch (_) {
      _showError('Connexion impossible. Vérifiez le réseau et réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email ou mot de passe incorrect.',
      'invalid-email' => 'Adresse email invalide.',
      'user-disabled' => 'Ce compte Firebase est désactivé.',
      'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
      _ => error.message ?? 'Échec de la connexion.',
    };
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _showError('Saisissez d’abord une adresse email valide.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé.')),
      );
    } on FirebaseAuthException catch (error) {
      _showError(_authMessage(error));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFE7E8EE)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: BebezenPalette.primaryLight,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 34,
                            color: BebezenPalette.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Bebezen Admin',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Administration web et desktop',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF737789)),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email administrateur',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) => (value ?? '').trim().contains('@')
                            ? null
                            : 'Saisissez une adresse email valide',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value ?? '').length >= 6
                            ? null
                            : 'Le mot de passe doit contenir au moins 6 caractères',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberEmail,
                            onChanged: (value) =>
                                setState(() => _rememberEmail = value ?? false),
                          ),
                          const Text('Mémoriser l’email'),
                          const Spacer(),
                          TextButton(
                            onPressed: _resetPassword,
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _loading ? null : _login,
                        icon: _loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(_loading ? 'Connexion…' : 'Se connecter'),
                      ),
                    ],
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

class _UnauthorizedAccount extends StatelessWidget {
  const _UnauthorizedAccount({
    required this.email,
    required this.uid,
    this.error,
  });

  final String email;
  final String uid;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Accès administrateur refusé',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('$email ne possède pas les droits nécessaires.'),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxWidth: 620),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BebezenPalette.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(
                  error == null
                      ? 'Vérifiez dans Firestore :\n'
                            'admins/$uid\n'
                            'active = true (type boolean)'
                      : 'Erreur Firestore : $error\n\nUID connecté : $uid',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: AdminService().signOut,
                child: const Text('Utiliser un autre compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminLoading extends StatelessWidget {
  const _AdminLoading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
