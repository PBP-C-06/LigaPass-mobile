import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/profiles/models/profile.dart';
import 'package:ligapass/profiles/widgets/user_profile_card.dart';
import 'package:ligapass/profiles/widgets/user_profile_user_action_card.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class UserProfilePage extends StatefulWidget {
  final String id;

  const UserProfilePage({super.key, required this.id});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Future<Profile> fetchProfile(CookieRequest request) async {
    final url = "http://localhost:8000/profiles/json/${widget.id}/";
    final response = await request.get(url);

    // print("DEBUG response: $response"); // Debug JSON

    if (response.containsKey('error')) {
      throw Exception(response['error']);
    }

    return Profile.fromJson(response);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      appBar: AppBar(
        title: const Text("User Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<Profile>(
        future: fetchProfile(request),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                UserProfileCard(profile: profile),
                const SizedBox(height: 5),
                UserProfileUserActionCard(userId: profile.id),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
