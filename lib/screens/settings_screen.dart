import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';
import '../services/cloud_migration_service.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and Title
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'TAX APP / SETTINGS',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Sidebar
                    Expanded(
                      flex: 4,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SETTINGS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 24),
                            _buildMenuItem(Icons.palette, 'Appearance & Skins', 0),
                            Divider(color: Colors.white.withValues(alpha: 0.1)),
                            _buildMenuItem(Icons.security, 'Security Center', 1),
                            Divider(color: Colors.white.withValues(alpha: 0.1)),
                            _buildMenuItem(Icons.description, 'Tax Information', 2),
                            Divider(color: Colors.white.withValues(alpha: 0.1)),
                            _buildMenuItem(Icons.credit_card, 'Payment Methods', 3),
                            Divider(color: Colors.white.withValues(alpha: 0.1)),
                            _buildMenuItem(Icons.cloud_sync, 'Data Management', 4),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                    // Right Panel
                    Expanded(
                      flex: 6,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: _buildRightPanelContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanelContent() {
    switch (_selectedMenuIndex) {
      case 0:
        return _buildAppearancePanel();
      case 1:
        return _buildSecurityPanel();
      case 2:
        return _buildTaxInformationPanel();
      case 4:
        return _buildDataManagementPanel();
      default:
        return Center(
          child: Text('Section under construction', style: TextStyle(color: Colors.white70)),
        );
    }
  }

  Widget _buildAppearancePanel() {
    final themeProvider = Provider.of<AppThemeProvider>(context);
    final currentPrimary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: currentPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: currentPrimary.withValues(alpha: 0.5)),
              ),
              child: Icon(Icons.palette, color: currentPrimary, size: 32),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('APPEARANCE & SKINS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('PERSONALIZE YOUR EXPERIENCE', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, letterSpacing: 1.1)),
              ],
            ),
          ],
        ),
        SizedBox(height: 32),
        Text('Select App Skin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildSkinOption(themeProvider, AppSkin.bimbomixer, 'Bimbomixer', const Color(0xFFFFD700)),
              _buildSkinOption(themeProvider, AppSkin.synthwave, 'Synthwave', const Color(0xFFFF00FF)),
              _buildSkinOption(themeProvider, AppSkin.cyberpunk, 'Cyberpunk', const Color(0xFF00FF00)),
              _buildSkinOption(themeProvider, AppSkin.oceanGlass, 'Ocean Glass', const Color(0xFF00BFFF)),
              _buildSkinOption(themeProvider, AppSkin.sunset, 'Sunset', const Color(0xFFFF4500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkinOption(AppThemeProvider themeProvider, AppSkin skin, String title, Color colorPreview) {
    bool isSelected = themeProvider.currentSkin == skin;
    return InkWell(
      onTap: () {
        themeProvider.setSkin(skin);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colorPreview.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorPreview : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorPreview,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected) BoxShadow(color: colorPreview.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: colorPreview),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.5)),
              ),
              child: Icon(Icons.security, color: Colors.pinkAccent, size: 32),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SECURITY CENTER', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('SECURE YOUR ACCOUNT', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, letterSpacing: 1.1)),
              ],
            ),
          ],
        ),
        SizedBox(height: 32),
        Expanded(
          child: ListView(
            children: [
              _buildSecurityItem(Icons.lock, '2-Factor Authentication (2FA)', 'Enabled', true),
              _buildSecurityItem(Icons.fingerprint, 'Biometric Login (FaceID/TouchID)', 'Enabled', true),
              _buildLoginActivity(),
              _buildSecurityItem(Icons.key, 'Change Password', 'Locked', false, color: Colors.redAccent),
              _buildSecurityItem(Icons.verified_user, 'Data Encryption', 'Active', true, color: Colors.lightBlueAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxInformationPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
              ),
              child: Icon(Icons.description, color: Colors.orangeAccent, size: 32),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TAX INFORMATION', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('CONFIGURA I DATI DELLA TUA AZIENDA', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, letterSpacing: 1.1)),
              ],
            ),
          ],
        ),
        SizedBox(height: 32),
        Expanded(
          child: FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              
              final prefs = snapshot.data!;
              return ListView(
                children: [
                  _buildEditableTaxItem(prefs, 'Ragione Sociale (Denominazione)', 'company_name', Icons.business, 'La Tua Azienda S.r.l.'),
                  _buildEditableTaxItem(prefs, 'Partita IVA (11 caratteri)', 'company_vat', Icons.numbers, '01234567890'),
                  _buildEditableTaxItem(prefs, 'Indirizzo Sede', 'company_address', Icons.location_on, 'Via Roma 1'),
                  Row(
                    children: [
                      Expanded(child: _buildEditableTaxItem(prefs, 'CAP', 'company_zip', Icons.local_post_office, '00100')),
                      SizedBox(width: 16),
                      Expanded(child: _buildEditableTaxItem(prefs, 'Comune', 'company_city', Icons.location_city, 'Roma')),
                      SizedBox(width: 16),
                      Expanded(child: _buildEditableTaxItem(prefs, 'Provincia (Sigla)', 'company_province', Icons.map, 'RM')),
                    ],
                  ),
                  _buildEditableTaxItem(prefs, 'Regime Fiscale (es. RF01 per ordinario, RF19 per forfettario)', 'company_regime', Icons.account_balance, 'RF01'),
                ],
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTaxItem(SharedPreferences prefs, String label, String key, IconData icon, String defaultVal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 8),
          TextFormField(
            initialValue: prefs.getString(key) ?? '',
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.orangeAccent),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: defaultVal,
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onChanged: (val) {
              if (val.isNotEmpty) {
                prefs.setString(key, val);
              } else {
                prefs.remove(key);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
              ),
              child: Icon(Icons.cloud_sync, color: Colors.blueAccent, size: 32),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DATA MANAGEMENT', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('SYNC OR RECOVER CLOUD DATA', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, letterSpacing: 1.1)),
              ],
            ),
          ],
        ),
        SizedBox(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.cloud_download, color: Colors.greenAccent),
          title: Text('Ripristina Dati da Firebase', style: TextStyle(color: Colors.white)),
          subtitle: Text('Scarica i dati vecchi salvati nel cloud.', style: TextStyle(color: Colors.white70)),
          trailing: ElevatedButton(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Color(0xFF1E1E1E),
                  title: Text('Sincronizzazione in corso', style: TextStyle(color: Colors.white)),
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(child: Text('Attendere prego...', style: TextStyle(color: Colors.white70))),
                    ],
                  ),
                ),
              );
              try {
                final importService = CloudMigrationService();
                await importService.syncFromCloud();
                if (mounted) {
                  Navigator.pop(context); // chiudi loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dati sincronizzati con successo! Riavvia l\'app.')));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // chiudi loading
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante la sincronizzazione: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: Text('Avvia Sync', style: TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    bool isSelected = _selectedMenuIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMenuIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.7), size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            if (isSelected) Icon(Icons.keyboard_arrow_right, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String status, bool switchValue, {Color color = Colors.pinkAccent}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          Text(status, style: TextStyle(color: color, fontSize: 14)),
          SizedBox(width: 12),
          Switch(
            value: switchValue,
            onChanged: (v) {},
            activeThumbColor: Colors.white,
            activeTrackColor: color.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginActivity() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.white.withValues(alpha: 0.7), size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Login Activity', style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 4),
                Text('Last Login: Just Now', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                Text('Location: London, UK', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text('View History', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
