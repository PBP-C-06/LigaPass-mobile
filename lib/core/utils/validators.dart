/// Kumpulan validator sederhana untuk form.
class Validators {
  const Validators._();

  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    final base = required(value, fieldName: 'Email');
    if (base != null) return base;
    final pattern = RegExp(r'^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
    if (!pattern.hasMatch(value!.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }
}
