// ... imports inchangés
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProfessionalRatingsViewPage extends StatefulWidget {
  final int professionalId;

  const ProfessionalRatingsViewPage({Key? key, required this.professionalId})
    : super(key: key);

  @override
  State<ProfessionalRatingsViewPage> createState() =>
      _ProfessionalRatingsViewPageState();
}

class _ProfessionalRatingsViewPageState
    extends State<ProfessionalRatingsViewPage> {
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
    _fetchProfessionalRatings();
  }

  Future<void> _fetchProfessionalRatings() async {
    if (!mounted) return;

    setState(() {
      if (!isRefreshing) isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      final url = Uri.parse(
        'http://192.168.1.5:8000/api/professionel/rating/${widget.professionalId}',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == 1) {
          final ratingsData = responseData['data']['ratings'] ?? [];

          final double total = ratingsData.fold<double>(0.0, (
            double sum,
            dynamic rating,
          ) {
            final dynamic note = rating['note'];
            if (note == null) return sum;
            if (note is int) return sum + note.toDouble();
            if (note is double) return sum + note;
            if (note is String) return sum + (double.tryParse(note) ?? 0.0);
            return sum;
          });

          final double avg =
              ratingsData.isNotEmpty
                  ? total / ratingsData.length.toDouble()
                  : 0.0;

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
      } else {
        throw Exception(
          responseData['message'] ?? 'Erreur serveur: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      isRefreshing = false;
      errorMessage = e.toString().replaceAll('Exception: ', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Evaluations',
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
    if (isLoading) return _buildLoadingView();
    if (errorMessage.isNotEmpty) return _buildErrorView();
    if (ratings.isEmpty) return _buildEmptyView();

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
          return const Icon(Icons.star, color: Colors.amber, size: 30);
        } else if (rating > index) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 30);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 30);
        }
      }),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final date = DateFormat(
      'dd/MM/yyyy à HH:mm',
    ).format(DateTime.parse(rating['created_at']).toLocal());

    final double note = (rating['note'] as num).toDouble();

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
                  'Note: $note/5',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(note),
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRatingBar(note),
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

  Widget _buildRatingBar(double rating) {
    final percentage = rating / 5;
    return LinearProgressIndicator(
      value: percentage,
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(_getRatingColor(rating)),
    );
  }

  Color _getRatingColor(double rating) {
    return rating >= 3 ? Colors.green : Colors.red;
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue.shade700),
          const SizedBox(height: 20),
          const Text(
            'Chargement des évaluations...',
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
              'Aucune évaluation pour ce professionnel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Ce professionnel n\'a pas encore reçu d\'évaluations.',
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
