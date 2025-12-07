import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class UserProfileAdminActionCard extends StatefulWidget {
  final String userId;
  final String currentStatus;
  final void Function(String)? onUserDeleted; 

  const UserProfileAdminActionCard({
    super.key,
    required this.userId,
    required this.currentStatus,
    this.onUserDeleted,
  });

  @override
  State<UserProfileAdminActionCard> createState() => _UserProfileAdminActionCardState();
}

class _UserProfileAdminActionCardState extends State<UserProfileAdminActionCard> {
  late String _selectedStatus; 
  final List<String> _statuses = ["active", "suspended", "banned"];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus; 
  }

  Future<void> _changeStatus(CookieRequest request) async {
    try {
      final url = "http://localhost:8000/profiles/admin/flutter-edit/${widget.userId}/";
      final response = await request.postJson(
        url,
        jsonEncode({"status": _selectedStatus}),
      );
      
      if (response['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']),
          backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update status: ${response['message']}"),
          backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e"),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(CookieRequest request) async {
    try {
      final url = "http://localhost:8000/profiles/flutter-delete/${widget.userId}/";
      final response = await request.postJson(url, jsonEncode({}));

      if (!context.mounted) return;

      if (response['ok'] == true) {
        if (!mounted) return;

        if (widget.onUserDeleted != null) {
          widget.onUserDeleted!(widget.userId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']),
          backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus user: ${response['message']}"),
          backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e"),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Ubah Status User",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            initialValue: _selectedStatus, 
            items: _statuses.map((status) => DropdownMenuItem(
              value: status,
              child: Text(status),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await _changeStatus(request);
              },
              child: const Text(
                "Ubah Status",
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
                    content: const Text("Apakah Anda yakin ingin menghapus user ini?"),
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
                  await _deleteUser(request);
                }
              },
              child: const Text(
                "Hapus Pengguna",
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
