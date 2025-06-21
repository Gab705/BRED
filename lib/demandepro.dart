import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ProfessionalRequestsPage extends StatefulWidget {
  const ProfessionalRequestsPage({Key? key}) : super(key: key);

  @override
  State<ProfessionalRequestsPage> createState() =>
      _ProfessionalRequestsPageState();
}

class _ProfessionalRequestsPageState extends State<ProfessionalRequestsPage> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> requests = [];
  Map<int, dynamic> userDetails = {};
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
      await _fetchProfessionalRequests();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'professional-auth');
  }

  Future<void> _fetchProfessionalRequests() async {
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

      const String apiUrl = 'http://192.168.1.5:8000/api/Liste/Demande/Pro';
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
        // Fetch user details for each request
        await _fetchUserDetails(responseData['data'], token);

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

  Future<void> _fetchUserDetails(List<dynamic> requests, String token) async {
    try {
      for (var request in requests) {
        final userId = request['user_id'];
        if (!userDetails.containsKey(userId)) {
          final userResponse = await http.get(
            Uri.parse('http://192.168.1.5:8000/api/user-info/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);
            setState(() {
              userDetails[userId] = userData['data'];
            });
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des détails utilisateur: $e');
    }
  }

  Future<void> _changeRequestStatus(int requestId, String newStatus) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Session expirée, veuillez vous reconnecter.');
      }

      final response = await http
          .post(
            Uri.parse(
              'http://192.168.1.5:8000/api/intervention/status/$requestId',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({'status': newStatus}),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Refresh the list after status change
        await _fetchProfessionalRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(
          responseData['message'] ?? 'Erreur lors du changement de statut',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Demandes Clients',
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
        await _fetchProfessionalRequests();
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
            'Chargement des demandes clients...',
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
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
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
              onPressed: _fetchProfessionalRequests,
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
              Icons.assignment_outlined,
              size: 80,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 25),
            Text(
              'Aucune demande client pour l\'instant.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Les demandes de vos clients apparaîtront ici.',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: _fetchProfessionalRequests,
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

    final userInfo = userDetails[request['user_id']] ?? {};
    final userName = userInfo['name'] ?? 'Client inconnu';
    final userEmail = userInfo['email'] ?? 'Email non disponible';
    final userPhone = userInfo['phone'] ?? 'Téléphone non disponible';

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
                // Status Tag with dropdown for changing status
                PopupMenuButton<String>(
                  onSelected: (newStatus) {
                    _changeRequestStatus(request['id'], newStatus);
                  },
                  itemBuilder: (BuildContext context) {
                    return ['attente', 'accepte', 'rejecte', 'effectue'].map((
                      String status,
                    ) {
                      return PopupMenuItem<String>(
                        value: status,
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        request['status'],
                      ).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          request['status'].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
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

            // Client information section
            Text(
              'Informations Client',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.person_outline,
              text: 'Nom: $userName',
              iconColor: Colors.blue.shade700,
              textColor: Colors.blueGrey.shade800,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.email_outlined,
              text: 'Email: $userEmail',
              iconColor: Colors.blue.shade700,
              textColor: Colors.blueGrey.shade800,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              text: 'Téléphone: $userPhone',
              iconColor: Colors.blue.shade700,
              textColor: Colors.blueGrey.shade800,
            ),
            const SizedBox(height: 15),

            // Request information section
            Text(
              'Détails de la Demande',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 10),
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
              icon: Icons.info_outline,
              text:
                  'Créée le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(request['created_at']))}',
              iconColor: Colors.grey[600],
              textColor: Colors.grey[700],
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
      case 'accepte':
        return Colors.green.shade600;
      case 'rejecte':
        return Colors.red.shade600;
      case 'attente':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}
