import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ligapass/common/widgets/app_bottom_nav.dart';
import 'package:ligapass/matches/models/match.dart';
import 'package:ligapass/bookings/screens/ticket_price_screen.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Banner carousel
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Banner data
  final List<Map<String, dynamic>> _banners = [
    {
      'image': 'assets/banners/banner1.jpeg',
      'title': 'Rasakan Setiap Pertandingan Secara Langsung',
      'description': 'Lihat jadwal, tim, dan amankan tiket Anda sekarang!',
      'ctaText': 'Beli Tiket',
      'ctaRoute': '/matches',
    },
    {
      'image': 'assets/banners/banner2.jpeg',
      'title': 'Akses Eksklusif Liga Utama',
      'description': 'Dapatkan tiket untuk pertandingan paling ditunggu!',
      'ctaText': 'Lihat Tiket',
      'ctaRoute': '/matches',
    },
    {
      'image': 'assets/banners/banner3.jpeg',
      'title': 'Berita Sepak Bola Terkini',
      'description':
          'Ikuti kabar terbaru dan analisis mendalam tentang sepak bola.',
      'ctaText': 'Baca Berita',
      'ctaRoute': '/news',
    },
  ];

  // News data
  List<Map<String, dynamic>> _latestNews = [];
  bool _isLoadingNews = false;

  // Teams data for slider
  List<Map<String, dynamic>> _teams = [];
  final ScrollController _teamScrollController = ScrollController();
  Timer? _teamScrollTimer;

  // Upcoming matches - load directly
  List<Match> _upcomingMatches = [];
  bool _isLoadingMatches = false;

  @override
  void initState() {
    super.initState();
    _startBannerAutoSlide();
    _loadLatestNews();
    _loadTeams();
    _loadUpcomingMatches();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _teamScrollTimer?.cancel();
    _teamScrollController.dispose();
    super.dispose();
  }

  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextIndex = (_currentBannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadLatestNews() async {
    setState(() => _isLoadingNews = true);
    try {
      final url = '${ApiConfig.baseUrl}/news/api/news/?page=1&per_page=5';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          // Response bisa langsung array atau object dengan key
          List<dynamic> newsList;
          if (data is List) {
            newsList = data;
          } else {
            newsList = data['news'] ?? data['results'] ?? data['data'] ?? [];
          }
          setState(() {
            _latestNews = List<Map<String, dynamic>>.from(newsList);
            _isLoadingNews = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingNews = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _loadUpcomingMatches() async {
    setState(() => _isLoadingMatches = true);
    try {
      // Use the calendar API with status filter
      final url =
          '${ApiConfig.baseUrl}/matches/api/calendar/?page=1&per_page=10&status=Upcoming';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          List<dynamic> matchesList;
          if (data is List) {
            matchesList = data;
          } else {
            matchesList =
                data['matches'] ?? data['results'] ?? data['data'] ?? [];
          }

          // Parse matches - API already filters upcoming
          final matches = matchesList
              .map((m) => Match.fromJson(m as Map<String, dynamic>))
              .take(5)
              .toList();

          setState(() {
            _upcomingMatches = matches;
            _isLoadingMatches = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingMatches = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  Future<void> _loadTeams() async {
    try {
      // Use the flutter team logos endpoint that exists
      final url = '${ApiConfig.baseUrl}/matches/api/flutter/team-logos/';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          // Response bisa langsung array atau object dengan key
          List<dynamic> teamsList;
          if (data is List) {
            teamsList = data;
          } else {
            teamsList = data['teams'] ?? data['results'] ?? data['data'] ?? [];
          }
          setState(() {
            _teams = List<Map<String, dynamic>>.from(teamsList);
          });
          _startTeamAutoScroll();
        }
      }
    } catch (e) {
    }
  }

  void _startTeamAutoScroll() {
    if (_teams.isEmpty) return;
    _teamScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (_teamScrollController.hasClients) {
        final maxScroll = _teamScrollController.position.maxScrollExtent;
        final currentScroll = _teamScrollController.offset;
        if (currentScroll >= maxScroll) {
          _teamScrollController.jumpTo(0);
        } else {
          _teamScrollController.jumpTo(currentScroll + 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LigaPass',
          style: TextStyle(
            color: Color(0xFF1d4ed8),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf6f9ff), Color(0xFFe8f0ff), Color(0xFFdce6ff)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadUpcomingMatches();
            await _loadLatestNews();
            await _loadTeams();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner Carousel
                _buildHeroBanner(),

                // Pertandingan Mendatang Section
                _buildUpcomingMatchesSection(),

                // Tim Liga 1 Section
                if (_teams.isNotEmpty) _buildTeamsSection(),

                // Berita Terbaru Section
                _buildNewsSection(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(
        currentRoute: '/home',
        showAssistantButton: true,
      ),
    );
  }

  Widget _buildHeroBanner() {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.asset(
                    banner['image'],
                    fit: BoxFit.cover,
                    colorBlendMode: BlendMode.darken,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            banner['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            banner['description'],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, banner['ctaRoute']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            banner['ctaText'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Dot Indicators
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentBannerIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatchesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Pertandingan Mendatang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/matches'),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingMatches)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            )
          else if (_upcomingMatches.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Tidak ada pertandingan mendatang saat ini.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            Column(
              children: _upcomingMatches
                  .map((match) => _buildMatchCard(match))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    return GestureDetector(
      onTap: () {
        // Navigate to ticket price screen for booking
        final request = context.read<CookieRequest>();
        if (request.loggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketPriceScreen(
                matchId: match.id,
                homeTeam: match.homeTeamName,
                awayTeam: match.awayTeamName,
                homeTeamLogo: match.homeLogoUrl,
                awayTeamLogo: match.awayLogoUrl,
                venue: match.venueName,
                matchDate: match.kickoff?.toIso8601String(),
                matchStatus: match.status.name,
                homeScore: match.homeGoals,
                awayScore: match.awayGoals,
              ),
            ),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Home Team
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      match.homeTeamName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildTeamLogo(match.homeLogoUrl, size: 32),
                ],
              ),
            ),
            // VS & Date
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMatchDate(match.kickoff),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Away Team
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTeamLogo(match.awayLogoUrl, size: 32),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      match.awayTeamName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl, {double size = 40}) {
    return SizedBox(
      width: size,
      height: size,
      child: logoUrl != null && logoUrl.isNotEmpty
          ? Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.sports_soccer, color: Color(0xFF9CA3AF)),
            )
          : const Icon(Icons.sports_soccer, color: Color(0xFF9CA3AF)),
    );
  }

  String _formatMatchDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year\n$hour:$minute';
  }

  Widget _buildTeamsSection() {
    // Duplicate teams for infinite scroll effect
    final displayTeams = [..._teams, ..._teams];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Text(
            'Tim Liga 1',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.1, 0.9, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                controller: _teamScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: displayTeams.length,
                itemBuilder: (context, index) {
                  final team = displayTeams[index];
                  final logoUrl =
                      team['logo_url'] ?? team['display_logo_url'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTeamLogoItem(logoUrl),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogoItem(String logoUrl) {
    String resolvedUrl = logoUrl;
    if (logoUrl.isNotEmpty && !logoUrl.startsWith('http')) {
      resolvedUrl = ApiConfig.resolveUrl(logoUrl);
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: resolvedUrl.isNotEmpty
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.sports_soccer, color: Color(0xFF9CA3AF)),
            )
          : const Icon(Icons.sports_soccer, color: Color(0xFF9CA3AF)),
    );
  }

  Widget _buildNewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Berita Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/news'),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingNews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            )
          else if (_latestNews.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Tidak ada berita saat ini.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            Column(
              children: _latestNews
                  .map((news) => _buildNewsCard(news))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    // Django response uses 'thumbnail' field
    final imageUrl =
        news['thumbnail'] ?? news['image_url'] ?? news['image'] ?? '';
    final title = news['title'] ?? '';
    final category = news['category'] ?? 'Berita';

    String resolvedImageUrl = imageUrl;
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      resolvedImageUrl = ApiConfig.resolveUrl(imageUrl);
    }

    return GestureDetector(
      onTap: () {
        // Navigate to news detail if needed
        Navigator.pushNamed(context, '/news');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: resolvedImageUrl.isNotEmpty
                    ? Image.network(
                        resolvedImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(
                            Icons.newspaper,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFE5E7EB),
                        child: const Icon(
                          Icons.newspaper,
                          color: Color(0xFF9CA3AF),
                          size: 32,
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category.toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
