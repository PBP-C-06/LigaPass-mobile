import 'package:flutter/material.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:ligapass/profiles/models/profile.dart';
import 'package:ligapass/profiles/screens/user_profile_page.dart';

class AdminSearchFilterCard extends StatelessWidget {
  final List<Profile> userProfiles;
  final bool loading;
  final String search;
  final String filter;
  final ImageProvider Function(String?) resolveImage;
  final void Function(String) onSearchChanged;
  final void Function(String) onFilterChanged;
  final TextEditingController searchController;

  final int currentPage;
  final int totalPages;
  final VoidCallback onNextPage;
  final VoidCallback onPrevPage;
  final void Function(String)? onUserDeleted;

  const AdminSearchFilterCard({
    super.key,
    required this.userProfiles,
    required this.loading,
    required this.search,
    required this.filter,
    required this.resolveImage,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.searchController,
    required this.currentPage,
    required this.totalPages,
    required this.onNextPage,
    required this.onPrevPage,
    this.onUserDeleted,
  });

  @override
  Widget build(BuildContext context) {
    const int pageSize = 5;
    final int start = (currentPage - 1) * pageSize;
    final int end = (start + pageSize) > userProfiles.length
        ? userProfiles.length
        : (start + pageSize);

    final List<Profile> pageItems =
        userProfiles.isEmpty ? [] : userProfiles.sublist(start, end);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            "Informasi Profil Pengguna",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xff1f2937),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Cari nama pengguna...",
              prefixIcon: const Icon(Icons.search),
              fillColor: const Color(0xfff6f7f9),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xfff6f7f9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButton<String>(
              value: filter,
              underline: const SizedBox(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: "all", child: Text("All")),
                DropdownMenuItem(value: "active", child: Text("Active")),
                DropdownMenuItem(value: "suspended", child: Text("Suspended")),
                DropdownMenuItem(value: "banned", child: Text("Banned")),
              ],
              onChanged: (v) => onFilterChanged(v!),
            ),
          ),

          const SizedBox(height: 24),

          loading
              ? const Center(child: CircularProgressIndicator())
              : pageItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Tidak ada profil untuk pencarian "$search" dengan filter "$filter".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  )
              : Column(
                  children: pageItems.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xfffafafa),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade200,
                            child: ClipOval(
                              child: Image(
                                image: resolveImage(p.profilePicture),
                                fit: BoxFit.cover,
                                width: 56,
                                height: 56,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    "assets/profile_images/default-profile-picture.png",
                                    fit: BoxFit.cover,
                                    width: 56,
                                    height: 56,
                                  );
                                },
                              )
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.username,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          TextButton(
                            onPressed: () async {
                              final deleted = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                    id: p.id,
                                    onUserDeleted: onUserDeleted,
                                  ),
                                ),
                              );

                              if (deleted == true) {
                                onUserDeleted?.call(p.id);
                              }
                            },
                            child: const Text(
                              "Detail",
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 1 ? onPrevPage : null,
                icon: const Icon(Icons.arrow_back_ios),
              ),
              Text("Page $currentPage of $totalPages"),
              IconButton(
                onPressed: currentPage < totalPages ? onNextPage : null,
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String resolveUrl(String? path) {
  if (path == null || path.isEmpty) {
    return "assets/profile_images/default-profile-picture.png";
  }
  return ApiConfig.resolveUrl(path);
}
