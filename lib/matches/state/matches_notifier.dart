import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../models/match_filter.dart';
import '../repositories/matches_repository.dart';

class MatchesNotifier extends ChangeNotifier {
  MatchesNotifier(this.repository);

  final MatchesRepository repository;

  MatchFilter _filter = const MatchFilter();
  List<Match> _matches = [];
  MatchPagination? _pagination;
  bool _isLoading = false;
  String? _error;

  List<Match> get matches => _matches;
  MatchPagination? get pagination => _pagination;
  MatchFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMatches({MatchFilter? filter, bool resetPage = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final nextFilter =
        filter ?? _filter.copyWith(resetPage: resetPage, page: resetPage ? 1 : null);

    try {
      final response = await repository.fetchMatches(nextFilter);
      _matches = response.matches;
      _pagination = response.pagination;
      _filter = nextFilter.copyWith(page: response.pagination.currentPage);
    } catch (err) {
      _error = err.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateQuery(String value) {
    _filter = _filter.copyWith(query: value, resetPage: true);
  }

  void updatePerPage(int perPage) {
    final sanitizedPerPage = MatchFilter.allowedPerPage.contains(perPage) ? perPage : 10;
    _filter = _filter.copyWith(perPage: sanitizedPerPage, resetPage: true);
  }

  void updateStatuses(Set<MatchStatus> statuses) {
    _filter = _filter.copyWith(statuses: statuses, resetPage: true);
  }

  void updateDateRange({DateTime? start, DateTime? end}) {
    _filter = _filter.copyWith(
      dateStart: start,
      dateEnd: end,
      resetPage: true,
    );
  }

  Future<void> resetFilters() async {
    _filter = const MatchFilter();
    await loadMatches();
  }

  Future<void> goToPage(int page) async {
    if (_pagination == null) return;
    final clampedPage = page.clamp(1, _pagination!.totalPages);
    _filter = _filter.copyWith(page: clampedPage);
    await loadMatches();
  }
}
