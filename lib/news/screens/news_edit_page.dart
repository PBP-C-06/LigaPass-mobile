import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:ligapass/config/endpoints.dart';

class EditNewsPage extends StatefulWidget {
  final Map<String, dynamic> news;

  const EditNewsPage({super.key, required this.news});

  @override
  State<EditNewsPage> createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  String _selectedCategory = "update";
  bool _isFeatured = false;

  Uint8List? _selectedImageBytes;
  XFile? _pickedImage;

  bool _loading = false;
  bool _deleteCurrentImage = false;

  final List<String> _categories = [
    'update',
    'transfer',
    'exclusive',
    'match',
    'rumor',
    'analysis',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.news["title"]);
    _contentController = TextEditingController(text: widget.news["content"]);
    _selectedCategory = widget.news["category"];
    _isFeatured = widget.news["is_featured"];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _selectedImageBytes = bytes;
        _deleteCurrentImage = false;
      });
    }
  }

  Future<void> _submitEdit(CookieRequest request) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String? base64Image;
      if (_selectedImageBytes != null) {
        base64Image = base64Encode(_selectedImageBytes!);
      }

      final data = {
        "title": _titleController.text,
        "content": _contentController.text,
        "category": _selectedCategory,
        "is_featured": _isFeatured,
        "thumbnail_base64": base64Image,
        "delete_thumbnail": _deleteCurrentImage,
      };

      final response = await request.postJson(
        Endpoints.editNews(widget.news["id"]),
        jsonEncode(data),
      );

      if (response["status"] == "success") {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berita berhasil diperbarui")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${response['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.01),
              elevation: 0,
              centerTitle: true,
              title: Text(
                "Edit Berita",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFf6f9ff),
              Color(0xFFe8f0ff),
              Color(0xFFdce6ff),
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Form(
                      key: _formKey,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Edit Berita",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Perbarui informasi dan gambar berita",
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 24),

                              // === Judul ===
                              const Text("Judul Berita"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,
                                maxLength: 100,
                                decoration: InputDecoration(
                                  hintText: "Perbarui judul berita...",
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  counterStyle: const TextStyle(fontSize: 12),
                                ),
                                validator: (value) => value == null || value.isEmpty
                                    ? "Judul wajib diisi"
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // === Konten ===
                              const Text("Konten Berita"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _contentController,
                                maxLines: 8,
                                decoration: InputDecoration(
                                  hintText: "Perbarui isi berita...",
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) => value == null || value.isEmpty
                                    ? "Konten wajib diisi"
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // === Kategori & Featured ===
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCategory,
                                      decoration: InputDecoration(
                                        labelText: "Kategori",
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      items: _categories
                                          .map((cat) => DropdownMenuItem(
                                                value: cat,
                                                child: Text(cat[0].toUpperCase() + cat.substring(1)),
                                              ))
                                          .toList(),
                                      onChanged: (value) =>
                                          setState(() => _selectedCategory = value ?? 'update'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    child: CheckboxListTile(
                                      value: _isFeatured,
                                      onChanged: (value) =>
                                          setState(() => _isFeatured = value ?? false),
                                      title: const Text("Unggulan"),
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // === Thumbnail ===
                              const Text("Thumbnail Berita"),
                              const SizedBox(height: 8),

                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _selectedImageBytes != null
                                        ? Image.memory(
                                            _selectedImageBytes!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          )
                                        : (widget.news["thumbnail"] != null && !_deleteCurrentImage)
                                            ? Image.network(
                                                widget.news["thumbnail"],
                                                width: double.infinity,
                                                height: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Image.asset(
                                                  'assets/placeholder.png',
                                                  width: double.infinity,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Container(
                                                height: 200,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                                                ),
                                              ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.upload, color: Colors.blueAccent),
                                    label: Text(
                                      _pickedImage == null ? "Unggah Gambar" : "Ganti Gambar",
                                      style: const TextStyle(color: Colors.blueAccent),
                                    ),
                                  ),
                                  if (widget.news["thumbnail"] != null && _selectedImageBytes == null)
                                    TextButton.icon(
                                      onPressed: () => setState(() => _deleteCurrentImage = true),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      label: const Text("Hapus Gambar", style: TextStyle(color: Colors.red)),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // === Submit ===
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text("Simpan Perubahan"),
                                  onPressed: () => _submitEdit(request),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class DottedBorderContainer extends StatelessWidget {
  final Widget child;

  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: child,
    );
  }
}