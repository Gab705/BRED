import 'dart:convert';
import 'dart:io'; // Import for File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cinetpay/cinetpay.dart'; // Make sure this package is correctly imported
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  String name = '',
      email = '',
      phone = '',
      password = '',
      location = '',
      zoneIntervention = '';

  XFile? photo, cni, diploma, workPhoto;
  List<XFile> businessPhotos = [];

  bool loading = false;

  // Expanded list of services
  List<String> allServices = [
    'Mécanique générale',
    'Plomberie d\'urgence',
    'Installation électrique',
    'Maintenance climatisation',
    'Menuiserie sur mesure',
    'Serrurerie',
    'Peinture intérieure',
    'Réparation toiture',
    'Nettoyage professionnel',
    'Aménagement paysager',
    'Installation de chauffage',
    'Dépannage informatique',
    'Vitrerie',
    'Désinfection et dératisation',
    'Maçonnerie',
    'Rénovation salle de bain',
    'Installation caméra de surveillance',
    'Débouchage canalisation',
    'Réparation électroménager',
    'Pose de carrelage',
  ];
  List<String> servicesOffered = [];

  @override
  void initState() {
    super.initState();
    // Initialize servicesOffered if needed, or leave empty
  }

  // --- File Picking Functions ---
  Future<void> pickFile(Function(XFile?) onPicked) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => onPicked(pickedFile));
    } else {
      // Optional: show a message if nothing was picked
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier sélectionné')),
      );
    }
  }

  Future<void> pickMultipleFiles() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() => businessPhotos = pickedFiles);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier sélectionné')),
      );
    }
  }

  // --- Form Submission ---
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check for required files
    if (photo == null ||
        cni == null ||
        diploma == null ||
        workPhoto == null ||
        businessPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tous les fichiers (photo, CNI, diplôme, photo de travail et photos d\'entreprise) sont requis.',
          ),
        ),
      );
      return;
    }

    if (servicesOffered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un service proposé.'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://192.168.1.5:8000/api/pro/register',
        ), // Make sure this IP is correct for your setup
      );
      request.headers.addAll({'Accept': 'application/json'});

      request.fields.addAll({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'location': location,
        'is_active': 'false', // Assuming this is initially false
        'zone_intervention': zoneIntervention,
        'available_now': 'true', // Assuming this is initially true
      });

      for (var service in servicesOffered) {
        request.fields.addAll({'services_offered[]': service});
      }

      // Add files
      request.files.addAll([
        await http.MultipartFile.fromPath('photo', photo!.path),
        await http.MultipartFile.fromPath('cni_path', cni!.path),
        await http.MultipartFile.fromPath('diploma_path', diploma!.path),
        await http.MultipartFile.fromPath('work_photo_path', workPhoto!.path),
      ]);

      // Add multiple business photos
      for (var file in businessPhotos) {
        request.files.add(
          await http.MultipartFile.fromPath('business_photos[]', file.path),
        );
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      print("Réponse brute: $responseString"); // For debugging

      final data = json.decode(responseString);

      if (response.statusCode == 200 && data['status'] == 1) {
        final user = data['data'];
        // Show success message before opening CinetPay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Inscription réussie ! Procédez au paiement.'),
          ),
        );
        _openWavePayment(user);
      } else {
        String errorMessage = 'Erreur lors de l\'inscription.';
        if (data != null && data['message'] != null) {
          errorMessage = data['message'];
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Erreur: $errorMessage')));
      }
    } catch (e) {
      print('Erreur lors de l’envoi : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Erreur réseau ou de traitement des données.'),
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // --- CinetPay Integration ---
  static const String wavePaymentLink =
      "https://pay.wave.com/m/M_ci_ISQu1nm0GhJV/c/ci/?amount=100";

  void _openWavePayment(dynamic user) async {
    // Essayer d'ouvrir directement dans l'application Wave
    final deepLink = Uri.parse(
      'https://pay.wave.com/m/M_ci_ISQu1nm0GhJV/c/ci/?amount=100',
    );

    try {
      if (await canLaunchUrl(deepLink)) {
        await launchUrl(deepLink, mode: LaunchMode.externalApplication).then((
          _,
        ) {
          // Redirection vers login après retour de l'app externe
          Navigator.pushReplacementNamed(context, '/login');
        });
        return;
      }
    } catch (e) {
      print("Erreur d'ouverture de l'app Wave: $e");
    }

    // Fallback: Ouvrir dans le WebView
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                if (request.url.startsWith('intent://') ||
                    request.url.contains('play.google.com')) {
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onUrlChange: (change) {
                // Quand l'utilisateur revient de Wave (peu importe le résultat)
                if (change.url == null || change.url!.isEmpty) return;

                if (change.url!.contains('pay.wave.com') ||
                    change.url!.contains('return')) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(wavePaymentLink));

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Paiement Wave'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/loginPro');
                  },
                ),
              ),
              body: WebViewWidget(controller: controller),
            ),
      ),
    );

    // Double sécurité pour la redirection
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
  // --- Widget Builders ---

  @override
  Widget build(BuildContext context) {
    // Access theme for text styles if needed
    // final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Inscription Pro 👷',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Créer votre compte professionnel",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Rejoignez notre réseau de professionnels qualifiés.",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 32),

                // Personal Information Fields
                _buildTextField(
                  label: 'Nom Complet',
                  icon: Icons.person,
                  onChanged: (v) => name = v,
                ),
                _buildTextField(
                  label: 'Adresse Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => email = v,
                ),
                _buildTextField(
                  label: 'Numéro de Téléphone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => phone = v,
                ),
                _buildTextField(
                  label: 'Mot de passe',
                  icon: Icons.lock,
                  obscure: true,
                  onChanged: (v) => password = v,
                ),
                _buildTextField(
                  label: 'Localisation (Ville/Quartier)',
                  icon: Icons.location_on,
                  onChanged: (v) => location = v,
                ),
                _buildTextField(
                  label: 'Zone d\'Intervention',
                  icon: Icons.map,
                  onChanged: (v) => zoneIntervention = v,
                ),

                const SizedBox(height: 24),

                // Services Offered Selection
                _buildServicesDropdown(),
                if (servicesOffered.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0, // horizontal space between chips
                    runSpacing: 8.0, // vertical space between lines of chips
                    children:
                        servicesOffered.map((service) {
                          return Chip(
                            label: Text(service),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                servicesOffered.remove(service);
                              });
                            },
                            backgroundColor: Colors.green[50],
                            labelStyle: TextStyle(color: Colors.green[800]),
                            side: BorderSide(color: Colors.green[200]!),
                          );
                        }).toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // File Upload Sections
                const Text(
                  "Documents et Photos (Obligatoire)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFileUploadField(
                  label: "Photo de Profil",
                  onPressed: () => pickFile((f) => setState(() => photo = f)),
                  file: photo,
                ),
                _buildFileUploadField(
                  label: "Carte Nationale d'Identité (CNI)",
                  onPressed: () => pickFile((f) => setState(() => cni = f)),
                  file: cni,
                ),
                _buildFileUploadField(
                  label: "Diplôme / Certification",
                  onPressed: () => pickFile((f) => setState(() => diploma = f)),
                  file: diploma,
                ),
                _buildFileUploadField(
                  label: "Photo en situation de travail",
                  onPressed:
                      () => pickFile((f) => setState(() => workPhoto = f)),
                  file: workPhoto,
                ),
                _buildMultipleFileUploadField(
                  label: "Photos d'entreprise / Réalisations (min. 1)",
                  onPressed: pickMultipleFiles,
                  files: businessPhotos,
                ),
                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700, // Primary blue
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5, // Subtle shadow for depth
                  ),
                  child:
                      loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "S'inscrire et Payer les Frais",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(height: 20),

                // "Already registered" link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/loginPro'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text("Déjà inscrit ? Se connecter ici"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Reusable Widget Builders ---

  // Text Field with Icon
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        obscureText: obscure,
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator:
            (value) =>
                (value == null || value.isEmpty) ? 'Ce champ est requis' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]), // Icon
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // File Upload Field (Single File)
  Widget _buildFileUploadField({
    required String label,
    required VoidCallback onPressed,
    XFile? file,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload, color: Colors.blueGrey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file != null ? file.name : "Aucun fichier sélectionné",
                      style: TextStyle(
                        color: file != null ? Colors.black87 : Colors.grey[600],
                        fontStyle:
                            file != null ? FontStyle.normal : FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (file != null &&
                      (file.path.endsWith('.jpg') ||
                          file.path.endsWith('.png') ||
                          file.path.endsWith('.jpeg')))
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(file.path),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Multiple File Upload Field
  Widget _buildMultipleFileUploadField({
    required String label,
    required VoidCallback onPressed,
    required List<XFile> files,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.collections, color: Colors.blueGrey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      files.isNotEmpty
                          ? '${files.length} fichier(s) sélectionné(s)'
                          : "Cliquez pour choisir des photos",
                      style: TextStyle(
                        color:
                            files.isNotEmpty
                                ? Colors.black87
                                : Colors.grey[600],
                        fontStyle:
                            files.isNotEmpty
                                ? FontStyle.normal
                                : FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.add_a_photo, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
          if (files.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 100, // Fixed height for the grid
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // Only one row
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1, // Make items square
                ),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(files[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              files.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Services Multi-Select Dropdown
  Widget _buildServicesDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Services Proposés",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final List<String>? result = await showModalBottomSheet(
              context: context,
              isScrollControlled:
                  true, // Allows content to take up full height if needed
              builder: (context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter modalSetState) {
                    return Container(
                      height:
                          MediaQuery.of(context).size.height *
                          0.75, // Adjust height
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Sélectionnez vos services",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: allServices.length,
                              itemBuilder: (context, index) {
                                final service = allServices[index];
                                return CheckboxListTile(
                                  title: Text(service),
                                  value: servicesOffered.contains(service),
                                  onChanged: (bool? selected) {
                                    modalSetState(() {
                                      if (selected == true) {
                                        servicesOffered.add(service);
                                      } else {
                                        servicesOffered.remove(service);
                                      }
                                    });
                                  },
                                  activeColor: Colors.blue.shade700,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, servicesOffered);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Confirmer la sélection",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
            if (result != null) {
              setState(() {
                servicesOffered = result;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.handyman,
                  color: Colors.grey[600],
                ), // Icon for services
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    servicesOffered.isEmpty
                        ? "Sélectionnez les services proposés"
                        : "${servicesOffered.length} service(s) sélectionné(s)",
                    style: TextStyle(
                      color:
                          servicesOffered.isEmpty
                              ? Colors.grey[600]
                              : Colors.black87,
                      fontStyle:
                          servicesOffered.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
