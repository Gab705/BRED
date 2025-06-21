import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bredproject/profile.dart';
import 'package:bredproject/intervention_service.dart';
import 'package:bredproject/listedemandeuser.dart';
import 'package:bredproject/aide.dart';
import 'package:bredproject/chatbit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // Ajout pour la fonctionnalité de partage
import 'package:bredproject/listenotationuser.dart';
import 'package:bredproject/demandepro.dart';

void main() => runApp(const HomepageScreen());

const storage = FlutterSecureStorage();

class HomepageScreen extends StatelessWidget {
  const HomepageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRED - Réparation Express',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1DA1F2),
          secondary: Color(0xFF17BF63),
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const BredHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Professional {
  final int id;
  final String name;
  final String phone;
  final String photo;
  final List<String> servicesOffered;
  final bool availableNow;
  final String zoneIntervention;
  final List<String> businessPhotos;

  Professional({
    required this.id,
    required this.name,
    required this.phone,
    required this.photo,
    required this.servicesOffered,
    required this.availableNow,
    required this.zoneIntervention,
    required this.businessPhotos,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    List<String> parsedBusinessPhotos = [];
    final dynamic rawBusinessPhotos = json['business_photos'];

    if (rawBusinessPhotos is String && rawBusinessPhotos.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBusinessPhotos);
        if (decoded is List) {
          parsedBusinessPhotos = List<String>.from(
            decoded.map((item) => item.toString()),
          );
        }
      } catch (e) {
        // En cas d'erreur de décodage JSON, la liste reste vide
      }
    }

    return Professional(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      photo: json['photo'] as String,
      servicesOffered: List<String>.from(json['services_offered'] ?? []),
      availableNow: json['available_now'] as bool,
      zoneIntervention: json['zone_intervention'] as String,
      businessPhotos: parsedBusinessPhotos,
    );
  }
}

class ProfessionalService {
  static Future<List<Professional>> fetchProfessionals() async {
    final token = await storage.read(key: 'auth_token');

    final response = await http.get(
      Uri.parse('http://192.168.1.5:8000/api/listepro'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List professionals = jsonResponse['data'];
      return professionals.map((pro) => Professional.fromJson(pro)).toList();
    } else {
      throw Exception('Failed to load professionals: ${response.statusCode}');
    }
  }

  static Future<List<Professional>> fetchProfessionalsByLocation(
    String location,
  ) async {
    final token = await storage.read(key: 'auth_token');

    final response = await http.get(
      Uri.parse(
        'http://192.168.1.5:8000/api/professionel/proximite?location=$location',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List professionals = jsonResponse['data'];

      if (professionals.isEmpty) {
        return [];
      }

      return professionals.map((pro) => Professional.fromJson(pro)).toList();
    } else {
      throw Exception(
        'Failed to load professionals by location: ${response.statusCode}',
      );
    }
  }
}

class HomeContent extends StatefulWidget {
  final String searchLocation;

  const HomeContent({super.key, required this.searchLocation});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Professional>> futureProfessionals;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProfessionals(widget.searchLocation);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(covariant HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchLocation != oldWidget.searchLocation) {
      _loadProfessionals(widget.searchLocation);
    }
  }

  void _loadProfessionals(String location) {
    setState(() {
      if (location.isEmpty) {
        futureProfessionals = ProfessionalService.fetchProfessionals();
      } else {
        futureProfessionals = ProfessionalService.fetchProfessionalsByLocation(
          location,
        );
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Implémenter le chargement supplémentaire ici si nécessaire
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    _loadProfessionals(widget.searchLocation);
  }

  Future<void> _showInterventionDialog(Professional professional) async {
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    Widget _buildDateTimeCard(
      BuildContext context, {
      required IconData icon,
      required String title,
      required String value,
      required VoidCallback onTap,
    }) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      );
    }

    final result = await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nouvelle intervention",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "avec ${professional.name}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: "Description du problème",
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      _buildDateTimeCard(
                        context,
                        icon: Icons.calendar_today_outlined,
                        title: "Date prévue",
                        value:
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            builder:
                                (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDateTimeCard(
                        context,
                        icon: Icons.access_time_outlined,
                        title: "Heure prévue",
                        value: selectedTime.format(context),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder:
                                (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.all(16),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Annuler",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (descriptionController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Veuillez saisir une description"),
                          ),
                        );
                        return;
                      }

                      final scheduledAt = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      try {
                        await InterventionService.createIntervention(
                          professionalId: professional.id,
                          description: descriptionController.text,
                          scheduledAt: scheduledAt,
                        );
                        if (mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erreur: ${e.toString()}"),
                              backgroundColor: Colors.red[400],
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "Envoyer",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              );
            },
          ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Demande envoyée à ${professional.name} !",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 4,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 3),
            dismissDirection: DismissDirection.horizontal,
            animation: CurvedAnimation(
              parent: kAlwaysCompleteAnimation,
              curve: Curves.easeOutQuint,
            ),
          ),
        );
      }
    }
  }

  void _saveProfessional(int id) {}

  // Nouvelle méthode pour partager un professionnel
  void _shareProfessional(Professional professional) {
    final String services = professional.servicesOffered.join(", ");
    final String shareText =
        "Découvrez ce professionnel sur BRED:\n\n"
        "👨‍🔧 Nom: ${professional.name}\n"
        "📱 Téléphone: ${professional.phone}\n"
        "🛠 Services: $services\n"
        "📍 Zone d'intervention: ${professional.zoneIntervention}\n\n"
        "Téléchargez l'application BRED pour trouver plus de professionnels près de chez vous!";

    Share.share(
      shareText,
      subject: "Professionnel BRED - ${professional.name}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          if (widget.searchLocation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Chip(
                    label: Text('Localisation: ${widget.searchLocation}'),
                    onDeleted: () {
                      final bredHomePageState =
                          context.findAncestorStateOfType<_BredHomePageState>();
                      bredHomePageState?._handleSearchSubmit('');
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Professional>>(
              future: futureProfessionals,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.searchLocation.isEmpty
                              ? 'Aucun professionnel disponible.'
                              : 'Aucun professionnel trouvé à "${widget.searchLocation}".',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.searchLocation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              final bredHomePageState =
                                  context
                                      .findAncestorStateOfType<
                                        _BredHomePageState
                                      >();
                              bredHomePageState?._handleSearchSubmit('');
                            },
                            child: const Text('Réinitialiser la recherche'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildProfessionalCard(
                      professional: snapshot.data![index],
                      context: context,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint(
        'Impossible de lancer l\'application téléphonique pour le numéro : $phoneNumber',
      );
    }
  }

  Widget _buildProfessionalCard({
    required Professional professional,
    required BuildContext context,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      professional.photo.isNotEmpty
                          ? CachedNetworkImageProvider(
                                'http://192.168.1.5:8000/storage/${professional.photo}',
                              )
                              as ImageProvider<Object>
                          : const AssetImage('assets/default_avatar.png'),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            professional.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  professional.availableNow
                                      ? Colors.green[50]
                                      : Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              professional.availableNow
                                  ? 'Disponible'
                                  : 'Occupé',
                              style: TextStyle(
                                color:
                                    professional.availableNow
                                        ? Colors.green
                                        : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        professional.phone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children:
                            professional.servicesOffered
                                .map(
                                  (service) => Chip(
                                    label: Text(
                                      service,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    backgroundColor: Colors.blue.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                      side: BorderSide(
                                        color: Colors.blue.shade100,
                                        width: 0.8,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                )
                                .toList(),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            professional.zoneIntervention,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (professional.businessPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        professional.businessPhotos.length > 1 ? 2 : 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: professional.businessPhotos.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl:
                          'http://192.168.1.5:8000/storage/${professional.businessPhotos[index]}',
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(color: Colors.grey[200]),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Feather.message_circle, size: 20),
                  onPressed: () => _showInterventionDialog(professional),
                ),
                IconButton(
                  icon: const Icon(Feather.phone, size: 20),
                  onPressed: () => _makePhoneCall(professional.phone),
                ),
                IconButton(
                  icon: const Icon(Feather.star, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfessionalRatingsViewPage(
                              professionalId:
                                  professional
                                      .id, // Paramètre nommé correctement
                            ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Feather.share_2, size: 20),
                  onPressed: () => _shareProfessional(professional),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String) onSearchSubmitted;

  const HomeAppBar({super.key, required this.onSearchSubmitted});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: _isSearching ? _buildSearchField(context) : const Text('BRED'),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Feather.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        IconButton(icon: const Icon(Feather.bell), onPressed: () {}),
      ],
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher par localisation...',
          prefixIcon: const Icon(Feather.search, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Feather.x, size: 20),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
              widget.onSearchSubmitted('');
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onSubmitted: (value) {
          widget.onSearchSubmitted(value);
          setState(() {
            _isSearching = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class BredHomePage extends StatefulWidget {
  const BredHomePage({super.key});

  @override
  State<BredHomePage> createState() => _BredHomePageState();
}

class _BredHomePageState extends State<BredHomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String _currentSearchLocation = '';

  void _handleSearchSubmit(String location) {
    setState(() {
      _currentSearchLocation = location;
      if (_selectedIndex != 0) {
        _pageController.jumpToPage(0);
        _selectedIndex = 0;
      }
      _updatePages();
    });
  }

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _updatePages();
  }

  void _updatePages() {
    _pages = [
      Scaffold(
        appBar: HomeAppBar(onSearchSubmitted: _handleSearchSubmit),
        body: HomeContent(searchLocation: _currentSearchLocation),
        floatingActionButton: const HomeFAB(),
      ),
      const UserRequestsPage(),
      const OnboardingScreen(),
      const SettingsPage(),
    ];
  }

  @override
  void didUpdateWidget(covariant BredHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.jumpToPage(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Feather.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Feather.list), label: 'Demandes'),
          BottomNavigationBarItem(
            icon: Icon(Feather.help_circle),
            label: 'Aide',
          ),
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

class HomeFAB extends StatelessWidget {
  const HomeFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WebViewScreen()),
        );
      },
      child: const Icon(Icons.chat_bubble, color: Colors.white),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }
}
