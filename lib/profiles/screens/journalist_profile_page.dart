import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/profiles/models/admin_journalist_profile.dart';
import 'package:ligapass/profiles/widgets/journalist_profile_card.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';


class JournalistProfilePage extends StatefulWidget {
  const JournalistProfilePage({super.key});

  @override
  State<JournalistProfilePage> createState() => _JournalistProfilePageState();
}

class _JournalistProfilePageState extends State<JournalistProfilePage> {
  Future<AdminJournalistProfile> fetchProfile(CookieRequest request) async {
    String url = "http://localhost:8000/profiles/json/journalist/";
    final response = await request.get(url);
    return AdminJournalistProfile.fromJson(response);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      appBar: AppBar(
        title: const Text("Journalist Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder(
        future: fetchProfile(request),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: JournalistProfileCard(profile: profile),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
