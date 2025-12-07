import 'package:flutter/material.dart';
import 'package:ligapass/profiles/models/admin_journalist_profile.dart';

class AdminProfileCard extends StatelessWidget {
  final AdminJournalistProfile adminProfile;

  const AdminProfileCard({
    super.key,
    required this.adminProfile,
  });

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
              "Profil Admin",
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
                      'assets/profile_images/Admin.png',
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
                  adminProfile.username,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1f2937),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          Divider(color: Colors.grey, thickness: 1),
        ],
      ),
    );
  }
}