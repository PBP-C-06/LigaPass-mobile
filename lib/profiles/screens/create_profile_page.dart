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

  Future<void> submitProfile(CookieRequest request, String phone, String dob, File? image) async {
    setState(() => _loading = true);

    try {
      var uri = Uri.parse("http://localhost:8000/profiles/flutter-create-profile/");
      var requestMultipart = http.MultipartRequest("POST", uri);

      requestMultipart.fields['phone'] = phone;
      requestMultipart.fields['date_of_birth'] = dob;

      if (image != null) {
        requestMultipart.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          image.path,
        ));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Profil"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              // child: CreateProfileCard(
              //   onSubmit: (phone, dob, image) {
              //     submitProfile(request, phone, dob, image);
              //   },
              // ),
            ),
    );
  }
}
