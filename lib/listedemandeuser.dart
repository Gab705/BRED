import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class UserRequestsPage extends StatefulWidget {
  const UserRequestsPage({Key? key}) : super(key: key);

  @override
  State<UserRequestsPage> createState() => _UserRequestsPageState();
}

class _UserRequestsPageState extends State<UserRequestsPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> requests = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await initializeDateFormatting('fr_FR');
      await _fetchUserRequests();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _fetchUserRequests() async {
    if (!mounted) return;

    setState(() {
      if (!isRefreshing) isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Session expirée, veuillez vous reconnecter.');
      }

      const String apiUrl = 'http://192.168.1.5:8000/api/user/index';
      final response = await http
          .get(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          requests = List<dynamic>.from(responseData['data'] ?? []);
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        throw Exception(
          responseData['message'] ?? 'Erreur serveur: ${response.statusCode}.',
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
      if (errorMessage.contains('Failed host lookup')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'La requête a pris trop de temps. Veuillez réessayer.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Demandes',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        toolbarHeight: 70,
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

    if (requests.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => isRefreshing = true);
        await _fetchUserRequests();
      },
      color: Colors.blue.shade700,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index]);
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue.shade700),
          const SizedBox(height: 20),
          Text(
            'Chargement de vos demandes...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
            Icon(Icons.cloud_off, size: 60, color: Colors.red.shade400),
            const SizedBox(height: 25),
            Text(
              'Oups! Une erreur est survenue.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _fetchUserRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Réessayer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 80,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 25),
            Text(
              'Aucune demande pour l\'instant.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Commencez par créer une nouvelle demande de service.',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: _fetchUserRequests,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Actualiser',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final dateTime = DateTime.parse(request['scheduled_at']);
    final formattedDate = DateFormat('dd MMM yyyy', 'fr_FR').format(dateTime);
    final formattedTime = DateFormat('HH:mm', 'fr_FR').format(dateTime);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request['status']).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    request['status'].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (request['is_paid'] == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.red.shade200!),
                    ),
                    child: Text(
                      'NON PAYÉ',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              request['description'] ?? 'Aucune description fournie.',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 18),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              text: 'Date: $formattedDate',
              iconColor: Colors.blue.shade700,
              textColor: Colors.blueGrey.shade800,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.access_time,
              text: 'Heure: $formattedTime',
              iconColor: Colors.blue.shade700,
              textColor: Colors.blueGrey.shade800,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.person_outline,
              text: 'Professionnel: ID #${request['professional_id']}',
              iconColor: Colors.green.shade700,
              textColor: Colors.blueGrey.shade800,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.info_outline,
              text:
                  'Créée le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(request['created_at']))}',
              iconColor: Colors.grey[600],
              textColor: Colors.grey[700],
            ),

            // Bouton pour noter le professionnel (visible seulement si le statut est "terminé")
            if (request['status'].toLowerCase() == 'effectue')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed:
                      () => _showRatingDialog(
                        context,
                        int.parse(request['professional_id'].toString()),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Noter ce professionnel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.grey[700]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.grey[700],
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'effectue':
        return Colors.green.shade600;
      case 'rejecte':
        return Colors.red.shade600;
      case 'accepte':
        return Colors.orange.shade600;
      case 'annule':
        return Colors.purple.shade600;
      case 'attente':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  Future<void> _showRatingDialog(
    BuildContext context,
    int professionalId,
  ) async {
    int rating = 0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Noter le professionnel'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Donnez une note de 1 à 5 étoiles :'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed:
                      rating == 0
                          ? null
                          : () async {
                            Navigator.pop(context);
                            await _submitRating(
                              professionalId,
                              rating,
                              commentController.text,
                            );
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(
    int professionalId,
    int rating,
    String comment,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Session expirée, veuillez vous reconnecter.');
      }

      const String baseUrl = 'http://192.168.1.5:8000';
      final url = Uri.parse('$baseUrl/api/store/rating/$professionalId');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({'note': rating, 'comment': comment}),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Notation enregistrée avec succès',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(
          responseData['message'] ??
              'Erreur lors de l\'enregistrement de la notation',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
