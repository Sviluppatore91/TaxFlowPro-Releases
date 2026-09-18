import re

with open('lib/screens/login_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
if 'package:shared_preferences/shared_preferences.dart' not in content:
    content = content.replace("import 'dart:io' show Platform;", "import 'dart:io' show Platform;\nimport 'package:shared_preferences/shared_preferences.dart';\nimport 'package:local_auth/local_auth.dart';")

# 2. Add state variables
state_vars = """
  bool _rememberMe = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
"""
if '_rememberMe = false;' not in content:
    content = content.replace("String _statusMessage = '';", "String _statusMessage = '';\n" + state_vars)

# 3. Add initState and helper methods
init_state_and_helpers = """
  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadSavedCredentials();
  }

  Future<void> _checkBiometrics() async {
    if (kIsWeb || Platform.isWindows) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck || isDeviceSupported;
      });
    } catch (e) {
      debugPrint("Errore biometria: $e");
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final remember = prefs.getBool('remember_me') ?? false;

    if (remember && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autenticati per accedere a TaxFlowPro',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('saved_email');
        final savedPassword = prefs.getString('saved_password');
        
        if (savedEmail != null && savedPassword != null) {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          await _loginWithEmail();
        } else {
          setState(() => _errorMessage = 'Nessuna credenziale salvata per l\\'impronta. Effettua prima il login spuntando "Ricorda".');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore biometria: $e');
    }
  }
"""
if 'void initState()' not in content:
    content = content.replace("Future<void> _requestPermissions() async {", init_state_and_helpers + "\n  Future<void> _requestPermissions() async {")

# 4. Save credentials on successful email login
save_creds = """
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('saved_email', username);
          await prefs.setString('saved_password', password);
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
          await prefs.setBool('remember_me', false);
        }
"""
if "final prefs = await SharedPreferences.getInstance();" not in content:
    content = content.replace("dbHelper.cleanOldLoginAttempts();", "dbHelper.cleanOldLoginAttempts();\n" + save_creds)

# 5. Add UI in _buildForm
ui_additions = """
        // Ricorda e Impronta
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _rememberMe = val ?? false);
                  },
                ),
                const Text('Ricorda', style: TextStyle(color: Colors.white70)),
              ],
            ),
            if (_canCheckBiometrics)
              IconButton(
                icon: const Icon(Icons.fingerprint, color: Colors.white, size: 32),
                onPressed: _loginWithBiometrics,
                tooltip: 'Accedi con impronta',
              ),
          ],
        ),
        const SizedBox(height: 16),
"""
if "Ricorda e Impronta" not in content:
    content = content.replace("if (_errorMessage.isNotEmpty)", ui_additions + "\n        if (_errorMessage.isNotEmpty)")

with open('lib/screens/login_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Modifiche applicate con successo!")
