import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart'; // Assurez-vous que ce package est dans pubspec.yaml

// Importez vos autres pages. Vérifiez bien les chemins !
import 'package:bredproject/profile.dart';
import 'package:bredproject/listedemandeuser.dart';
import 'package:bredproject/aide.dart';
import 'package:bredproject/profilepro.dart';
import 'package:bredproject/demandepro.dart';
import 'package:bredproject/listenotation.dart';
import 'package:bredproject/dashboardpro.dart';

void main() => runApp(const HomeProScreen());

class HomeProScreen extends StatelessWidget {
  const HomeProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRED - Professionnel',
      // Thème général de l'application
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Bleu primaire fort
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF17BF63), // Vert accentué
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Fond léger
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB), // AppBar bleu
          foregroundColor: Colors.white, // Texte et icônes blancs
          elevation: 0, // Pas d'ombre pour un look moderne
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4, // Élévation par défaut des cartes
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ), // Coins arrondis par défaut
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF2563EB,
            ), // Fond des boutons primaires
            foregroundColor: Colors.white, // Texte des boutons primaires
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(
              0xFF2563EB,
            ), // Couleur des boutons texte
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        useMaterial3: true,
      ),
      home: const BredHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Modèle de données pour les statistiques professionnelles
class ProfessionalStats {
  final int pendingRequests;
  final int completedToday;
  final double rating;
  final int totalClients;

  ProfessionalStats({
    required this.pendingRequests,
    required this.completedToday,
    required this.rating,
    required this.totalClients,
  });
}

// Modèle de données pour les demandes d'intervention
class InterventionRequest {
  final int id;
  final String clientName;
  final String serviceType;
  final String requestedTime;
  final String status; // Ex: 'En attente', 'Confirmée', 'Terminée'

  InterventionRequest({
    required this.id,
    required this.clientName,
    required this.serviceType,
    required this.requestedTime,
    required this.status,
  });
}

class BredHomePage extends StatefulWidget {
  const BredHomePage({super.key});

  @override
  State<BredHomePage> createState() => _BredHomePageState();
}

class _BredHomePageState extends State<BredHomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Données fictives pour les statistiques du professionnel
  final ProfessionalStats stats = ProfessionalStats(
    pendingRequests: 3,
    completedToday: 5,
    rating: 4.7,
    totalClients: 42,
  );

  // Données fictives pour les demandes récentes
  final List<InterventionRequest> recentRequests = [
    InterventionRequest(
      id: 1,
      clientName: "Jean Dupont",
      serviceType: "Plomberie d'urgence",
      requestedTime: "Aujourd'hui, 09:30",
      status: "En attente",
    ),
    InterventionRequest(
      id: 2,
      clientName: "Marie Martin",
      serviceType: "Installation électrique",
      requestedTime: "Aujourd'hui, 11:15",
      status: "Confirmée",
    ),
    InterventionRequest(
      id: 3,
      clientName: "Pierre Lambert",
      serviceType: "Maintenance climatisation",
      requestedTime: "Hier, 16:45",
      status: "Terminée",
    ),
    InterventionRequest(
      id: 4,
      clientName: "Sophie Dubois",
      serviceType: "Réparation toiture",
      requestedTime: "Hier, 10:00",
      status: "En attente",
    ),
  ];

  late final List<Widget> _pages; // La liste des pages pour le PageView

  @override
  void initState() {
    super.initState();
    // Initialise les pages de l'application
    _pages = [
      ProfessionalDashboardApp(), // Page du tableau de bord
      const ProfessionalRequestsPage(), // Page des demandes
      const ProfessionalRatingsPage(), // Page d'aide
      const SettingsProPage(), // Page de profil
    ];
  }

  // --- Widget pour la page d'accueil du professionnel (Tableau de bord) ---
  Widget _buildProfessionalHomePage() {
    return Scaffold(
      // L'AppBar utilise le thème défini globalement
      appBar: AppBar(
        title: const Text(
          'Tableau de bord',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ), // Padding général
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de bienvenue
            const Text(
              'Bonjour,',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'John Doe', // Nom dynamique du professionnel
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 28),

            // Section statistiques
            const Text(
              'Votre activité en un coup d\'œil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 26),
            GridView.count(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Important pour le défilement dans SingleChildScrollView
              crossAxisCount: 2,
              // *** FIX CRITIQUE : childAspectRatio ajusté pour plus d'espace vertical ***
              childAspectRatio: 0.70, // Ratio plus petit = cartes plus HAUTES
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Demandes en attente',
                  stats.pendingRequests.toString(),
                  Feather.clock,
                  Colors.orange[700]!, // Teinte plus foncée
                ),
                _buildStatCard(
                  'Terminées aujourd\'hui',
                  stats.completedToday.toString(),
                  Feather.check_circle,
                  Colors.green[700]!,
                ),
                _buildStatCard(
                  'Note moyenne',
                  stats.rating.toStringAsFixed(1), // Formatage à une décimale
                  Feather.star,
                  Colors.amber[700]!,
                ),
                _buildStatCard(
                  'Clients servis',
                  stats.totalClients.toString(),
                  Feather.users,
                  Colors.blue[700]!,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Section demandes récentes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Demandes récentes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigue vers l'onglet "Demandes"
                    _selectedIndex = 1; // Index de l'onglet Demandes
                    _pageController.jumpToPage(
                      _selectedIndex,
                    ); // Navigue via PageView
                    setState(() {}); // Rafraîchit la BottomNavigationBar
                  },
                  icon: const Icon(Feather.arrow_right, size: 18),
                  label: const Text('Voir tout'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Message si aucune demande récente
            if (recentRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'Aucune demande récente pour le moment.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ...recentRequests
                  .map((request) => _buildRequestCard(request))
                  .toList(),
          ],
        ),
      ),
    );
  }

  // --- Widgets d'aide pour la construction des éléments UI ---

  // Construit une carte de statistique individuelle
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 6, // Ombre plus prononcée
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding suffisant
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween, // Distribue l'espace verticalement
          children: [
            Icon(icon, size: 36, color: color), // Grande icône
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              overflow:
                  TextOverflow.ellipsis, // Empêche le débordement du texte
              maxLines: 2, // Permet jusqu'à 2 lignes
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 26, // Grande taille pour la valeur
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construit une carte de demande d'intervention individuelle
  Widget _buildRequestCard(InterventionRequest request) {
    // Détermine la couleur du statut dynamiquement
    Color statusColorBg;
    Color statusColorText;
    switch (request.status) {
      case 'En attente':
        statusColorBg = Colors.orange[100]!;
        statusColorText = Colors.orange[800]!;
        break;
      case 'Confirmée':
        statusColorBg = Colors.blue[100]!;
        statusColorText = Colors.blue[800]!;
        break;
      case 'Terminée':
        statusColorBg = Colors.green[100]!;
        statusColorText = Colors.green[800]!;
        break;
      default:
        statusColorBg = Colors.grey[100]!;
        statusColorText = Colors.grey[800]!;
    }

    return Card(
      elevation: 3, // Légère ombre
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.clientName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColorBg,
                    borderRadius: BorderRadius.circular(
                      20,
                    ), // Forme de pilule pour le statut
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColorText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.serviceType,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Feather.clock,
                  size: 18,
                  color: Colors.grey[600],
                ), // Icône d'horloge
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.requestedTime,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Action pour voir les détails de la demande
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Affichage des détails de la demande ${request.id}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Feather.arrow_right,
                    size: 18,
                  ), // Icône de flèche
                  label: const Text('Détails'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Le corps contient le PageView qui gère le changement de page
      body: PageView(
        controller: _pageController,
        // Désactive le balayage manuel pour que la navigation soit gérée par la barre inférieure
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          // Met à jour l'index sélectionné si l'utilisateur change de page
          setState(() => _selectedIndex = index);
        },
      ),
      // La barre de navigation inférieure
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Navigue vers la page sélectionnée sans animation
            _pageController.jumpToPage(index);
          });
        },
        type:
            BottomNavigationBarType
                .fixed, // Assure que tous les libellés sont visibles
        selectedItemColor:
            Theme.of(
              context,
            ).colorScheme.primary, // Utilise la couleur primaire du thème
        unselectedItemColor:
            Colors.grey, // Couleur des éléments non sélectionnés
        items: const [
          BottomNavigationBarItem(icon: Icon(Feather.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Feather.clipboard),
            label: 'Demandes',
          ), // Icône changée pour "Demandes"
          BottomNavigationBarItem(icon: Icon(Feather.star), label: 'Note'),
          BottomNavigationBarItem(icon: Icon(Feather.user), label: 'Profil'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class UserRequestsPage extends StatelessWidget {
  const UserRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Demandes')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Feather.clipboard, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Gérez vos demandes de service ici.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centre d\'aide')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Feather.help_circle, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Trouvez l\'aide et le support nécessaires.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Feather.user, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Consultez et modifiez votre profil professionnel.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
