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
      appBar: AppBar(
        title: const Text(
          "Journalist Profile",
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
        child: FutureBuilder(
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
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
