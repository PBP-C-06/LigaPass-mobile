import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  XFile? _pickedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  DateTime? _selectedDob;
  bool _loading = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        setState(() {
          _username = args['username'] as String?;
        });
      }
    });
  }


  Future<void> submitProfile(
    CookieRequest request,
    String phone,
    String dob,
    XFile? image,
  ) async {
    setState(() => _loading = true);

    try {
      final uri = ApiConfig.uri("/profiles/flutter-create-profile/");
      var requestMultipart = http.MultipartRequest("POST", uri);

      requestMultipart.fields['phone'] = phone;
      requestMultipart.fields['date_of_birth'] = dob;

      if (_username != null && _username!.isNotEmpty) {
        requestMultipart.fields['username'] = _username!;
      }

      if (_selectedImageBytes != null && kIsWeb) {
        requestMultipart.files.add(
          http.MultipartFile.fromBytes(
            'profile_picture',
            _selectedImageBytes!,
            filename: _selectedImageName ?? 'profile_picture.jpg',
          ),
        );
      } else if (image != null) {
        requestMultipart.files.add(
          await http.MultipartFile.fromPath('profile_picture', image.path),
        );
      }

      final cookieHeader = request.cookies.entries
          .map((entry) => "${entry.key}=${entry.value.value}")
          .join("; ");
      if (cookieHeader.isNotEmpty) {
        requestMultipart.headers['Cookie'] = cookieHeader;
      }
      final csrfCookie = request.cookies['csrftoken'];
      if (csrfCookie != null) {
        requestMultipart.headers['X-CSRFToken'] = csrfCookie.value;
      }
      requestMultipart.headers['Accept'] = 'application/json';

      var response = await requestMultipart.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (!mounted) return;
        request.jsonData['hasProfile'] = true;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil dibuat!")),
        );
        Navigator.of(context).pushReplacementNamed("/home");
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 70);
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: firstDate,
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _selectedDob = selected;
        _dobController.text = DateFormat('yyyy-MM-dd').format(selected);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Builder(
                      builder: (context) {
                        final data = request.jsonData;
                        final username = _username ?? data['username'] ?? '-';
                        final email = data['email'] ?? '-';
                        final first = data['first_name'] ?? '';
                        final last = data['last_name'] ?? '';
                        final fullName = '$first $last'.trim().isEmpty ? '-' : '$first $last';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 28, horizontal: 22),
                                margin: const EdgeInsets.only(bottom: 24),
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
                                    const Text(
                                      "Profil User",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff1f2937),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(color: Colors.grey, thickness: 1),
                                    const SizedBox(height: 22),

                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 45,
                                          backgroundColor: Colors.grey.shade200,
                                          child: Icon(Icons.person,
                                              size: 50, color: Colors.grey.shade500),
                                        ),
                                        const SizedBox(width: 22),
                                        Expanded(
                                          child: Text(
                                            username,
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
                                    const SizedBox(height: 30),

                                    _infoRow("Nama Lengkap", fullName),
                                    const SizedBox(height: 16),
                                    _infoRow("Email", email),
                                  ],
                                ),
                              );
                            },
                          ),

                          Form(
                            key: _formKey,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Lengkapi Profil",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1d4ed8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: "Nomor Telepon",
                                      prefixIcon: Icon(Icons.phone),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return "Nomor telepon wajib diisi";
                                      }
                                      if (value.trim().length < 8) {
                                        return "Nomor telepon tidak valid";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: _dobController,
                                    readOnly: true,
                                    onTap: _pickDate,
                                    decoration: const InputDecoration(
                                      labelText: "Tanggal Lahir",
                                      prefixIcon: Icon(Icons.cake_outlined),
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Tanggal lahir wajib diisi";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 96,
                                          height: 96,
                                          color: const Color(0xFFE5E7EB),
                                          child: _selectedImageBytes != null
                                              ? Image.memory(
                                                  _selectedImageBytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 48,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1d4ed8),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _pickImage,
                                          icon: const Icon(Icons.upload_file),
                                          label: Text(
                                            _pickedImage == null
                                                ? "Upload Foto Profil"
                                                : "Ganti Foto Profil",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_pickedImage == null) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Opsional: unggah foto profil agar akun lebih mudah dikenali.",
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: _loading
                                          ? null
                                          : () async {
                                              if (!_formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }

                                              await submitProfile(
                                                request,
                                                _phoneController.text.trim(),
                                                _dobController.text.trim(),
                                                _pickedImage,
                                              );
                                            },
                                      child: const Text(
                                        "Simpan Profil",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
      // Untuk botton navbar
      bottomNavigationBar: const AppBottomNav(currentRoute: '/profile'),
    );
  }
}
