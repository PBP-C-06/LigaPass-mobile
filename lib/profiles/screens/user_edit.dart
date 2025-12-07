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

      multipartRequest.fields['username'] = _usernameController.text.trim();
      multipartRequest.fields['email'] = _emailController.text.trim();
      multipartRequest.fields['first_name'] = _firstNameController.text.trim();
      multipartRequest.fields['last_name'] = _lastNameController.text.trim();
      multipartRequest.fields['phone'] = _phoneController.text.trim();
      multipartRequest.fields['date_of_birth'] = _dobController.text.trim();

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
          "Ubah Profil",
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF5F6F7),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ubah Profil",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          Divider(color: Colors.grey, thickness: 1),
                          const SizedBox(height: 20),

                          Center(
                            child: GestureDetector(
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
                                                      ? widget.initialProfilePicture!
                                                      : '${ApiConfig.baseUrl}${widget.initialProfilePicture}',
                                                  fit: BoxFit.cover,
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
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              "Ketuk untuk mengubah foto",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _inputField(
                            label: "Nama Depan",
                            controller: _firstNameController,
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),

                          _inputField(
                            label: "Nama Belakang",
                            controller: _lastNameController,
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),

                          _inputField(
                            label: "Username",
                            controller: _usernameController,
                            icon: Icons.alternate_email,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Username wajib diisi";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _inputField(
                            label: "Email",
                            controller: _emailController,
                            icon: Icons.email,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Email wajib diisi";
                              }
                              if (!v.contains('@')) return "Email tidak valid";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _inputField(
                            label: "Nomor Telepon",
                            controller: _phoneController,
                            icon: Icons.phone,
                            keyboard: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tanggal Lahir",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                onTap: _pickDate,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.cake_outlined),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Simpan Perubahan",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboard,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}