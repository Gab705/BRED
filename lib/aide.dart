import 'package:flutter/material.dart';
import 'package:bredproject/homepage.dart';

class OnboardingModel {
  final String imageUrl;
  final String title;
  final String description;

  OnboardingModel({
    required this.imageUrl,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingModel> _onboardingData = [
    OnboardingModel(
      imageUrl:
          "https://img.freepik.com/free-vector/sign-up-concept-illustration_114360-7885.jpg",
      title: "Inscription facile",
      description: "Crée ton compte en 30 secondes !",
    ),
    OnboardingModel(
      imageUrl:
          "https://img.freepik.com/free-vector/mobile-login-concept-illustration_114360-135.jpg",
      title: "Connecte-toi",
      description: "Accède à ton espace personnel.",
    ),
    OnboardingModel(
      imageUrl:
          "https://img.freepik.com/free-vector/job-search-concept-illustration_114360-1370.jpg",
      title: "Trouve un pro",
      description: "Recherche par métier ou localisation.",
    ),
    OnboardingModel(
      imageUrl:
          "https://img.freepik.com/free-vector/handyman-concept-illustration_114360-8374.jpg",
      title: "Demande de prestation",
      description:
          "Décris ton besoin et envoie la demande.", // Description ajoutée
    ),
    OnboardingModel(
      imageUrl:
          "https://img.freepik.com/free-vector/waiting-concept-illustration_114360-1374.jpg",
      title: "Attends la réponse",
      description: "Tu seras notifié dès que le pro accepte.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomepageScreen()),
                    ),
                child: const Text(
                  "Passer",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder:
                    (context, index) =>
                        OnboardingPage(model: _onboardingData[index]),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == index
                            ? Colors.blue
                            : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage == _onboardingData.length - 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomepageScreen()),
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _currentPage == _onboardingData.length - 1
                      ? "Commencer"
                      : "Suivant",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            MainAxisSize.min, // Ajouté pour éviter les problèmes de layout
        children: [
          Image.network(
            model.imageUrl,
            height: 250,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) =>
                    const Icon(Icons.error), // Gestion d'erreur
          ),
          const SizedBox(height: 30),
          Text(
            model.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (model.description.isNotEmpty) ...[
            // Condition pour afficher la description seulement si elle n'est pas vide
            const SizedBox(height: 10),
            Text(
              model.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
