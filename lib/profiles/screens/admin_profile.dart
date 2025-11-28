import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:ligapass/profiles/models/admin_journalist_profile.dart';
import 'package:ligapass/profiles/models/profile.dart';

// TODO buat nanti:
// - Pastikan route '/profiles/user/:id' atau page target sudah tersedia.
// - Sesuaikan BASE_URL jika server Django dijalankan di alamat lain.
// - Jika kamu memakai emulator Android gunakan http://10.0.2.2:8000

const String BASE_URL = 'http://localhost:8000';
const String ADMIN_PROFILE_ENDPOINT = '$BASE_URL/profiles/json/admin/';
const String SEARCH_FILTER_ENDPOINT = '$BASE_URL/profiles/json/admin/search-filter/';

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

  @override
  void initState() {
    super.initState();
    // initial fetch will be triggered in didChangeDependencies because we need CookieRequest from context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final request = context.watch<CookieRequest>();
    _fetchAdmin(request);
    _fetchProfiles(request, search: search, filter: filter);
  }

  Future<void> _fetchAdmin(CookieRequest request) async {
    setState(() {
      loadingAdmin = true;
    });
    try {
      final response = await request.get(ADMIN_PROFILE_ENDPOINT);
      // response is expected to be a JSON object
      if (response != null) {
        // AdminJournalistProfile.fromJson expects keys: username, profile_picture, total_news, total_views
        adminProfile = AdminJournalistProfile.fromJson(Map<String, dynamic>.from(response));
      } else {
        adminProfile = null;
      }
    } catch (e) {
      // handle error (silent here, show snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil profil admin: $e')),
      );
    } finally {
      setState(() {
        loadingAdmin = false;
      });
    }
  }

  Future<void> _fetchProfiles(
    CookieRequest request, {
    required String search,
    required String filter,
  }) async {
    setState(() {
      loadingProfiles = true;
    });

    try {
      final url = '$SEARCH_FILTER_ENDPOINT?search=${Uri.encodeQueryComponent(search)}&filter=${Uri.encodeQueryComponent(filter)}';
      final response = await request.get(url);
      profiles.clear();
      if (response != null) {
        // response expected to be List<dynamic>
        for (var item in response) {
          if (item != null) {
            profiles.add(Profile.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil daftar profil: $e')),
      );
    } finally {
      setState(() {
        loadingProfiles = false;
      });
    }
  }

  String _resolveImageUrl(String? picPath) {
    if (picPath == null || picPath.isEmpty) {
      return '$BASE_URL${"/static/images/default-profile-picture.png"}'; // fallback
    }
    // If API returns full URL already, use it
    if (picPath.startsWith('http://') || picPath.startsWith('https://')) {
      return picPath;
    }
    // If API returns a media path like '/media/...' or 'media/...' append BASE_URL
    if (!picPath.startsWith('/')) {
      return '$BASE_URL/$picPath';
    }
    return '$BASE_URL$picPath';
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Admin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: loadingAdmin
                    ? Row(
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(width: 12),
                          Text('Memuat profil admin...'),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(
                              _resolveImageUrl(adminProfile?.profilePicture),
                            ),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminProfile?.username ?? 'admin',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // If the logged-in user is admin, show search/filter and list.
            // We don't have the current_user endpoint here to check role; assume route only accessible by admin.
            // Search + Filter UI
            const Text('Informasi Profil Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            Row(
              children: [
                // Search input (flex)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari nama pengguna...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) async {
                      search = val;
                      // call fetch
                      await _fetchProfiles(request, search: search, filter: filter);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Filter dropdown
                DropdownButton<String>(
                  value: filter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                    DropdownMenuItem(value: 'banned', child: Text('Banned')),
                  ],
                  onChanged: (val) async {
                    if (val == null) return;
                    setState(() {
                      filter = val;
                    });
                    await _fetchProfiles(request, search: search, filter: filter);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Profiles list
            loadingProfiles
                ? const Center(child: CircularProgressIndicator())
                : profiles.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Tidak ada profil untuk pencarian "$search" dengan filter "$filter".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = profiles[index];
                          final imageUrl = _resolveImageUrl(p.profilePicture);
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(imageUrl),
                                onBackgroundImageError: (_, __) {},
                              ),
                              title: Text(p.username),
                              subtitle: Text(p.email),
                              trailing: TextButton(
                                child: const Text('Detail'),
                                onPressed: () {
                                  // Navigate to user profile page; assume named route exists
                                  // Replace with specific page if you have a widget for user profile
                                  Navigator.pushNamed(context, '/profiles/user/${p.id}');
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
