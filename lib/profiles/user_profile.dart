import 'package:flutter/material.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/profiles/profiles_colors.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  // Placeholder user role == admin 
  final bool isAdmin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BACK BUTTON
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profile card detail
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // title
                          const Text(
                            "Profil Pengguna",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Photo & username
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  height: 90,
                                  width: 90,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              const Expanded(
                                child: Text(
                                  "username_placeholder",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Detail data grid
                          GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 3.2,
                                ),
                            children: const [
                              _InfoItem(label: "Nama Lengkap", value: "-"),
                              _InfoItem(label: "Email", value: "-"),
                              _InfoItem(label: "Nomor Telepon", value: "-"),
                              _InfoItem(label: "Tanggal Lahir", value: "-"),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Edit profile button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {},
                              child: const Text("Ubah Profil"),
                            ),
                          ),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Show admin if isAdmin == true
                          if (isAdmin) ...[
                            const Text(
                              "Ubah Status User (Admin)",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: "active",
                                        items: const [
                                          DropdownMenuItem(
                                            value: "active",
                                            child: Text("Active"),
                                          ),
                                          DropdownMenuItem(
                                            value: "suspended",
                                            child: Text("Suspended"),
                                          ),
                                          DropdownMenuItem(
                                            value: "banned",
                                            child: Text("Banned"),
                                          ),
                                        ],
                                        onChanged: (value) {},
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryDeep,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: const Text("Konfirmasi"),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
