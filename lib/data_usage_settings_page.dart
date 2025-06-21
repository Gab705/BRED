import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pour la persistance des préférences
import 'package:cached_network_image/cached_network_image.dart'; // Pour vider le cache des images réseau

class DataUsageSettingsPage extends StatefulWidget {
  const DataUsageSettingsPage({super.key});

  @override
  State<DataUsageSettingsPage> createState() => _DataUsageSettingsPageState();
}

class _DataUsageSettingsPageState extends State<DataUsageSettingsPage> {
  bool _autoDownloadImages = true;
  bool _autoDownloadVideos = false;
  bool _saveToGallery = true;
  String _cacheSize = 'Calcul en cours...'; // Pour afficher la taille du cache

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _calculateCacheSize();
  }

  // Charge les préférences depuis SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoDownloadImages = prefs.getBool('autoDownloadImages') ?? true;
      _autoDownloadVideos = prefs.getBool('autoDownloadVideos') ?? false;
      _saveToGallery = prefs.getBool('saveToGallery') ?? true;
    });
  }

  // Sauvegarde les préférences dans SharedPreferences
  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Simule le calcul de la taille du cache (implémentation réelle plus complexe)
  Future<void> _calculateCacheSize() async {
    // Dans une vraie application, vous calculeriez ici la taille réelle du cache.
    // Cela peut impliquer de parcourir les répertoires de cache de l'application.
    await Future.delayed(const Duration(milliseconds: 500)); // Simule un délai
    setState(() {
      // Taille fictive, à remplacer par une logique réelle
      _cacheSize = 'Environ 45 Mo';
    });
  }

  // Pour vider le cache
  Future<void> _clearCache() async {
    try {
      await CachedNetworkImage.evictFromCache(
        '',
      ); // Vide le cache de toutes les images
      // Si vous avez d'autres types de cache (fichiers, etc.), ajoutez leur logique ici.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cache vidé avec succès !'),
          backgroundColor:
              Theme.of(
                context,
              ).colorScheme.secondary, // Utilise la couleur secondaire
        ),
      );
      await _calculateCacheSize(); // Recalcule la taille après vidage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du vidage du cache : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stockage et Données',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(), // Rend le scroll plus agréable
        children: [
          _buildSectionHeader('Utilisation du Réseau'),
          _buildInfoCard(
            context,
            icon: Icons.signal_cellular_alt_rounded,
            title: 'Données Mobiles Utilisées',
            value: '250 Mo (estimé)', // Idéalement, dynamique
            color: Colors.deepOrangeAccent.shade100,
          ),
          _buildInfoCard(
            context,
            icon: Icons.wifi_rounded,
            title: 'Données Wi-Fi Utilisées',
            value: '1.2 Go (estimé)', // Idéalement, dynamique
            color: Colors.blueAccent.shade100,
          ),
          const SizedBox(height: 16), // Espacement entre les sections
          _buildSectionHeader('Téléchargement Automatique des Médias'),
          _buildSwitchSetting(
            context,
            title: 'Télécharger les images',
            subtitle:
                'Télécharge les images reçues via le réseau mobile et Wi-Fi',
            value: _autoDownloadImages,
            onChanged: (value) {
              setState(() => _autoDownloadImages = value);
              _savePreference('autoDownloadImages', value);
            },
          ),
          _buildSwitchSetting(
            context,
            title: 'Télécharger les vidéos',
            subtitle: 'Télécharge les vidéos reçues via le Wi-Fi uniquement',
            value: _autoDownloadVideos,
            onChanged: (value) {
              setState(() => _autoDownloadVideos = value);
              _savePreference('autoDownloadVideos', value);
            },
          ),
          const SizedBox(height: 16), // Espacement
          _buildSectionHeader('Paramètres de Stockage'),
          _buildListTileSetting(
            context,
            title: 'Taille du Cache',
            subtitle: 'Espace occupé par les fichiers temporaires',
            trailing: Text(_cacheSize),
            icon: Icons.folder_open_rounded,
          ),
          _buildListTileSetting(
            context,
            title: 'Vider le Cache',
            subtitle:
                'Libère de l\'espace en supprimant les fichiers temporaires',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            icon: Icons.delete_sweep_rounded,
            onTap: () => _showClearCacheDialog(context),
          ),
          _buildSwitchSetting(
            context,
            title: 'Enregistrer dans la galerie',
            subtitle:
                'Enregistre les médias reçus dans la galerie de votre appareil',
            value: _saveToGallery,
            onChanged: (value) {
              setState(() => _saveToGallery = value);
              _savePreference('saveToGallery', value);
            },
          ),
          const SizedBox(height: 24), // Espacement final
        ],
      ),
    );
  }

  // Nouveau widget pour les titres de section, plus stylisé
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary, // Couleur accentuée
          fontWeight: FontWeight.bold,
          fontSize: 15.0,
          letterSpacing: 0.8, // Espacement des lettres
        ),
      ),
    );
  }

  // Nouveau widget pour les cartes d'information d'utilisation des données
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color, // Ajout d'une couleur pour le fond
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2, // Légère ombre pour donner du relief
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.1), // Couleur de fond douce
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28), // Icône colorée
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nouveau widget pour les SwitchListTile, pour un style uniforme
  Widget _buildSwitchSetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0.5, // Très légère ombre
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        dense: true, // Rend le ListTile plus compact
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
      ),
    );
  }

  // Nouveau widget pour les ListTile, pour un style uniforme
  Widget _buildListTileSetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0.5, // Très légère ombre
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading:
            icon != null
                ? Icon(icon, color: Theme.of(context).colorScheme.primary)
                : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: trailing,
        onTap: onTap,
        dense: true, // Rend le ListTile plus compact
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Vider le cache ?'),
          content: const Text(
            'Ceci supprimera les fichiers temporaires téléchargés par l\'application. Cela peut libérer de l\'espace de stockage.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Ferme le dialogue
                _clearCache(); // Appelle la fonction de vidage du cache
              },
              child: const Text('Vider'),
            ),
          ],
        );
      },
    );
  }
}
