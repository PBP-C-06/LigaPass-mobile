import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class UserEditPage extends StatefulWidget {
  final String userId;
  final String? initialUsername;
  final String? initialEmail;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialPhone;
  final String? initialDateOfBirth;
  final String? initialProfilePicture;

  const UserEditPage({
    super.key,
    required this.userId,
    this.initialUsername,
    this.initialEmail,
    this.initialFirstName,
    this.initialLastName,
    this.initialPhone,
    this.initialDateOfBirth,
    this.initialProfilePicture,
  });

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  XFile? _pickedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  DateTime? _selectedDob;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.initialUsername ?? '',
    );
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _firstNameController = TextEditingController(
      text: widget.initialFirstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.initialLastName ?? '',
    );
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _dobController = TextEditingController(
      text: widget.initialDateOfBirth ?? '',
    );

    if (widget.initialDateOfBirth != null &&
        widget.initialDateOfBirth!.isNotEmpty) {
      try {
        _selectedDob = DateTime.parse(widget.initialDateOfBirth!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
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
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    }
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final request = context.read<CookieRequest>();
      final uri = ApiConfig.uri("/profiles/flutter-edit/${widget.userId}/");
      var multipartRequest = http.MultipartRequest("POST", uri);

      // Add form fields
      multipartRequest.fields['username'] = _usernameController.text.trim();
      multipartRequest.fields['email'] = _emailController.text.trim();
      multipartRequest.fields['first_name'] = _firstNameController.text.trim();
      multipartRequest.fields['last_name'] = _lastNameController.text.trim();
      multipartRequest.fields['phone'] = _phoneController.text.trim();
      multipartRequest.fields['date_of_birth'] = _dobController.text.trim();

      // Add profile picture if selected
      if (_selectedImageBytes != null && kIsWeb) {
        multipartRequest.files.add(
          http.MultipartFile.fromBytes(
            'profile_picture',
            _selectedImageBytes!,
            filename: _selectedImageName ?? 'profile_picture.jpg',
          ),
        );
      } else if (_pickedImage != null) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            _pickedImage!.path,
          ),
        );
      }

      // Add cookies and CSRF token
      final cookieHeader = request.cookies.entries
          .map((entry) => "${entry.key}=${entry.value.value}")
          .join("; ");
      if (cookieHeader.isNotEmpty) {
        multipartRequest.headers['Cookie'] = cookieHeader;
      }
      final csrfCookie = request.cookies['csrftoken'];
      if (csrfCookie != null) {
        multipartRequest.headers['X-CSRFToken'] = csrfCookie.value;
      }
      multipartRequest.headers['Accept'] = 'application/json';

      var response = await multipartRequest.send();
      final resBody = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memperbarui profil: $resBody"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profil",
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture Section
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            const Text(
                              "Foto Profil",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1d4ed8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      color: const Color(0xFFE5E7EB),
                                      child: _selectedImageBytes != null
                                          ? Image.memory(
                                              _selectedImageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : widget.initialProfilePicture != null
                                          ? Image.network(
                                              widget.initialProfilePicture!
                                                      .startsWith('http')
                                                  ? widget
                                                        .initialProfilePicture!
                                                  : '${ApiConfig.baseUrl}${widget.initialProfilePicture}',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.person,
                                                    size: 48,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 48,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1d4ed8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Ketuk untuk mengubah foto",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form Fields
                      Container(
                        padding: const EdgeInsets.all(20),
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
                              "Informasi Pribadi",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1d4ed8),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // First Name
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: "Nama Depan",
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Last Name
                            TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: "Nama Belakang",
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: "Username",
                                prefixIcon: Icon(Icons.alternate_email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Username wajib diisi";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: "Email",
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email wajib diisi";
                                }
                                if (!value.contains('@')) {
                                  return "Email tidak valid";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: "Nomor Telepon",
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date of Birth
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loading ? null : _submitEdit,
                        child: const Text(
                          "Simpan Perubahan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
