import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateAvailabilityPage extends StatefulWidget {
  const UpdateAvailabilityPage({Key? key}) : super(key: key);

  @override
  State<UpdateAvailabilityPage> createState() => _UpdateAvailabilityPageState();
}

class _UpdateAvailabilityPageState extends State<UpdateAvailabilityPage> {
  final _storage = const FlutterSecureStorage();
  bool? _currentAvailability;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfessionalData();
  }

  Future<void> _loadProfessionalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'professional-auth');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('http://192.168.1.5:8000/api/pro/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentAvailability = data['available_now'] as bool;
        });
      } else {
        throw Exception(
          'Failed to load professional data: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAvailability(bool newValue) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final token = await _storage.read(key: 'professional-auth');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('http://192.168.1.5:8000/api/update/disponibilite'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'available_now': newValue}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _currentAvailability = newValue;
          _successMessage =
              responseData['message'] ?? 'Availability updated successfully';
        });
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to update availability',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Disponibilité',
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
          _isLoading && _currentAvailability == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SwitchListTile(
                          title: Text(
                            _currentAvailability == true
                                ? 'DIPONIBLE'
                                : 'INDISPONIBLE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  _currentAvailability == true
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                          subtitle: const Text(
                            'Modifier votre statut de disponibilité au travail',
                          ),
                          value: _currentAvailability ?? false,
                          onChanged:
                              _isLoading
                                  ? null
                                  : (value) => _updateAvailability(value),
                          secondary: Icon(
                            _currentAvailability == true
                                ? Icons.work
                                : Icons.work_off,
                            color:
                                _currentAvailability == true
                                    ? Colors.green
                                    : Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_successMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _successMessage,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
