import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

void main() => runApp(const ProfessionalDashboardApp());

class ProfessionalDashboardApp extends StatelessWidget {
  const ProfessionalDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRED Pro Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ProfessionalDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final token = await _storage.read(key: 'professional-auth');
      if (token == null) throw Exception('Token non disponible');

      final response = await http.get(
        Uri.parse('http://192.168.1.5:8000/api/Dashboard/pro'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _dashboardData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'attente':
        return 'En attente';
      case 'effectue':
        return 'Effectuée';
      case 'rejecte':
        return 'Rejetée';
      case 'accepte':
        return 'Acceptée';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'attente':
        return Colors.orange;
      case 'effectue':
        return Colors.green;
      case 'rejecte':
        return Colors.red;
      case 'accepte':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tableau de Bord',
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Statistiques
                    const Text(
                      'Votre Activité',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 0.80,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          'Demandes en attente',
                          _dashboardData!['date']['Demande_en_attente']
                              .toString(),
                          Feather.clock,
                          Colors.orange[700]!,
                        ),
                        _buildStatCard(
                          'Terminées aujourd\'hui',
                          _dashboardData!['date']['Terminées_aujourdhui']
                              .toString(),
                          Feather.check_circle,
                          Colors.green[700]!,
                        ),
                        _buildStatCard(
                          'Note moyenne',
                          _dashboardData!['date']['Note_moyenne']
                              .toStringAsFixed(1),
                          Feather.star,
                          Colors.amber[700]!,
                        ),
                        _buildStatCard(
                          'Clients servis',
                          _dashboardData!['date']['Clients_servis'].toString(),
                          Feather.users,
                          Colors.blue[700]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dernières interventions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dernières Interventions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._dashboardData!['date']['Dernieres_interventions']
                        .map<Widget>(
                          (intervention) => _buildInterventionCard(
                            id: intervention['id'],
                            description: intervention['description'],
                            date: _formatDate(intervention['scheduled_at']),
                            status: _translateStatus(intervention['status']),
                            statusColor: _getStatusColor(
                              intervention['status'],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionCard({
    required int id,
    required String description,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Intervention #$id',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Feather.calendar, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Row(
                    children: [
                      Text(
                        'Détails',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Icon(Feather.chevron_right, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
