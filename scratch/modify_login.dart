import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tax_flow_pro/screens/main_screen.dart';
import 'package:tax_flow_pro/widgets/glass_container.dart';
import 'package:tax_flow_pro/widgets/custom_text_field.dart';
import 'package:tax_flow_pro/database/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:tax_flow_pro/services/drive_sync_service.dart';
import 'package:tax_flow_pro/services/windows_auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _statusMessage = '';

  Future<void> _requestPermissions() async {
    if (kIsWeb || Platform.isWindows) return;
    setState(() => _statusMessage = 'Richiesta permessi in corso...');
    await [
      Permission.contacts,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  Future<void> _handlePostLoginSuccess(drive.DriveApi? driveApi, User user) async {
    await _requestPermissions();

    setState(() => _statusMessage = 'Sincronizzazione database...');
    final dbHelper = DatabaseHelper();
    
    if (driveApi != null) {
      final dbPath = await DatabaseHelper.getDatabasePath();
      final backupId = await DriveSyncService.checkBackupExists(driveApi);
      if (backupId != null) {
        setState(() => _statusMessage = 'Ripristino database dal cloud...');
        await DriveSyncService.downloadBackup(driveApi, backupId, dbPath);
        await dbHelper.reloadDatabase();
      } else {
        setState(() => _statusMessage = 'Creazione nuovo database...');
        await dbHelper.database; // Forza creazione
        await DriveSyncService.uploadBackup(driveApi, dbPath);
      }
    }

    final users = await dbHelper.getUsers();
    var existingUser = users.firstWhere(
      (u) => u['email'] == user.email,
      orElse: () => <String, dynamic>{},
    );

    String role = 'User';
    String username = user.displayName ?? (user.email?.split('@').first ?? 'Utente');

    if (existingUser.isEmpty) {
      await dbHelper.insertUser({
        'username': username,
        'email': user.email ?? '',
        'role': 'User',
        'password_hash': 'firebase_auth',
        'phone': '',
      });
    } else {
      role = existingUser['role'] ?? 'User';
      username = existingUser['username'] ?? username;
    }

    dbHelper.currentUser = username;
    await dbHelper.logAccess(username, role, kIsWeb ? 'Web' : (Platform.isWindows ? 'Computer' : 'Cellulare'), eventType: 'login_success');

    if (driveApi != null) {
      final dbPath = await DatabaseHelper.getDatabasePath();
      await DriveSyncService.uploadBackup(driveApi, dbPath);
    }

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(role: role, username: username)));
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Autenticazione con Google...';
    });

    try {
      drive.DriveApi? driveApi;

      if (!kIsWeb && Platform.isWindows) {
        final client = await WindowsAuthService.loginWithGoogle();
        if (client == null) {
          setState(() => _isLoading = false);
          return;
        }
        driveApi = drive.DriveApi(client);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: [drive.DriveApi.driveAppdataScope],
        );
        
        try { await googleSignIn.signOut(); } catch (_) {}
        try { await googleSignIn.disconnect(); } catch (_) {}
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return; 
        }

        driveApi = await DriveSyncService.getDriveApi(googleUser);

        setState(() => _statusMessage = 'Accesso a Firebase in corso...');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _handlePostLoginSuccess(driveApi, user);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore Google: $e');
      debugPrint('Errore Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmail() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Inserisci nome utente e password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Accesso in corso...';
    });

    try {
      final dbHelper = DatabaseHelper();
      
      // Usa verifyCredentials per confronto sicuro
      final verifiedUser = await dbHelper.verifyCredentials(username, password);

      if (verifiedUser != null) {
        final role = verifiedUser['role'] ?? 'User';
        
        dbHelper.cleanOldLoginAttempts();

        if (mounted) {
          try {
            String deviceType = 'Sconosciuto';
            if (kIsWeb) {
              deviceType = 'Computer / Web';
            } else {
              deviceType = (Platform.isAndroid || Platform.isIOS) ? 'Cellulare' : 'Computer';
            }
            await dbHelper.logAccess(username, role, deviceType, eventType: 'login_success');
          } catch (e) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Benvenuto $username!")),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(role: role, username: username)));
        }
      } else {
        setState(() => _errorMessage = 'Nome utente o password errati.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore imprevisto: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 320,
            child: GlassContainer(
              padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 15,
                      )
                    ]
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showInfoPopup(String title, String description, IconData icon) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 48),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Chiudi', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopLogo({CrossAxisAlignment alignment = CrossAxisAlignment.center}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/bimbomixer_logo_neon.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bentornato!',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Accedi al tuo account per continuare',
          style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _emailController,
          hintText: 'Nome Utente',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          hintText: 'Password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

        if (_isLoading && _statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),

        // Gradient Button
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _loginWithEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  'Accedi',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFooterIcons({bool isDesktop = false}) {
    return Row(
      mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFooterIcon(
          icon: Icons.security_outlined, 
          title: 'Sicuro', 
          subtitle: 'I tuoi dati sono\nsempre protetti',
          popupDesc: 'Utilizziamo crittografia end-to-end tramite i server Firebase Auth certificati per garantire che le tue password e i tuoi dati sensibili rimangano impenetrabili.',
          isDesktop: isDesktop
        ),
        if (isDesktop) const SizedBox(width: 32),
        _buildFooterIcon(
          icon: Icons.cloud_done_outlined, 
          title: 'Sincronizzato', 
          subtitle: 'Accedi ovunque,\nsu ogni dispositivo',
          popupDesc: 'Il nostro motore di sincronizzazione Cloud si appoggia a Google Drive e Firebase Firestore per mantenere il tuo database coerente tra PC, Android e Web.',
          isDesktop: isDesktop
        ),
        if (isDesktop) const SizedBox(width: 32),
        _buildFooterIcon(
          icon: Icons.insights_outlined, 
          title: 'Smart', 
          subtitle: 'Tutti gli strumenti\nper la tua attivitÃ ',
          popupDesc: 'Fatturazione, monitoraggio, statistiche predittive: TaxFlowPro Ã¨ progettato con moduli intelligenti per aiutarti a ottimizzare il flusso fiscale.',
          isDesktop: isDesktop
        ),
      ],
    );
  }

  Widget _buildFooterIcon({required IconData icon, required String title, required String subtitle, required String popupDesc, required bool isDesktop}) {
    return Expanded(
      flex: isDesktop ? 0 : 1,
      child: GestureDetector(
        onTap: () => _showInfoPopup(title, popupDesc, icon),
        child: Column(
          crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              subtitle, 
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, height: 1.4)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF121212)),
        Positioned(
          top: -200,
          right: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -300,
          left: -200,
          child: Container(
            width: 800,
            height: 800,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Linea diagonale luminosa
        Positioned(
          top: 0,
          left: -100,
          child: Transform.rotate(
            angle: -0.5,
            child: Container(
              width: 1000,
              height: 2,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 5),
                ],
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 850) {
                  return _buildDesktopLayout();
                }
                return _buildMobileLayout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Row(
          children: [
            // Left side (Brand and Info)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(right: 64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopLogo(alignment: CrossAxisAlignment.start),
                    const SizedBox(height: 48),
                    const Text(
                      'Gestisci la tua attivitÃ \nin modo semplice e intelligente.',
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TaxFlow Pro Ã¨ l\'app completa per la gestione della tua\nattivitÃ : fatture, clienti, spese, scadenze e molto altro.\nSempre con te, sempre aggiornato.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 48),
                    _buildFooterIcons(isDesktop: true),
                  ],
                ),
              ),
            ),
            // Right side (Form Box)
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                        blurRadius: 60,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(48),
                    borderRadius: 24,
                    borderColor: Colors.white.withValues(alpha: 0.2),
                    child: _buildFormAnimatedSwitcher(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildTopLogo(alignment: CrossAxisAlignment.center),
              const SizedBox(height: 24),
              const Text(
                'Bentornato!',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Accedi al tuo account per\ngestire la tua attivitÃ  in modo semplice.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              _buildForm(),
              const SizedBox(height: 48),
              _buildFooterIcons(isDesktop: false),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormAnimatedSwitcher() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: const ValueKey('login_form'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (MediaQuery.of(context).size.width > 850) ...[
               _buildTitleAndSubtitle(),
               const SizedBox(height: 32),
            ],
            _buildForm(), // For mobile, Title is outside the form, for Desktop it's inside
          ],
        ),
      ),
    );
  }
}
