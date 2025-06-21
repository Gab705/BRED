import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:bredproject/login_screen.dart';
import 'package:bredproject/registerpro.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  bool isLoading = false;

  Future<void> pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<void> register() async {
    setState(() => isLoading = true);

    final uri = Uri.parse("http://192.168.1.5:8000/api/register");
    final request = http.MultipartRequest("POST", uri);

    request.fields['name'] = nameController.text;
    request.fields['phone'] = phoneController.text;
    request.fields['email'] = emailController.text;
    request.fields['password'] = passwordController.text;

    if (_pickedImage != null) {
      final file = await http.MultipartFile.fromPath(
        "photo",
        _pickedImage!.path,
      );
      request.files.add(file);
    } else {
      request.fields['photo'] = "photoUser/default.jpg";
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['token'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte créé avec succès')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Erreur de création')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur réseau : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text(
                  "Créer un compte ✨",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: const Color(0xFF1F252E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Inscris-toi pour commencer.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Nom
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),

                // Téléphone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Upload Photo
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade200.withOpacity(0.3),
                          Colors.purple.shade200.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.blue.shade400, width: 2),
                    ),
                    alignment: Alignment.center,
                    child:
                        _pickedImage == null
                            ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Colors.blue.shade400,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Cliquer pour choisir une photo",
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: 4 / 3, // ou 1 si tu veux un carré
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 30),

                // Mot de passe
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton S'inscrire
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // couleur du bouton
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 20),

                // Déjà un compte ?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Déjà un compte ? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Se connecter",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center, // This centers children horizontally in the Row
                  children: [
                    const SizedBox(
                      height: 8,
                    ), // Note: SizedBox(height: ...) only adds vertical space.
                    // In a Row, it behaves like a normal child and takes up horizontal space.
                    // If you intended vertical space *above* the GestureDetector in a Row context,
                    // you might want to consider the parent widget of this Row.
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                      },
                      child: Text(
                        "S'inscrire professionnel 👷",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
