import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';

/// Show review popup for a match
/// Returns true if review was successfully submitted
Future<bool> showReviewPopup(
  BuildContext context, {
  required String matchId,
  required String matchTitle,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _ReviewPopupContent(matchId: matchId, matchTitle: matchTitle),
  );
  return result ?? false;
}

class _ReviewPopupContent extends StatefulWidget {
  final String matchId;
  final String matchTitle;

  const _ReviewPopupContent({required this.matchId, required this.matchTitle});

  @override
  State<_ReviewPopupContent> createState() => _ReviewPopupContentState();
}

class _ReviewPopupContentState extends State<_ReviewPopupContent> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _ratingError;
  String? _commentError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      // Validate rating
      if (_selectedRating == 0) {
        _ratingError = 'Rating harus dipilih';
        isValid = false;
      } else {
        _ratingError = null;
      }

      // Validate comment
      if (_commentController.text.trim().isEmpty) {
        _commentError = 'Ulasan tidak boleh kosong';
        isValid = false;
      } else {
        _commentError = null;
      }
    });

    return isValid;
  }

  Future<void> _submitReview() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = context.read<CookieRequest>();
      final url = ApiConfig.resolveUrl(
        '/reviews/api/${widget.matchId}/create/',
      );

      final response = await request.post(url, {
        'rating': _selectedRating.toString(),
        'comment': _commentController.text.trim(),
      });

      if (!mounted) return;

      if (response['ok'] == true) {
        _showSnackBar('Review berhasil dikirim!', isError: false);
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final message = response['message'] ?? 'Gagal mengirim review';
        _showSnackBar(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Text(
            "Beri Ulasan Anda",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 15),

          // Subtitle
          const Text(
            "Bagaimana pengalaman menonton pertandingan ini?",
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Rating stars
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      size: 36,
                      color: i < _selectedRating
                          ? const Color(0xFFFBBF24)
                          : _ratingError != null
                          ? Colors.red.shade200
                          : Colors.grey.shade300,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _selectedRating = i + 1;
                              _ratingError = null; // Clear error on selection
                            });
                          },
                  );
                }),
              ),
              // Rating error message
              if (_ratingError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _ratingError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 4,
            enabled: !_isSubmitting,
            onChanged: (value) {
              // Clear error when user starts typing
              if (_commentError != null && value.trim().isNotEmpty) {
                setState(() => _commentError = null);
              }
            },
            decoration: InputDecoration(
              hintText: "Tulis pengalaman Anda...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: _commentError != null
                  ? Colors.red.shade50
                  : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: _commentError != null
                    ? const BorderSide(color: Colors.red)
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: _commentError != null
                    ? const BorderSide(color: Colors.red)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _commentError != null
                      ? Colors.red
                      : const Color(0xFF2563EB),
                ),
              ),
              errorText: _commentError,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Submit button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Kirim",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
