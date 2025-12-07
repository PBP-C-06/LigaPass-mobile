import 'package:flutter/material.dart';
import 'package:ligapass/profiles/models/admin_journalist_profile.dart';

class JournalistProfileCard extends StatelessWidget {
  final AdminJournalistProfile profile;

  const JournalistProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "Profil Jurnalis",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff1f2937),
              ),
            ),
          ),

          Divider(color: Colors.grey, thickness: 1),
          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile_images/Journalist.png',
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                      errorBuilder: (context, error, stack) {
                        return Image.asset(
                          'assets/profile_images/default-profile-picture.png',
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 22),

              Expanded(
                child: Text(
                  profile.username,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1f2937),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),
          Divider(color: Colors.grey, thickness: 1),
          const SizedBox(height: 25),

          const Text(
            "Informasi Tentang Jurnalis",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff1f2937),
            ),
          ),
          const SizedBox(height: 18),

          _infoRow("Jumlah Berita", "${profile.totalNews}"),
          const SizedBox(height: 16),
          _infoRow("Jumlah Pembaca", "${profile.totalViews}"),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xfff9fafb),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff6b7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xff1f2937),
            ),
          ),
        ],
      ),
    );
  }
}