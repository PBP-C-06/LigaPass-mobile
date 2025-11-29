import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  _CreateProfilePageState createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  File? _profilePicture;
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _profilePicture = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm(CookieRequest cookieRequest) async {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri.parse("http://localhost:8000/profiles/create/");
    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll(cookieRequest.headers);

    if (_profilePicture != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          _profilePicture!.path,
        ),
      );
    }

    request.fields['phone'] = _phoneController.text;
    request.fields['date_of_birth'] =
        _selectedDate != null ? _selectedDate!.toIso8601String() : '';

    try {
      var streamedResponse = await request.send();
      var respStr = await streamedResponse.stream.bytesToString();
      var data = jsonDecode(respStr);

      if (streamedResponse.statusCode == 201 && data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacementNamed(context, '/matches');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? "Terjadi kesalahan."),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terjadi kesalahan saat mengirim data."),
          backgroundColor: Colors.red,
        ),
      );
      print("Error submit profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    final username = request.jsonData['username'] ?? '';
    final fullName = request.jsonData['full_name'] ?? '';
    final email = request.jsonData['email'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Lengkapi Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Text(
                "Selamat datang, ${username.isNotEmpty ? username : 'User'}!",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Lengkapi profil Anda sebelum membeli tiket 🎫",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Foto Profil
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _profilePicture != null ? FileImage(_profilePicture!) : null,
                  child: _profilePicture == null
                      ? const Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Nama Lengkap
              TextFormField(
                initialValue: fullName,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 12),

              // Username
              TextFormField(
                initialValue: username,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Nama Pengguna",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                initialValue: email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 12),

              // Nomor Telepon
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val == null || val.isEmpty ? "Nomor telepon wajib diisi" : null,
                decoration: const InputDecoration(
                  labelText: "Nomor Telepon",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Tanggal Lahir
              GestureDetector(
                onTap: () => _pickDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? _selectedDate!.toIso8601String().split("T")[0]
                          : '',
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Tanggal lahir wajib diisi" : null,
                    decoration: const InputDecoration(
                      labelText: "Tanggal Lahir",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submitForm(request),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text("Selanjutnya", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
