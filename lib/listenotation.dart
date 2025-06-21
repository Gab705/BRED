import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfessionalRatingsPage extends StatefulWidget {
  const ProfessionalRatingsPage({Key? key}) : super(key: key);

  @override
  State<ProfessionalRatingsPage> createState() =>
      _ProfessionalRatingsPageState();
}

class _ProfessionalRatingsPageState extends State<ProfessionalRatingsPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> ratings = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isRefreshing = false;
  double averageRating = 0.0;
  int ratingsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _verifyAndInitializeStorage();
      _fetchProfessionalRatings();
    });
  }

  Future<void> _verifyAndInitializeStorage() async {
    debugPrint('Vérification du stockage sécurisé:');
    final token = await _getAuthToken();
    if (token == null) {
      debugPrint('Aucun token trouvé - Déconnexion nécessaire');
      _handleLogout();
      return;
    }

    debugPrint('Token: $token');

    var professionalId = await _getProfessionalId();
    if (professionalId == null) {
      // Tentative de récupération depuis le token
      final parts = token.split('|');
      if (parts.length > 1) {
        final id = parts[0];
        debugPrint('Récupération du professional_id depuis le token: $id');
        await _storage.write(key: 'professional_id', value: id);
        professionalId = int.tryParse(id);
      }
    }

    debugPrint('Professional ID: $professionalId');

    if (professionalId == null) {
      debugPrint('Aucun professional_id disponible - Déconnexion nécessaire');
      _handleLogout();
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final token = await _storage.read(key: 'professional-auth');
      if (token == null) {
        debugPrint('Aucun token trouvé dans le stockage');
      }
      return token;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  Future<int?> _getProfessionalId() async {
    try {
      final idString = await _storage.read(key: 'professional_id');
      if (idString == null || idString.isEmpty) {
        debugPrint('Aucun professional_id trouvé dans le stockage');
        return null;
      }
      return int.tryParse(idString);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du professional_id: $e');
      return null;
    }
  }

  Future<void> _fetchProfessionalRatings() async {
    if (!mounted) return;

    setState(() {
      if (!isRefreshing) isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _getAuthToken();
      final professionalId = await _getProfessionalId();

      debugPrint(
        'Token utilisé pour la requête: ${token != null ? 'présent' : 'absent'}',
      );
      debugPrint('Professional ID utilisé: $professionalId');

      if (token == null || professionalId == null) {
        throw Exception(
          'Session expirée ou informations manquantes. Veuillez vous reconnecter.',
        );
      }

      const String baseUrl =
          'http://192.168.1.5:8000'; // Remplacez par votre URL
      final url = Uri.parse(
        '$baseUrl/api/professionals/ratings/$professionalId',
      );

      debugPrint('Envoi de la requête à: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Réponse reçue - Status: ${response.statusCode}');
      debugPrint('Corps de la réponse: ${response.body}');

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == 1) {
          final List<dynamic> ratingsData = responseData['data'] ?? [];
          final double total = ratingsData.fold(
            0,
            (sum, rating) => sum + (rating['note'] as num),
          );
          final double avg =
              ratingsData.isNotEmpty ? total / ratingsData.length : 0.0;

          if (!mounted) return;

          setState(() {
            ratings = ratingsData;
            averageRating = avg;
            ratingsCount = ratingsData.length;
            isLoading = false;
            isRefreshing = false;
          });
        } else {
          throw Exception(
            responseData['message'] ?? 'Statut de réponse inattendu',
          );
        }
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'professional-auth');
        await _storage.delete(key: 'professional_id');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
          responseData['message'] ?? 'Erreur serveur (${response.statusCode})',
        );
      }
    } on http.ClientException catch (e) {
      _handleNetworkError(e);
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleNetworkError(http.ClientException e) {
    debugPrint('Erreur réseau: $e');
    _handleError(
      'Connexion au serveur impossible. Vérifiez votre connexion internet.',
    );
  }

  void _handleError(dynamic e) {
    if (!mounted) return;

    final errorMsg = e.toString().replaceAll('Exception: ', '');
    debugPrint('Erreur traitée: $errorMsg');

    if (errorMsg.contains('Session expirée') ||
        errorMsg.contains('informations manquantes')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogout();
      });
    } else {
      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = errorMsg;
      });
    }
  }

  void _handleLogout() async {
    await _storage.deleteAll();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes evaluations',
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingView();
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (ratings.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => isRefreshing = true);
        await _fetchProfessionalRatings();
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildRatingSummary(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildRatingCard(ratings[index]),
                childCount: ratings.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Note Moyenne',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '/5',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildRatingStars(averageRating),
            Text(
              '$ratingsCount évaluation${ratingsCount > 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          // Étoile pleine
          return const Icon(Icons.star, color: Colors.amber, size: 30);
        } else if (rating > index && rating < index + 1) {
          // Demi-étoile (uniquement pour les valeurs fractionnaires)
          return const Icon(Icons.star_half, color: Colors.amber, size: 30);
        } else {
          // Étoile vide
          return const Icon(Icons.star_border, color: Colors.amber, size: 30);
        }
      }),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final date = DateFormat(
      'dd/MM/yyyy à HH:mm',
    ).format(DateTime.parse(rating['created_at']).toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Note: ${rating['note']}/5',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(rating['note']),
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRatingBar(rating['note']),
            if (rating['comment'] != null &&
                rating['comment'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Commentaire:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(rating['comment'], style: const TextStyle(fontSize: 15)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int rating) {
    final percentage = rating / 5;
    return LinearProgressIndicator(
      value: percentage,
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(_getRatingColor(rating)),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 3) return Colors.green;
    return Colors.red;
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue.shade700),
          const SizedBox(height: 20),
          const Text(
            'Chargement de vos évaluations...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            const SizedBox(height: 20),
            Text(
              'Impossible de charger les évaluations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                errorMessage,
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchProfessionalRatings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Réessayer'),
            ),
            if (errorMessage.contains('Session expirée')) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _handleLogout,
                child: const Text('Se reconnecter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 80, color: Colors.blue[200]),
            const SizedBox(height: 20),
            const Text(
              'Aucune évaluation pour le moment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Vous verrez apparaître ici les notes et commentaires de vos clients après chaque service terminé.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _fetchProfessionalRatings,
              child: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }
}
