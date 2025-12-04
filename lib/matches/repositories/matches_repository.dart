import '../models/match.dart';
import '../models/match_filter.dart';
import '../services/matches_api_client.dart';

class MatchesRepository {
  MatchesRepository({required this.apiClient});

  final MatchesApiClient apiClient;

  Future<MatchResponse> fetchMatches(MatchFilter filter) {
    return apiClient.fetchMatches(filter: filter);
  }
}
