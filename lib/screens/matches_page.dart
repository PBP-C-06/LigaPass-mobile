import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../models/match_filter.dart';
import '../state/matches_notifier.dart';
import '../widgets/match_card.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late TextEditingController _searchController;
  DateTime? _startDate;
  DateTime? _endDate;
  Set<MatchStatus> _selectedStatuses = const {
    MatchStatus.upcoming,
    MatchStatus.ongoing,
    MatchStatus.finished,
  };
  int _perPage = 10;

  @override
  void initState() {
    super.initState();
    final filter = context.read<MatchesNotifier>().filter;
    _searchController = TextEditingController(text: filter.query);
    _startDate = filter.dateStart;
    _endDate = filter.dateEnd;
    _selectedStatuses = filter.statuses;
    _perPage = filter.perPage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _applyFilters() async {
    final notifier = context.read<MatchesNotifier>();
    notifier
      ..updateQuery(_searchController.text)
      ..updatePerPage(_perPage)
      ..updateStatuses(_selectedStatuses)
      ..updateDateRange(start: _startDate, end: _endDate);

    await notifier.loadMatches(resetPage: true);
  }

  Future<void> _resetFilters() async {
    setState(() {
      _searchController.text = '';
      _startDate = null;
      _endDate = null;
      _selectedStatuses = const {
        MatchStatus.upcoming,
        MatchStatus.ongoing,
        MatchStatus.finished,
      };
      _perPage = 10;
    });
    await context.read<MatchesNotifier>().resetFilters();
  }

  String _formatDate(DateTime? date) =>
      date != null ? DateFormat('dd MMM yyyy').format(date) : 'Pilih tanggal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LigaPass Matches',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<MatchesNotifier>().loadMatches(),
        child: Consumer<MatchesNotifier>(
          builder: (context, state, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FilterCard(
                  searchController: _searchController,
                  startDateText: _formatDate(_startDate),
                  endDateText: _formatDate(_endDate),
                  onPickStart: () => _pickDate(isStart: true),
                  onPickEnd: () => _pickDate(isStart: false),
                  statuses: _selectedStatuses,
                  onToggleStatus: (status, isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selectedStatuses = {..._selectedStatuses, status};
                      } else {
                        _selectedStatuses = {..._selectedStatuses}..remove(status);
                        if (_selectedStatuses.isEmpty) {
                          _selectedStatuses = const {MatchStatus.upcoming};
                        }
                      }
                    });
                  },
                  perPage: _perPage,
                  onPerPageChanged: (value) {
                    if (value != null) {
                      setState(() => _perPage = value);
                    }
                  },
                  onApply: _applyFilters,
                  onReset: _resetFilters,
                  isLoading: state.isLoading,
                ),
                const SizedBox(height: 12),
                if (state.error != null)
                  _ErrorBanner(
                    message: state.error!,
                    onRetry: () => state.loadMatches(resetPage: true),
                  )
                else if (state.isLoading && state.matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Tidak ada pertandingan sesuai filter.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  ...[
                    ...state.matches.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(
                          match: match,
                          onTap: () => Navigator.of(context).pushNamed(
                            '/match',
                            arguments: match,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PaginationControls(
                      pagination: state.pagination,
                      onPrevious: state.pagination?.hasPrevious == true
                          ? () => state.goToPage((state.pagination!.currentPage - 1))
                          : null,
                      onNext: state.pagination?.hasNext == true
                          ? () => state.goToPage((state.pagination!.currentPage + 1))
                          : null,
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.searchController,
    required this.startDateText,
    required this.endDateText,
    required this.onPickStart,
    required this.onPickEnd,
    required this.statuses,
    required this.onToggleStatus,
    required this.perPage,
    required this.onPerPageChanged,
    required this.onApply,
    required this.onReset,
    required this.isLoading,
  });

  final TextEditingController searchController;
  final String startDateText;
  final String endDateText;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final Set<MatchStatus> statuses;
  final void Function(MatchStatus status, bool isSelected) onToggleStatus;
  final int perPage;
  final ValueChanged<int?> onPerPageChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Cari tim',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => onApply(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _statusChip('Upcoming', MatchStatus.upcoming, statuses.contains(MatchStatus.upcoming)),
                _statusChip('Ongoing', MatchStatus.ongoing, statuses.contains(MatchStatus.ongoing)),
                _statusChip('Finished', MatchStatus.finished, statuses.contains(MatchStatus.finished)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickStart,
                    icon: const Icon(Icons.date_range),
                    label: Text(startDateText),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickEnd,
                    icon: const Icon(Icons.event),
                    label: Text(endDateText),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int>(
                    value: perPage,
                    decoration: InputDecoration(
                      labelText: 'Entri per halaman',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: MatchFilter.allowedPerPage
                        .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                        .toList(),
                    onChanged: onPerPageChanged,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onApply,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Terapkan'),
                ),
                TextButton(
                  onPressed: isLoading ? null : onReset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, MatchStatus status, bool selected) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (value) => onToggleStatus(status, value),
      selectedColor: Colors.indigo.shade50,
      checkmarkColor: Colors.indigo,
      side: BorderSide(color: selected ? Colors.indigo : Colors.grey.shade300),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  final MatchPagination? pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (pagination == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Prev'),
          ),
          const SizedBox(width: 12),
          Text(
            'Halaman ${pagination!.currentPage} / ${pagination!.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
