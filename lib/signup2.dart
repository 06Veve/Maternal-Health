import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bebezen/core/services/account_service.dart';
import 'package:bebezen/manage_navigation.dart';
import 'package:bebezen/services/input_validator.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameCtl = TextEditingController();
  final _gaCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _pwdCtl = TextEditingController();
  final _confirmPwdCtl = TextEditingController();
  final _inviteCtl = TextEditingController();
  AccountRole _role = AccountRole.mother;

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _pwdCtl.text.trim(),
      );

      final accountService = AccountService();
      if (_role == AccountRole.mother) {
        await accountService.createMotherProfile(
          user: cred.user!,
          name: _nameCtl.text,
          gestationalWeeks: int.parse(_gaCtl.text.trim()),
        );
      } else {
        try {
          await accountService.createPartnerProfile(
            user: cred.user!,
            name: _nameCtl.text,
            invitationCode: _inviteCtl.text,
          );
        } catch (_) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .delete();
          await cred.user!.delete();
          rethrow;
        }
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ManageNavigation()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Signup failed")));
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _gaCtl.dispose();
    _emailCtl.dispose();
    _pwdCtl.dispose();
    _confirmPwdCtl.dispose();
    _inviteCtl.dispose();
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
                  Hero(
                    tag: "logo",
                    child: Image.asset(
                      "assets/images/img.png",
                      width: 60,
                      height: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Create Account",
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  Text(
                    "Start your personalized journey today",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),

                  SegmentedButton<AccountRole>(
                    segments: const [
                      ButtonSegment(
                        value: AccountRole.mother,
                        icon: Icon(Icons.pregnant_woman),
                        label: Text('Mother'),
                      ),
                      ButtonSegment(
                        value: AccountRole.partner,
                        icon: Icon(Icons.family_restroom),
                        label: Text('Partner'),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (selection) {
                      setState(() => _role = selection.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  BZInput(
                    label: "Full Name",
                    hint: "Jane Doe",
                    controller: _nameCtl,
                    prefixIcon: Icons.person_outline,
                    validator: InputValidator.validateName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  BZInput(
                    label: "Email Address",
                    hint: "jane@example.com",
                    controller: _emailCtl,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: InputValidator.validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  if (_role == AccountRole.mother)
                    BZInput(
                      label: "Gestational Age (Weeks)",
                      hint: "e.g. 12",
                      controller: _gaCtl,
                      prefixIcon: Icons.pregnant_woman,
                      keyboardType: TextInputType.number,
                      validator: InputValidator.validateGestationalAge,
                      textInputAction: TextInputAction.next,
                    )
                  else
                    BZInput(
                      label: "Partner invitation code",
                      hint: "e.g. 8F4A12BC",
                      controller: _inviteCtl,
                      prefixIcon: Icons.link,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if ((value ?? '').trim().length < 8) {
                          return 'Enter the invitation code sent by the mother';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),

                  BZInput(
                    label: "Password",
                    hint: "••••••••",
                    controller: _pwdCtl,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: InputValidator.validatePassword,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  BZInput(
                    label: "Confirm Password",
                    hint: "••••••••",
                    controller: _confirmPwdCtl,
                    prefixIcon: Icons.lock_reset_outlined,
                    isPassword: true,
                    validator: (value) => InputValidator.validatePasswordMatch(
                      value,
                      _pwdCtl.text,
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),

                  BZButton(
                    label: "Sign Up",
                    onPressed: _signup,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Login",
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
