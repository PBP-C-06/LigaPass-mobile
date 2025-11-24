import 'package:intl/intl.dart';

import 'match.dart';

class MatchFilter {
  final String query;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final Set<MatchStatus> statuses;
  final int perPage;
  final int page;

  static const allowedPerPage = [5, 10, 25, 50];

  const MatchFilter({
    this.query = '',
    this.dateStart,
    this.dateEnd,
    this.statuses = const {MatchStatus.upcoming, MatchStatus.ongoing, MatchStatus.finished},
    this.perPage = 10,
    this.page = 1,
  });

  MatchFilter copyWith({
    String? query,
    DateTime? dateStart,
    DateTime? dateEnd,
    Set<MatchStatus>? statuses,
    int? perPage,
    int? page,
    bool resetPage = false,
  }) {
    return MatchFilter(
      query: query ?? this.query,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      statuses: statuses ?? this.statuses,
      perPage: perPage ?? this.perPage,
      page: resetPage ? 1 : (page ?? this.page),
    );
  }

  Map<String, String> toQueryParameters() {
    final formatter = DateFormat('yyyy-MM-dd');
    final params = <String, String>{
      'page': page.toString(),
      'per_page': allowedPerPage.contains(perPage) ? perPage.toString() : '10',
    };

    if (query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }

    if (dateStart != null) {
      params['date_start'] = formatter.format(dateStart!);
    }

    if (dateEnd != null) {
      params['date_end'] = formatter.format(dateEnd!);
    }

    if (statuses.isNotEmpty && statuses.length < 3) {
      params['status'] = statuses.map((status) => switch (status) {
            MatchStatus.upcoming => 'Upcoming',
            MatchStatus.ongoing => 'Ongoing',
            MatchStatus.finished => 'Finished',
            MatchStatus.unknown => '',
          }).where((value) => value.isNotEmpty).join(',');
    }

    return params;
  }
}
