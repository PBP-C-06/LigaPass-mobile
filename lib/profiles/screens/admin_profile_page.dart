import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/common/widgets/logout_button.dart';
import 'package:ligapass/profiles/models/admin_journalist_profile.dart';
import 'package:ligapass/profiles/models/profile.dart';
import 'package:ligapass/profiles/widgets/admin_profile_card.dart';
import 'package:ligapass/profiles/widgets/admin_search_filter_card.dart';
import 'package:ligapass/reviews/widgets/admin_analytics.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

const String baseUrl = 'http://localhost:8000';
const String adminProfileEndpoint = '$baseUrl/profiles/json/admin/';
const String adminSearchFilterEndpoint =
    '$baseUrl/profiles/json/admin/search-filter/';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  AdminJournalistProfile? adminProfile;
  List<Profile> profiles = [];
  bool loadingAdmin = true;
  bool loadingProfiles = true;
  String search = '';
  String filter = 'all';

  final TextEditingController _searchController = TextEditingController();

  int currentPage = 1;
  int totalPages = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = context.watch<CookieRequest>();

    if (loadingAdmin) _fetchAdmin(request);

    _fetchProfiles(request, search: search, filter: filter);
  }

  Future<void> _fetchAdmin(CookieRequest request) async {
    setState(() => loadingAdmin = true);
    try {
      final response = await request.get(adminProfileEndpoint);
      if (response != null) {
        adminProfile = AdminJournalistProfile.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil profil admin: $e")),
      );
    } finally {
      setState(() => loadingAdmin = false);
    }
  }

  Future<void> _fetchProfiles(
    CookieRequest request, {
    required String search,
    required String filter,
  }) async {
    setState(() => loadingProfiles = true);
    try {
      final url =
          '$adminSearchFilterEndpoint?search=${Uri.encodeQueryComponent(search)}&filter=${Uri.encodeQueryComponent(filter)}';

      final response = await request.get(url);
      profiles.clear();

      if (response != null) {
        for (var item in response) {
          profiles.add(Profile.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      // Untuk menghitung pagination setelah di fetch
      setState(() {
        totalPages = (profiles.length / 5).ceil();
        if (totalPages < 1) totalPages = 1;

        // Reset to page awal jika search / filter berubah
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil daftar profil: $e")),
      );
    } finally {
      setState(() => loadingProfiles = false);
    }
  }

  String _resolveImageUrl(String? picPath) {
    if (picPath == null || picPath.isEmpty) {
      return '$baseUrl/static/images/default-profile-picture.png';
    }
    if (picPath.startsWith("http")) return picPath;
    if (!picPath.startsWith("/")) return "$baseUrl/$picPath";
    return "$baseUrl$picPath";
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Profile",
          style: TextStyle(
            color: Color(0xFF1d4ed8),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1d4ed8),
        iconTheme: const IconThemeData(color: Color(0xFF1d4ed8)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf6f9ff), Color(0xFFe8f0ff), Color(0xFFdce6ff)],
          ),
        ),
        child: loadingAdmin
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AdminProfileCard(adminProfile: adminProfile!),

                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            AdminSearchFilterCard(
                              userProfiles: profiles,
                              loading: loadingProfiles,
                              search: search,
                              filter: filter,
                              resolveImage: _resolveImageUrl,
                              searchController: _searchController,

                              onSearchChanged: (val) {
                                search = val;
                                _fetchProfiles(
                                  request,
                                  search: search,
                                  filter: filter,
                                );
                              },

                              onFilterChanged: (val) {
                                filter = val;
                                _fetchProfiles(
                                  request,
                                  search: search,
                                  filter: filter,
                                );
                              },

                              // Pagination
                              currentPage: currentPage,
                              totalPages: totalPages,
                              onNextPage: () {
                                if (currentPage < totalPages) {
                                  setState(() => currentPage++);
                                }
                              },
                              onPrevPage: () {
                                if (currentPage > 1) {
                                  setState(() => currentPage--);
                                }
                              },

                              onUserDeleted: (userId) {
                                setState(() {
                                  profiles.removeWhere((p) => p.id == userId);
                                  totalPages = (profiles.length / 5).ceil();
                                  if (totalPages < 1) totalPages = 1;
                                  if (currentPage > totalPages) {
                                    currentPage = totalPages;
                                  }
                                });
                              },
                            ),

                            GestureDetector(
                              onTap: () {
                                final request = context.read<CookieRequest>();

                                final sessionCookie = request.cookies.entries
                                    .map((e) => "${e.key}=${e.value}")
                                    .join("; ");

                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) {
                                    return AdminAnalyticsPanel(
                                      sessionCookie: sessionCookie,
                                      onClose: () => Navigator.pop(context),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1d4ed8),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      offset: const Offset(0, 3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.analytics, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      "Lihat Analitik Admin",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const LogoutButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),

      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
