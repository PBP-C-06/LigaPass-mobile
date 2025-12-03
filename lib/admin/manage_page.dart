import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ligapass/admin/admin_api_service.dart';
import 'package:ligapass/admin/models.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/config/api_config.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class AdminManagePage extends StatelessWidget {
  const AdminManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isAdmin = request.loggedIn && request.jsonData['role'] == 'admin';

    return DefaultTabController(
      length: isAdmin ? 3 : 1,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Admin Manage',
            style: TextStyle(
              color: Color(0xFF1d4ed8),
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1d4ed8)),
          bottom: isAdmin
              ? const TabBar(
                  labelColor: Color(0xFF1d4ed8),
                  unselectedLabelColor: Color(0xFF6b7280),
                  indicatorColor: Color(0xFF1d4ed8),
                  tabs: [
                    Tab(text: 'Pertandingan', icon: Icon(Icons.event)),
                    Tab(text: 'Tim', icon: Icon(Icons.groups)),
                    Tab(text: 'Venue', icon: Icon(Icons.stadium)),
                  ],
                )
              : null,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFf6f9ff), Color(0xFFe8f0ff), Color(0xFFdce6ff)],
            ),
          ),
          child: isAdmin
              ? const TabBarView(
                  children: [
                    _MatchesSection(),
                    _TeamsSection(),
                    _VenuesSection(),
                  ],
                )
              : _LockedContent(),
        ),
        bottomNavigationBar: const AppBottomNav(currentRoute: '/manage'),
      ),
    );
  }
}

class _LockedContent extends StatelessWidget {
  const _LockedContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Khusus admin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Silakan login dengan akun admin untuk membuka menu Manage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6b7280)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Ke Halaman Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamsSection extends StatefulWidget {
  const _TeamsSection();

  @override
  State<_TeamsSection> createState() => _TeamsSectionState();
}

class _TeamsSectionState extends State<_TeamsSection> {
  late final AdminApiService _service;
  bool _loading = true;
  List<AdminTeam> _teams = [];

  @override
  void initState() {
    super.initState();
    _service = AdminApiService(context.read<CookieRequest>());
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchTeams();
      if (!mounted) return;
      setState(() => _teams = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat tim: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTeamForm({AdminTeam? team}) async {
    final nameController = TextEditingController(text: team?.name ?? '');
    String league = team?.league ?? 'liga_1';
    final logoController = TextEditingController(text: team?.logoUrl ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setStateSB) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    team == null ? 'Tambah Tim' : 'Edit Tim',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tim',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: league,
                    decoration: const InputDecoration(
                      labelText: 'Liga',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'liga_1',
                        child: Text('Liga 1'),
                      ),
                      DropdownMenuItem(
                        value: 'liga_2',
                        child: Text('Liga 2'),
                      ),
                      DropdownMenuItem(
                        value: 'n/a',
                        child: Text('Tidak diketahui'),
                      ),
                    ],
                    onChanged: (val) => setStateSB(() => league = val ?? 'liga_1'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: logoController,
                    decoration: const InputDecoration(
                      labelText: 'Logo URL (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(team == null ? 'Tambah' : 'Simpan'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != true) return;

    try {
      if (team == null) {
        await _service.createTeam(
          name: nameController.text.trim(),
          league: league,
          logoUrl: logoController.text.trim().isEmpty
              ? null
              : logoController.text.trim(),
        );
      } else {
        await _service.updateTeam(AdminTeam(
          id: team.id,
          name: nameController.text.trim(),
          league: league,
          logoUrl: logoController.text.trim(),
        ));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(team == null ? 'Tim ditambahkan' : 'Tim diperbarui'),
        ),
      );
      _loadTeams();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tim: $e')),
      );
    }
  }

  Future<void> _deleteTeam(AdminTeam team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tim'),
        content: Text('Yakin menghapus ${team.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.deleteTeam(team.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tim ${team.name} dihapus')),
      );
      _loadTeams();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus tim: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadTeams,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  title: 'Daftar Tim',
                  subtitle: 'Kelola tim dan logo.',
                  actionLabel: 'Tambah Tim',
                  onAction: () => _openTeamForm(),
                ),
                const SizedBox(height: 12),
                if (_teams.isEmpty)
                  const Center(child: Text('Belum ada tim.'))
                else
                  ..._teams.map((t) => _TeamCard(
                        team: t,
                        onEdit: () => _openTeamForm(team: t),
                        onDelete: () => _deleteTeam(t),
                      )),
              ],
            ),
    );
  }
}

class _VenuesSection extends StatefulWidget {
  const _VenuesSection();

  @override
  State<_VenuesSection> createState() => _VenuesSectionState();
}

class _VenuesSectionState extends State<_VenuesSection> {
  late final AdminApiService _service;
  bool _loading = true;
  List<AdminVenue> _venues = [];

  @override
  void initState() {
    super.initState();
    _service = AdminApiService(context.read<CookieRequest>());
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchVenues();
      if (!mounted) return;
      setState(() => _venues = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat venue: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openVenueForm({AdminVenue? venue}) async {
    final nameController = TextEditingController(text: venue?.name ?? '');
    final cityController = TextEditingController(text: venue?.city ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                venue == null ? 'Tambah Venue' : 'Edit Venue',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Venue',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Kota',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(venue == null ? 'Tambah' : 'Simpan'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;

    try {
      if (venue == null) {
        await _service.createVenue(
          name: nameController.text.trim(),
          city: cityController.text.trim(),
        );
      } else {
        await _service.updateVenue(AdminVenue(
          id: venue.id,
          name: nameController.text.trim(),
          city: cityController.text.trim(),
        ));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(venue == null ? 'Venue ditambahkan' : 'Venue diperbarui')),
      );
      _loadVenues();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan venue: $e')),
      );
    }
  }

  Future<void> _deleteVenue(AdminVenue venue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Venue'),
        content: Text('Yakin menghapus ${venue.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.deleteVenue(venue.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venue ${venue.name} dihapus')),
      );
      _loadVenues();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus venue: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadVenues,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  title: 'Daftar Venue',
                  subtitle: 'Kelola stadion atau lokasi pertandingan.',
                  actionLabel: 'Tambah Venue',
                  onAction: () => _openVenueForm(),
                ),
                const SizedBox(height: 12),
                if (_venues.isEmpty)
                  const Center(child: Text('Belum ada venue.'))
                else
                  ..._venues.map(
                    (v) => _VenueCard(
                      venue: v,
                      onEdit: () => _openVenueForm(venue: v),
                      onDelete: () => _deleteVenue(v),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MatchesSection extends StatefulWidget {
  const _MatchesSection();

  @override
  State<_MatchesSection> createState() => _MatchesSectionState();
}

class _MatchesSectionState extends State<_MatchesSection> {
  late final AdminApiService _service;
  bool _loading = true;
  List<AdminMatch> _matches = [];
  List<AdminTeam> _teams = [];
  List<AdminVenue> _venues = [];

  @override
  void initState() {
    super.initState();
    _service = AdminApiService(context.read<CookieRequest>());
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchMatches(),
        _service.fetchTeams(),
        _service.fetchVenues(),
      ]);
      if (!mounted) return;
      setState(() {
        _matches = results[0] as List<AdminMatch>;
        _teams = results[1] as List<AdminTeam>;
        _venues = results[2] as List<AdminVenue>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMatchForm({AdminMatch? match}) async {
    if (_teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal butuh dua tim untuk membuat pertandingan')),
      );
      return;
    }
    String? homeTeamId =
        match?.homeTeamId ?? (_teams.isNotEmpty ? _teams.first.id : null);
    String? awayTeamId = match?.awayTeamId ??
        (_teams.length > 1 ? _teams[1].id : (_teams.isNotEmpty ? _teams.first.id : null));
    String? venueId = match?.venueId ?? (_venues.isNotEmpty ? _venues.first.id : null);
    DateTime date = match?.date ?? DateTime.now().add(const Duration(days: 1));
    int? homeGoals = match?.homeGoals;
    int? awayGoals = match?.awayGoals;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setStateSB) {
              Future<void> pickDate() async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                );
                if (pickedDate == null) return;
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(date),
                );
                setStateSB(() {
                  date = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime?.hour ?? date.hour,
                    pickedTime?.minute ?? date.minute,
                  );
                });
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      match == null ? 'Tambah Pertandingan' : 'Edit Pertandingan',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: homeTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Home Team',
                        border: OutlineInputBorder(),
                      ),
                      items: _teams
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ))
                          .toList(),
                      onChanged: (val) => setStateSB(() => homeTeamId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: awayTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Away Team',
                        border: OutlineInputBorder(),
                      ),
                      items: _teams
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ))
                          .toList(),
                      onChanged: (val) => setStateSB(() => awayTeamId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: venueId,
                      decoration: const InputDecoration(
                        labelText: 'Venue',
                        border: OutlineInputBorder(),
                      ),
                      items: _venues
                          .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text('${v.name}${v.city != null ? " - ${v.city}" : ""}'),
                              ))
                          .toList(),
                      onChanged: (val) => setStateSB(() => venueId = val),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tanggal & waktu'),
                      subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date)),
                      trailing: IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: pickDate,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Skor Home (opsional)',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: homeGoals?.toString() ?? '',
                            ),
                            onChanged: (val) => homeGoals = int.tryParse(val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Skor Away (opsional)',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: awayGoals?.toString() ?? '',
                            ),
                            onChanged: (val) => awayGoals = int.tryParse(val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(match == null ? 'Tambah' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result != true || homeTeamId == null || awayTeamId == null) return;

    try {
      if (homeTeamId == null || awayTeamId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tim home dan away terlebih dahulu')),
        );
        return;
      }

      if (match == null) {
        await _service.createMatch(
          homeTeamId: homeTeamId!,
          awayTeamId: awayTeamId!,
          venueId: venueId,
          date: date,
          homeGoals: homeGoals,
          awayGoals: awayGoals,
        );
      } else {
        await _service.updateMatch(AdminMatch(
          id: match.id,
          homeTeamId: homeTeamId!,
          awayTeamId: awayTeamId!,
          homeTeamName: match.homeTeamName,
          awayTeamName: match.awayTeamName,
          venueName: match.venueName,
          venueId: venueId,
          date: date,
          statusShort: match.statusShort,
          statusLong: match.statusLong,
          homeGoals: homeGoals,
          awayGoals: awayGoals,
        ));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(match == null ? 'Pertandingan ditambahkan' : 'Pertandingan diperbarui')),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pertandingan: $e')),
      );
    }
  }

  Future<void> _deleteMatch(AdminMatch match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pertandingan'),
        content: Text('Yakin menghapus ${match.homeTeamName} vs ${match.awayTeamName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.deleteMatch(match.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pertandingan dihapus')),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus pertandingan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  title: 'Pertandingan',
                  subtitle: 'Kelola jadwal dan skor pertandingan.',
                  actionLabel: 'Tambah Pertandingan',
                  onAction: _teams.length < 2 ? null : () => _openMatchForm(),
                ),
                const SizedBox(height: 12),
                if (_matches.isEmpty)
                  const Center(child: Text('Belum ada pertandingan.'))
                else
                  ..._matches.map(
                    (m) => _MatchCard(
                      match: m,
                      onEdit: () => _openMatchForm(match: m),
                      onDelete: () => _deleteMatch(m),
                      teams: _teams,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF6b7280)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563eb),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminTeam team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _CircleLogo(
          url: team.logoProxyUrl ?? team.logoUrl,
          fallbackUrl: team.logoUrl,
        ),
        title: Text(team.name),
        subtitle: Text(team.league.toUpperCase()),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminVenue venue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.location_city, color: Colors.indigo),
        title: Text(venue.name),
        subtitle: Text(venue.city?.isNotEmpty == true ? venue.city! : 'Kota tidak diisi'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.onEdit,
    required this.onDelete,
    required this.teams,
  });

  final AdminMatch match;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<AdminTeam> teams;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM yyyy • HH:mm').format(match.date);

    AdminTeam? teamFor(String id) {
      final idx = teams.indexWhere((t) => t.id == id);
      if (idx == -1) return null;
      return teams[idx];
    }

    Widget teamColumn(String name, AdminTeam? teamData) {
      final logo = teamData?.logoProxyUrl ?? teamData?.logoUrl;
      final fallback = teamData?.logoUrl;
      return Column(
        children: [
          _CircleLogo(
            url: logo,
            fallbackUrl: fallback,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 110,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(color: Color(0xFF6b7280)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.indigo),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
            children: [
              Expanded(
                  child: teamColumn(match.homeTeamName, teamFor(match.homeTeamId)),
                ),
                const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: teamColumn(match.awayTeamName, teamFor(match.awayTeamId)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              match.venueName.isNotEmpty ? match.venueName : 'Venue TBD',
              style: const TextStyle(color: Color(0xFF1f2937)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleLogo extends StatelessWidget {
  const _CircleLogo({required this.url, this.fallbackUrl});

  final String? url;
  final String? fallbackUrl;

  @override
  Widget build(BuildContext context) {
    final candidate = (url ?? '').isNotEmpty ? url : (fallbackUrl ?? '');
    final resolved = (candidate ?? '').isEmpty ? null : ApiConfig.resolveUrl(candidate!);

    if (resolved == null) {
      return const CircleAvatar(
        backgroundColor: Color(0xFF2563eb),
        child: Icon(Icons.shield, color: Colors.white),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.network(
          resolved,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Color(0xFF2563eb)),
        ),
      ),
    );
  }
}
