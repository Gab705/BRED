import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bredproject/login_screen.dart';
import 'package:bredproject/aide.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bredproject/data_usage_settings_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bredproject/registerpro.dart';
import 'package:bredproject/disponibilite.dart';

class SettingsProPage extends StatefulWidget {
  const SettingsProPage({super.key});

  @override
  State<SettingsProPage> createState() => _SettingsProPageState();
}

class _SettingsProPageState extends State<SettingsProPage> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? users;

  @override
  void initState() {
    super.initState();
    fetchAuthenticatedUser();
  }

  Future<void> fetchAuthenticatedUser() async {
    final token = await storage.read(key: 'professional-auth');

    if (token == null || token.isEmpty) {
      debugPrint("Aucun token trouvé - Utilisateur non connecté");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.5:8000/api/pro/me"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data['data'];
        });
      } else if (response.statusCode == 401) {
        debugPrint("Token invalide ou expiré");
        await storage.delete(key: 'auth_token');
      } else {
        debugPrint("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur lors de la requête: $e");
    }
  }

  void _showUserQrCode() {
    if (users == null) return;

    final userData = {
      'name': users!['name'],
      'phone': users!['phone'],
      'email': users!['email'],
      'user_id': users!['id'],
    };
    final userDataString = jsonEncode(userData);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mon QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: userDataString,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Scannez ce QR code pour partager mes informations',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        centerTitle: true,
        toolbarHeight: 70,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.shade100,
                child: ClipOval(
                  child:
                      users?['photo'] != null
                          ? Image.network(
                            'http://192.168.1.5:8000/storage/${users!['photo']}',
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/default.png',
                                fit: BoxFit.cover,
                                width: 52,
                                height: 52,
                              );
                            },
                          )
                          : Image.asset(
                            'assets/default.png',
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                          ),
                ),
              ),
              title: Text(
                users?['name'] ?? 'Utilisateur',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[400],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    users?['phone'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.qr_code, color: Colors.blue),
                onPressed: _showUserQrCode,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSettingsSection(
                  icon: Icons.verified_user,
                  title: 'Disponiblité',
                  subtitle: 'Mettre a jour sa disponibilité',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateAvailabilityPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsSection(
                  icon: Icons.storage,
                  title: 'Stockage et données',
                  subtitle: 'Utilisation du réseau, téléchargement auto',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataUsageSettingsPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsSection(
                  icon: Icons.person_add_alt_1,
                  title: 'Inviter un ami',
                  subtitle: 'Partager l\'application avec vos contacts',
                  onTap: () {
                    Share.share(
                      'Découvrez cette application géniale ! Téléchargez-la ici : [LIEN_DE_L_APPLICATION]',
                      subject: 'Découvrez cette application',
                    );
                  },
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red[50],
                      ),
                      child: Icon(Icons.logout, color: Colors.red[400]),
                    ),
                    title: Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal[50],
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
          ),
          actions: [
            TextButton(
              child: Text('ANNULER', style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'DÉCONNECTER',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                await storage.delete(key: 'auth_token');
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
