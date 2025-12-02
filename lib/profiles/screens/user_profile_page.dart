import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/profiles/models/profile.dart';
import 'package:ligapass/profiles/widgets/user_profile_admin_action_card.dart';
import 'package:ligapass/profiles/widgets/user_profile_card.dart';
import 'package:ligapass/profiles/widgets/user_profile_user_action_card.dart';
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
  Future<Profile> fetchProfile(CookieRequest request) async {
    final url = "http://localhost:8000/profiles/json/${widget.id}/";
    final response = await request.get(url);

    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }

    return Profile.fromJson(response);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Profile",
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
          future: fetchProfile(request),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final profile = snapshot.data!;
            final role = request.jsonData['role'];
            String currentStatus = profile.status;

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
                  else if (role == 'user')
                    UserProfileUserActionCard(userId: profile.id),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
