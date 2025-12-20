import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/common/widgets/logout_button.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:ligapass/profiles/models/profile.dart';
import 'package:ligapass/profiles/widgets/user_profile_admin_action_card.dart';
import 'package:ligapass/profiles/widgets/user_profile_card.dart';
import 'package:ligapass/profiles/widgets/user_profile_user_action_card.dart';
import 'package:ligapass/reviews/widgets/user_analytics.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class UserProfilePage extends StatefulWidget {
  final String id;
  final void Function(String)? onUserDeleted;

  const UserProfilePage({super.key, required this.id, this.onUserDeleted});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _initAndLoadProfile();
  }

  Future<Profile> _initAndLoadProfile() async {
    final request = context.read<CookieRequest>();

    if (!request.loggedIn) {
      throw Exception("Silakan login untuk mengakses profil.");
    }

    String? targetId = widget.id.isNotEmpty ? widget.id : null;

    if (targetId == null) {
      try {
        final resp =
            await request.get("${ApiConfig.baseUrl}/profiles/current_user_json/");
        if (resp is Map && resp["authenticated"] == true && resp["id"] != null) {
          targetId = resp["id"].toString();
        }
      } catch (_) {
        // fall through, will show error below
      }
    }

    if (targetId == null) {
      throw Exception("Tidak dapat memuat profil. Silakan login ulang.");
    }

    final url = "${ApiConfig.baseUrl}/profiles/json/$targetId/";
    final response = await request.get(url);

    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }

    return Profile.fromJson(response);
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _initAndLoadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil",
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
        child: FutureBuilder<Profile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _profileFuture = _initAndLoadProfile();
                          });
                        },
                        child: const Text('Coba Muat Ulang'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Profile not found'));
            }

            final profile = snapshot.data!;
            final role = request.jsonData['role'];
            String currentStatus = profile.status;
            final nameParts = profile.fullName.split(' ');
            final firstName = nameParts.isNotEmpty ? nameParts.first : '';
            final lastName = nameParts.length > 1
                ? nameParts.sublist(1).join(' ')
                : '';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  UserProfileCard(profile: profile),
                  if (role == 'admin')
                    UserProfileAdminActionCard(
                      userId: profile.id,
                      currentStatus: currentStatus,
                      onUserDeleted: widget.onUserDeleted,
                    )
                  else if (role == 'user') ...[
                    UserProfileUserActionCard(
                      userId: profile.id,
                      username: profile.username,
                      email: profile.email,
                      firstName: firstName,
                      lastName: lastName,
                      phone: profile.phone,
                      dateOfBirth: profile.dateOfBirth
                          .toIso8601String()
                          .split('T')
                          .first,
                      profilePicture: profile.profilePicture,
                      onEditSuccess: _refreshProfile,
                    ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return UserAnalyticsPanel(
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
                              color: Colors.black.withValues(alpha: 0.08),
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
                              "Lihat Analitik Pengguna",
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
                  ],
                  // Untuk button logout
                  const LogoutButton(),
                ],
              ),
            );
          },
        ),
      ),
      // Untuk botton navbar
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
