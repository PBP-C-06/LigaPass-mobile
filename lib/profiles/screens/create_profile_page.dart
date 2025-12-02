import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  bool _loading = false;

  Future<void> submitProfile(
    CookieRequest request,
    String phone,
    String dob,
    File? image,
  ) async {
    setState(() => _loading = true);

    try {
      var uri = Uri.parse(
        "http://localhost:8000/profiles/flutter-create-profile/",
      );
      var requestMultipart = http.MultipartRequest("POST", uri);

      requestMultipart.fields['phone'] = phone;
      requestMultipart.fields['date_of_birth'] = dob;

      if (image != null) {
        requestMultipart.files.add(
          await http.MultipartFile.fromPath('profile_picture', image.path),
        );
      }

      // Tambahkan cookie dari CookieRequest
      request.cookies.forEach((name, value) {
        requestMultipart.headers['Cookie'] =
            "$name=$value; ${requestMultipart.headers['Cookie'] ?? ''}";
      });

      var response = await requestMultipart.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil dibuat!")),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuat profil: $resBody")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Buat Profil",
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                // child: CreateProfileCard(
                //   onSubmit: (phone, dob, image) {
                //     submitProfile(request, phone, dob, image);
                //   },
                // ),
              ),
      ),
    );
  }
}
