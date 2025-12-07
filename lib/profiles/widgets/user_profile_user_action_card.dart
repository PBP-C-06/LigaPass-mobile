import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:ligapass/profiles/screens/user_edit.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class UserProfileUserActionCard extends StatelessWidget {
  final String userId;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? dateOfBirth;
  final String? profilePicture;
  final VoidCallback? onEditSuccess;

  const UserProfileUserActionCard({
    super.key,
    required this.userId,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.dateOfBirth,
    this.profilePicture,
    this.onEditSuccess,
  });

  Future<bool> _deleteProfile(
    BuildContext context,
    CookieRequest request,
  ) async {
    try {
      final url = ApiConfig.uri("profiles/flutter-delete/$userId/").toString();
      final response = await request.postJson(
        url,
        jsonEncode({}), 
      );

      if (!context.mounted) return false;

      if (response['ok'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message']),backgroundColor: Colors.green,));
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus profil: ${response['message']}"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e"), 
      backgroundColor: Colors.red,));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 10, bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserEditPage(
                      userId: userId,
                      initialUsername: username,
                      initialEmail: email,
                      initialFirstName: firstName,
                      initialLastName: lastName,
                      initialPhone: phone,
                      initialDateOfBirth: dateOfBirth,
                      initialProfilePicture: profilePicture,
                    ),
                  ),
                );
                if (result == true && onEditSuccess != null) {
                  onEditSuccess!();
                }
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                "Ubah",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Konfirmasi Hapus"),
                    content: const Text(
                      "Apakah Anda yakin ingin menghapus profil ini?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (!context.mounted) return;
                  final ctx = context;
                  final success = await _deleteProfile(ctx, request);
                  if (success) {
                    if (!context.mounted) return;
                    request.loggedIn = false;
                    request.cookies.clear();
                    Navigator.pushReplacementNamed(ctx, '/login');
                  }
                }
              },
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text(
                "Hapus",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
