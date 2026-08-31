import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tax_flow_pro/screens/main_screen.dart';
import 'package:tax_flow_pro/widgets/gradient_scaffold.dart';
import 'package:tax_flow_pro/widgets/glass_container.dart';
import 'package:tax_flow_pro/database/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // L'utente ha annullato
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Verifica utente su Firestore
        final dbHelper = DatabaseHelper();
        final users = await dbHelper.getUsers();
        
        var existingUser = users.firstWhere(
          (u) => u['email'] == user.email,
          orElse: () => <String, dynamic>{},
        );

        String role = 'User';
        String username = user.displayName ?? 'Utente';

        if (existingUser.isEmpty) {
          // Crea nuovo utente se non esiste
          await dbHelper.insertUser({
            'username': username,
            'email': user.email,
            'role': 'User',
            'password_hash': 'google_sso', // Placeholder
            'phone': '',
          });
        } else {
          role = existingUser['role'] ?? 'User';
          username = existingUser['username'] ?? username;
        }

        dbHelper.currentUser = username;
        await dbHelper.logAccess(username, role, 'Computer/Cellulare', eventType: 'login_success');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Benvenuto $username!")));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(role: role, username: username)));
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante l\'accesso con Google. Assicurati di essere connesso a internet e riprova.';
      });
      debugPrint('Errore Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Accesso TaxFlowPro', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassContainer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.account_balance, size: 80, color: Colors.white),
                  const SizedBox(height: 32),
                  const Text(
                    'Benvenuto in TaxFlowPro',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.login),
                    label: Text(_isLoading ? 'Accesso in corso...' : 'Accedi con Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
