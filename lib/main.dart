import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FORCE RECOMPILE - v8.0
// ─────────────────────────────────────────────────────────────────────────────
// APP LOGO HELPER
// ─────────────────────────────────────────────────────────────────────────────

class AppLogo {
  static const String _sqPath = 'assets/images/app_logo_sq.png';
  static const String _iconPath = 'assets/images/app_icon.png';

  static Widget build({double? width, double? height, BoxFit fit = BoxFit.contain}) {
    return Image.asset(
      _sqPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width ?? 80,
        height: height ?? 80,
        decoration: BoxDecoration(
          gradient: AppTheme.mainGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.live_tv, color: Colors.white, size: 36),
      ),
    );
  }

  static Widget icon({double size = 60}) {
    return Image.asset(
      _iconPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppTheme.mainGradient,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.live_tv, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. STORAGE SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Favorites ──
  static List<String> getFavorites() {
    return _prefs?.getStringList('favorites') ?? [];
  }

  static Future<bool> toggleFavorite(String channelName) async {
    final favs = getFavorites();
    if (favs.contains(channelName)) {
      favs.remove(channelName);
    } else {
      favs.add(channelName);
    }
    return _prefs!.setStringList('favorites', favs);
  }

  static Future<bool> clearFavorites() async {
    return _prefs!.remove('favorites');
  }

  // ── Recently Watched ──
  static List<String> getRecentlyWatched() {
    return _prefs?.getStringList('recentlyWatched') ?? [];
  }

  static Future<bool> addRecentlyWatched(String channelName) async {
    final recent = getRecentlyWatched();
    recent.remove(channelName);
    recent.insert(0, channelName);
    if (recent.length > 50) recent.removeRange(50, recent.length);
    return _prefs!.setStringList('recentlyWatched', recent);
  }

  static Future<bool> clearHistory() async {
    return _prefs!.remove('recentlyWatched');
  }

  // ── Onboarding ──
  static bool isOnboardingDone() {
    return _prefs?.getBool('onboardingDone') ?? false;
  }

  static Future<bool> setOnboardingDone() async {
    return _prefs!.setBool('onboardingDone', true);
  }

  // ── Aspect Ratio ──
  static String getAspectRatio() {
    return _prefs?.getString('aspect_ratio') ?? 'default';
  }

  static Future<void> setAspectRatio(String ratio) async {
    await _prefs!.setString('aspect_ratio', ratio);
  }

  // ── Data Saver Mode ──
  static bool getDataSaverMode() => _prefs?.getBool('dataSaverMode') ?? false;
  static Future<void> setDataSaverMode(bool val) async => await _prefs!.setBool('dataSaverMode', val);

  // ── Night Mode (Blue Light Filter) ──
  static bool getNightMode() => _prefs?.getBool('nightMode') ?? false;
  static Future<void> setNightMode(bool val) async => await _prefs!.setBool('nightMode', val);

  // ── Remove Single History Item ──
  static Future<bool> removeRecentlyWatched(String channelName) async {
    final recent = getRecentlyWatched();
    recent.remove(channelName);
    return _prefs!.setStringList('recentlyWatched', recent);
  }

  // ── Clear All ──
  static Future<void> clearAllData() async {
    await _prefs!.clear();
  }

  // ── Admin Panel ──
  static bool isAdminLoggedIn() => _prefs?.getBool('adminLoggedIn') ?? false;
  static Future<void> setAdminLoggedIn(bool val) async => await _prefs!.setBool('adminLoggedIn', val);
  static String getAdminPassword() => _prefs?.getString('adminPassword') ?? 'REDACTED';
  static Future<void> setAdminPassword(String pass) async => await _prefs!.setString('adminPassword', pass);

  // ── Session Tracking ──
  static Future<void> logSession() async {
    final now = DateTime.now().toIso8601String();
    final sessions = _prefs?.getStringList('sessions') ?? [];
    sessions.insert(0, now);
    if (sessions.length > 200) sessions.removeRange(200, sessions.length);
    await _prefs!.setStringList('sessions', sessions);
  }

  static List<String> getSessions() => _prefs?.getStringList('sessions') ?? [];
  static int getSessionCount() => getSessions().length;

  // ── App Open Counter ──
  static int getAppOpenCount() => _prefs?.getInt('appOpenCount') ?? 0;
  static Future<void> incrementAppOpenCount() async {
    final count = getAppOpenCount() + 1;
    await _prefs!.setInt('appOpenCount', count);
  }

  // ── Channel View Tracking ──
  static Future<void> incrementChannelView(String channelName) async {
    final views = _prefs?.getString('channelViews') ?? '{}';
    final Map<String, dynamic> viewMap = jsonDecode(views);
    viewMap[channelName] = (viewMap[channelName] ?? 0) + 1;
    await _prefs!.setString('channelViews', jsonEncode(viewMap));
  }

  static Map<String, int> getChannelViews() {
    final views = _prefs?.getString('channelViews') ?? '{}';
    final Map<String, dynamic> viewMap = jsonDecode(views);
    return viewMap.map((k, v) => MapEntry(k, v as int));
  }

  static int getTotalChannelViews() {
    return getChannelViews().values.fold(0, (a, b) => a + b);
  }

  // ── Unique Devices (simulated) ──
  static Future<void> registerDevice(String deviceId, String info) async {
    final devices = _prefs?.getStringList('registeredDevices') ?? [];
    // Remove old entry for same device
    devices.removeWhere((d) => d.startsWith('$deviceId|'));
    devices.insert(0, '$deviceId|$info|${DateTime.now().toIso8601String()}');
    if (devices.length > 50) devices.removeRange(50, devices.length);
    await _prefs!.setStringList('registeredDevices', devices);
  }

  static List<Map<String, String>> getRegisteredDevices() {
    final devices = _prefs?.getStringList('registeredDevices') ?? [];
    return devices.map((d) {
      final parts = d.split('|');
      return {
        'id': parts.isNotEmpty ? parts[0] : 'unknown',
        'info': parts.length > 1 ? parts[1] : 'Unknown',
        'lastSeen': parts.length > 2 ? parts[2] : '',
      };
    }).toList();
  }

  // ── Device ID ──
  static String getDeviceId() {
    return _prefs?.getString('deviceId') ?? 'DEV_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
  }

  static Future<String> getOrCreateDeviceId() async {
    String id = _prefs?.getString('deviceId') ?? '';
    if (id.isEmpty) {
      id = 'ISH_${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      await _prefs!.setString('deviceId', id);
    }
    return id;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. EPG SERVICE (Electronic Program Guide - Simulated)
// ─────────────────────────────────────────────────────────────────────────────

class EPGData {
  final String currentProgram;
  final String nextProgram;
  final int progress; // 0-100
  final int minsRemaining;

  const EPGData({
    required this.currentProgram,
    required this.nextProgram,
    required this.progress,
    required this.minsRemaining,
  });
}

class EPGService {
  static const Map<String, Map<String, List<String>>> programSchedules = {
    'News': {
      'morning': ['Morning News', 'Breakfast Headlines', 'Sunrise Bulletin', 'Dawn Update'],
      'afternoon': ['Afternoon News', 'Midday Report', 'National Debate', 'Economy Today'],
      'evening': ['Evening News', 'Prime Time Debate', 'World Report', 'Crime Patrol'],
      'night': ['Night Bulletin', 'Late Night Live', 'Sports Wrap', 'Weather Update'],
    },
    'Entertainment': {
      'morning': ['Morning Show', 'Daily Soap', 'Family Drama', 'Cooking Show'],
      'afternoon': ['Reality Show', 'Game Show', 'Talk Show', 'Comedy Hour'],
      'evening': ['Prime Time Serial', 'Dance Reality', 'Singing Show', 'Drama Special'],
      'night': ['Late Night Show', 'Movie Preview', 'Celebrity Interview', 'Comedy Night'],
    },
    'Movies': {
      'morning': ['Classic Movie', 'Bollywood Hits', 'Retro Cinema', 'Action Morning'],
      'afternoon': ['Blockbuster Movie', 'Premiere Film', 'Thriller Hour', 'Romance Special'],
      'evening': ['New Release', 'Super Hit Film', 'Movie Marathon', 'Weekend Premiere'],
      'night': ['Late Night Movie', 'Horror Night', 'Action Unlimited', 'Director Cut'],
    },
    'Sports': {
      'morning': ['Sports Morning', 'Cricket Highlights', 'Match Preview', 'Fitness Show'],
      'afternoon': ['Live Match', 'Cricket Live', 'Football Highlights', 'Sports Debate'],
      'evening': ['Prime Sports', 'Live Cricket', 'Match Analysis', 'Sports Center'],
      'night': ['Sports Night', 'Match Replay', 'Wrestling', 'Boxing Night'],
    },
    'Kids': {
      'morning': ['Cartoon Time', 'Kids Show', 'Animated Series', 'Fun Learning'],
      'afternoon': ['Toon Marathon', 'Kids Movie', 'Adventure Time', 'Art & Craft'],
      'evening': ['Evening Toons', 'Super Hero Hour', 'Kids Reality', 'Story Time'],
      'night': ['Bedtime Stories', 'Gentle Cartoons', 'Lullaby Songs', 'Night Tales'],
    },
    'Music': {
      'morning': ['Morning Vibes', 'Bollywood Hits', 'Retro Music', 'Devotional Songs'],
      'afternoon': ['Pop Charts', 'Lunchtime Music', 'Top 10 Countdown', 'Remix Hour'],
      'evening': ['Music Night', 'Live Concert', 'Video Jukebox', 'DJ Mix'],
      'night': ['Late Night Music', 'Romantic Hits', 'Sufi Night', 'Unplugged'],
    },
    'Regional': {
      'morning': ['Regional News', 'Local Shows', 'Cultural Program', 'Devotional'],
      'afternoon': ['Daily Serial', 'Reality Show', 'Cooking Show', 'Movie Time'],
      'evening': ['Prime Serial', 'Game Show', 'Talent Hunt', 'Drama Special'],
      'night': ['Late Night Show', 'Movie Preview', 'Comedy Show', 'Music Hour'],
    },
    'Devotional': {
      'morning': ['Morning Aarti', 'Bhajan Sandhya', 'Spiritual Discourse', 'Gita Recital'],
      'afternoon': ['Ramayan Katha', 'Bhakti Sangeet', 'Temple Live', 'Prayer Time'],
      'evening': ['Evening Aarti', 'Satsang Live', 'Mahabharat Katha', 'Hanuman Chalisa'],
      'night': ['Night Prayer', 'Meditation', 'Peaceful Bhajans', 'Shlok Recital'],
    },
  };

  static String _getTimeSlot() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  static List<String> _getProgramsForCategory(String category) {
    final slot = _getTimeSlot();
    final catPrograms = programSchedules[category] ?? programSchedules['Entertainment']!;
    return catPrograms[slot] ?? catPrograms['evening']!;
  }

  static EPGData getProgramForChannel(String channelName, String category) {
    final programs = _getProgramsForCategory(category);
    int hash = channelName.hashCode;
    int currentIdx = hash.abs() % programs.length;
    int nextIdx = (currentIdx + 1) % programs.length;
    final now = DateTime.now();
    int progress = ((now.minute * 60 + now.second) % 100);
    int minsRemaining = 30 - (now.minute % 30);
    if (minsRemaining == 30) minsRemaining = 0;

    return EPGData(
      currentProgram: programs[currentIdx],
      nextProgram: programs[nextIdx],
      progress: progress,
      minsRemaining: minsRemaining == 0 ? 30 : minsRemaining,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. FIREBASE SERVICE (Code-Ready - No actual Firebase imports)
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseService {
  // TODO: Setup Firebase for your project
  // 1. Go to https://console.firebase.google.com
  // 2. Create a new project "India Serial Hub"
  // 3. Add Android app (use your package name)
  // 4. Download google-services.json and put in android/app/
  // 5. Add these to pubspec.yaml:
  //    firebase_core: ^2.24.2
  //    firebase_database: ^10.4.0
  // 6. Uncomment the Firebase initialization in main()
  // 7. Set your database rules and add playlist_url in Realtime Database

  static const String _fallbackUrl = 'REDACTED';

  // Remote JSON endpoint for playlist URL (replace with your own)
  // You can use: Firebase Realtime DB, Firestore, or a simple JSON file hosting
  static const String _remoteConfigUrl = 'https://your-firebase-url.firebaseio.com/config.json';

  static Future<String> fetchPlaylistUrl() async {
    try {
      final response = await http.get(Uri.parse(_remoteConfigUrl)).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['playlist_url'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (e) {
      // Firebase not configured yet, use fallback
    }
    return _fallbackUrl;
  }

  static bool isConfigured() {
    return !_remoteConfigUrl.contains('your-firebase-url');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CATEGORY KEYWORDS & ICONS
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, List<String>> categoryKeywords = {
  'News': ['news', 'aaj tak', 'ndtv', 'abp', 'zee news', 'india tv', 'republic',
    'times now', 'tv9', 'news18', 'wion', 'cnbc', 'cnbc awaaz', 'et now'],
  'Entertainment': ['entertainment', 'star plus', 'zee tv', 'sony', 'colors',
    'sab tv', 'and tv', 'tv', 'serial', 'show', 'reality', 'comedy',
    'star utsav', 'zee anmol', 'sony pal', 'rishtey'],
  'Movies': ['movie', 'film', 'cinema', 'hbo', 'star gold', 'zee cinema',
    'sony max', 'movies now', 'utv', 'rox', 'box', 'pix', 'starmovies'],
  'Sports': ['sport', 'cricket', 'football', 'star sports', 'sony ten',
    'ten sports', 'espn', 'sports18', 'dd sports', 'neo sports', 'euro'],
  'Kids': ['kids', 'kid', 'cartoon', 'nick', 'pogo', 'disney', 'hungama',
    'chhota', 'motu', 'sonic', 'baby', 'tom and jerry'],
  'Music': ['music', 'mtv', 'channel v', '9xm', 'b4u', 'zindagi', 'song',
    'gaana', 'm-tv', 'mtv beats', '9x jalwa'],
  'Regional': ['regional', 'marathi', 'bengali', 'tamil', 'telugu', 'kannada',
    'malayalam', 'punjabi', 'gujarati', 'odia', 'assamese', 'sun tv',
    'vijay', 'gemini', 'etv', 'makkal', 'kalaignar', 'asianet', 'zee marathi'],
  'Devotional': ['devotional', 'spiritual', 'god', 'temple', 'bhakti',
    'aastha', 'sanskar', 'satsang', 'gita', 'ramayan', 'mahabharat',
    'hanuman', 'religious', 'prayer'],
};

const List<String> categoryOrder = [
  'All', 'Favorites', 'Recent', 'News', 'Entertainment', 'Movies',
  'Sports', 'Kids', 'Music', 'Regional', 'Devotional',
];

const Map<String, IconData> categoryIcons = {
  'All': Icons.grid_view,
  'Favorites': Icons.favorite,
  'Recent': Icons.history,
  'News': Icons.newspaper,
  'Entertainment': Icons.tv,
  'Movies': Icons.movie,
  'Sports': Icons.sports_cricket,
  'Kids': Icons.child_care,
  'Music': Icons.music_note,
  'Regional': Icons.language,
  'Devotional': Icons.temple_buddhist,
};

String detectCategory(String channelName) {
  final lower = channelName.toLowerCase();
  for (final entry in categoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (lower.contains(keyword)) return entry.key;
    }
  }
  return 'Entertainment';
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. APP THEME
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  static const Color primaryRed = Color(0xFFFF1744);
  static const Color neonRed = Color(0xFFFF5252);
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF14141F);
  static const Color cardBg = Color(0xFF1A1A2E);
  static const Color gradientStart = Color(0xFFD50000);
  static const Color gradientEnd = Color(0xFFFF1744);
  static const Color accentBlue = Color(0xFF448AFF);
  static const Color accentGold = Color(0xFFFFD740);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentCyan = Color(0xFF18FFFF);
  static const Color neonGreen = Color(0xFF69F0AE);
  static const Color accentGreen = Color(0xFF69F0AE);

  static LinearGradient get mainGradient =>
      const LinearGradient(colors: [gradientStart, gradientEnd]);
  static LinearGradient get cardGradient =>
      const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF222240)]);
  static LinearGradient get redGradient =>
      const LinearGradient(colors: [Color(0xFFC62828), Color(0xFFFF1744)]);
  static LinearGradient get neonGradient =>
      const LinearGradient(colors: [Color(0xFFFF1744), Color(0xFF7C4DFF)]);
  static LinearGradient get darkCardGradient =>
      const LinearGradient(colors: [Color(0xFF14141F), Color(0xFF1E1E35)]);

  static BoxDecoration glassCard({Color? tint}) {
    return BoxDecoration(
      color: (tint ?? cardBg).withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration neonBorder({Color? color, double radius = 16}) {
    final c = color ?? primaryRed;
    return BoxDecoration(
      color: surfaceDark,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: c.withOpacity(0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: c.withOpacity(0.15),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. CHANNEL MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ChannelModel {
  final String name;
  final String link;
  final String logo;
  final String group;

  const ChannelModel({
    required this.name,
    required this.link,
    required this.logo,
    required this.group,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. APP ENTRY SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await StorageService.init();
    if (!mounted) return;
    if (StorageService.isOnboardingDone()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: SpinKitFoldingCube(color: AppTheme.primaryRed, size: 50),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. INDIA SERIAL HUB (ROOT)
// ─────────────────────────────────────────────────────────────────────────────

class IndiaSerialHub extends StatelessWidget {
  const IndiaSerialHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'India Serial Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.darkBg,
        primaryColor: AppTheme.primaryRed,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.primaryRed,
          secondary: AppTheme.accentGold,
          surface: AppTheme.cardBg,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white.withOpacity(0.9)),
          titleTextStyle: GoogleFonts.bebasNeue(
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 1.5,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.primaryRed,
          unselectedItemColor: Colors.white.withOpacity(0.4),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        ),
        cardTheme: CardThemeData(
          color: AppTheme.cardBg,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AppEntryScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. ONBOARDING SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': 'logo',
      'title': 'Welcome to\nIndia Serial Hub',
      'subtitle': 'Your gateway to Live TV & Indian Entertainment',
      'color': AppTheme.primaryRed,
    },
    {
      'icon': Icons.favorite,
      'title': 'Double Tap to\nFavorite',
      'subtitle': 'Save your favorite channels for quick access anytime',
      'color': AppTheme.accentBlue,
    },
    {
      'icon': Icons.info_outline,
      'title': 'Long Press for\nChannel Info',
      'subtitle': 'Hold any channel card to see full details and options',
      'color': AppTheme.accentGold,
    },
    {
      'icon': Icons.play_circle_fill,
      'title': 'Enjoy!\nStart Watching',
      'subtitle': 'Hundreds of channels at your fingertips',
      'color': AppTheme.primaryRed,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await StorageService.setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              final isLogo = page['icon'] == 'logo';
              final pageColor = page['color'] as Color;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Icon / Logo container
                    Container(
                      width: isLogo ? 170 : 130,
                      height: isLogo ? 170 : 130,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLogo
                              ? [AppTheme.primaryRed.withOpacity(0.15), AppTheme.accentPurple.withOpacity(0.08)]
                              : [pageColor.withOpacity(0.15), pageColor.withOpacity(0.04)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLogo
                              ? AppTheme.primaryRed.withOpacity(0.25)
                              : pageColor.withOpacity(0.25),
                          width: isLogo ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isLogo
                                ? AppTheme.primaryRed.withOpacity(0.2)
                                : pageColor.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          if (isLogo)
                            BoxShadow(
                              color: AppTheme.accentPurple.withOpacity(0.08),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                        ],
                      ),
                      child: isLogo
                          ? ClipOval(child: AppLogo.icon(size: 130))
                          : Icon(page['icon'] as IconData, size: 56, color: pageColor),
                    ),
                    const SizedBox(height: 45),
                    Text(
                      page['title'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 34,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
            ),
          ),
          // Bottom section
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page indicators - creative pill style
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.primaryRed
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: _currentPage == index
                            ? [
                          BoxShadow(
                            color: AppTheme.primaryRed.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                // Next / Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.gradientStart,
                          AppTheme.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.play_arrow
                                  : Icons.arrow_forward_ios,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _textSlideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _textSlideAnim = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.4, 1.0, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _goHome();
  }

  Future<void> _goHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainBottomNavScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // ── Animated mesh gradient background ──
          Positioned.fill(
            child: AnimatedBuilder(animation: _controller, builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.5, 0.3),
                    radius: 1.2,
                    colors: [
                      AppTheme.primaryRed.withOpacity(0.08 * _glowAnim.value),
                      AppTheme.accentPurple.withOpacity(0.04 * _glowAnim.value),
                      AppTheme.darkBg,
                    ],
                  ),
                ),
              );
            }),
          ),

          // ── Diagonal neon lines ──
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomPaint(painter: _NeonLinesPainter()),
            ),
          ),

          // ── Floating neon particles ──
          ...List.generate(12, (i) {
            final positions = [
              (0.05, 0.08), (0.9, 0.12), (0.15, 0.85), (0.88, 0.8),
              (0.03, 0.45), (0.95, 0.5), (0.25, 0.03), (0.75, 0.95),
              (0.5, 0.02), (0.48, 0.97), (0.35, 0.9), (0.65, 0.08),
            ];
            final colors = [
              AppTheme.primaryRed, AppTheme.accentPurple, AppTheme.accentCyan,
              AppTheme.accentGold, AppTheme.neonRed, AppTheme.accentBlue,
            ];
            final sizes = [3.0, 4.0, 5.0, 2.5, 4.5, 3.5, 3.0, 5.0, 2.0, 4.0, 3.5, 5.5];
            final c = colors[i % colors.length];
            return Positioned(
              left: positions[i].$1 * 400,
              top: positions[i].$2 * 850,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Interval(i * 0.04, 0.5 + i * 0.02, curve: Curves.easeIn),
                ),
                child: Container(
                  width: sizes[i],
                  height: sizes[i],
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: c.withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── Main content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // ── Neon circle logo ──
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing ring
                        AnimatedBuilder(animation: _controller, builder: (_, __) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryRed.withOpacity(0.15 * _glowAnim.value),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryRed.withOpacity(0.3 * _glowAnim.value),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: AppTheme.accentPurple.withOpacity(0.15 * _glowAnim.value),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          );
                        }),
                        // Middle spinning ring effect
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentPurple.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        // Inner container with logo
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(child: AppLogo.icon(size: 130)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 45),

                // ── App name with neon glow ──
                SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                      .animate(_textSlideAnim),
                  child: FadeTransition(
                    opacity: _textSlideAnim,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF1744), Color(0xFFFF5252), Color(0xFF7C4DFF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            'INDIA SERIAL HUB',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 46,
                              color: Colors.white,
                              letterSpacing: 6,
                              shadows: [
                                Shadow(color: AppTheme.primaryRed.withOpacity(0.6), blurRadius: 30),
                                Shadow(color: AppTheme.accentPurple.withOpacity(0.3), blurRadius: 50),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 60,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: AppTheme.neonGradient,
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryRed.withOpacity(0.4), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'LIVE TV  \u2022  SERIALS  \u2022  ENTERTAINMENT',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4),
                            letterSpacing: 4,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 65),

                // ── Loading indicator ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      SpinKitPulse(color: AppTheme.primaryRed, size: 24),
                      const SizedBox(height: 14),
                      Text(
                        'Tuning channels...',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.25),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom neon diagonal lines painter ──
class _NeonLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppTheme.primaryRed.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final paint2 = Paint()
      ..color = AppTheme.accentPurple.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.5), paint1);
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.3), paint2);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.8, size.height), paint1);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.3, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 11. MAIN BOTTOM NAV SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MainBottomNavScreen extends StatefulWidget {
  const MainBottomNavScreen({super.key});

  @override
  State<MainBottomNavScreen> createState() => _MainBottomNavScreenState();
}

class _MainBottomNavScreenState extends State<MainBottomNavScreen> {
  int _currentIndex = 0;
  String _m3uUrl = 'REDACTED';
  bool _nightMode = false;
  bool _dataSaverMode = false;

  @override
  void initState() {
    super.initState();
    _nightMode = StorageService.getNightMode();
    _dataSaverMode = StorageService.getDataSaverMode();
    _trackAppOpen();
  }

  Future<void> _trackAppOpen() async {
    await StorageService.incrementAppOpenCount();
    await StorageService.logSession();
    final deviceId = await StorageService.getOrCreateDeviceId();
    await StorageService.registerDevice(deviceId, 'Flutter Device');
  }

  void _onNightModeChanged(bool val) {
    setState(() => _nightMode = val);
    StorageService.setNightMode(val);
  }

  void _onDataSaverChanged(bool val) {
    setState(() => _dataSaverMode = val);
    StorageService.setDataSaverMode(val);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Exit App',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Kya aap app band karna chahte hain?',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('No',
                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Yes',
                    style: GoogleFonts.poppins(color: AppTheme.primaryRed)),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                OTTAppHomePage(
                  initialUrl: _m3uUrl,
                  onM3uLoaded: (url) {
                    setState(() => _m3uUrl = url);
                  },
                  dataSaverMode: _dataSaverMode,
                ),
                AdminPanel(
                  m3uUrl: _m3uUrl,
                  onM3uLoaded: (url) {
                    setState(() => _m3uUrl = url);
                  },
                  nightMode: _nightMode,
                  dataSaverMode: _dataSaverMode,
                  onNightModeChanged: _onNightModeChanged,
                  onDataSaverChanged: _onDataSaverChanged,
                ),
              ],
            ),
            // ── Night Mode (Blue Light Filter) Overlay ──
            if (_nightMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.orange.withOpacity(0.15),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 30,
                spreadRadius: 3,
              ),
            ],
            border: Border(
              top: BorderSide(
                color: _currentIndex == 0
                    ? AppTheme.primaryRed.withOpacity(0.4)
                    : _currentIndex == 1
                    ? AppTheme.accentPurple.withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Glowing animated line at top of active tab ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  gradient: _currentIndex == 0
                      ? AppTheme.redGradient
                      : AppTheme.neonGradient,
                  boxShadow: _currentIndex == 0
                      ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                      : [BoxShadow(color: AppTheme.accentPurple.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)],
                ),
              ),
              BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: AppTheme.primaryRed,
                unselectedItemColor: Colors.white.withOpacity(0.3),
                selectedFontSize: 12,
                unselectedFontSize: 11,
                selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _currentIndex == 0
                            ? AppTheme.primaryRed.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: _currentIndex == 0
                            ? Border.all(color: AppTheme.primaryRed.withOpacity(0.25))
                            : null,
                        boxShadow: _currentIndex == 0
                            ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.1), blurRadius: 10)]
                            : null,
                      ),
                      child: Icon(
                        _currentIndex == 0 ? Icons.play_circle_filled : Icons.live_tv,
                        color: _currentIndex == 0
                            ? AppTheme.primaryRed
                            : Colors.white.withOpacity(0.3),
                        size: 24,
                      ),
                    ),
                    label: 'Live TV',
                  ),
                  BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _currentIndex == 1
                            ? AppTheme.accentPurple.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: _currentIndex == 1
                            ? Border.all(color: AppTheme.accentPurple.withOpacity(0.25))
                            : null,
                        boxShadow: _currentIndex == 1
                            ? [BoxShadow(color: AppTheme.accentPurple.withOpacity(0.08), blurRadius: 10)]
                            : null,
                      ),
                      child: Icon(Icons.settings,
                          color: _currentIndex == 1
                              ? AppTheme.accentPurple
                              : Colors.white.withOpacity(0.3)),
                    ),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12. OTT APP HOME PAGE
// ─────────────────────────────────────────────────────────────────────────────

class OTTAppHomePage extends StatefulWidget {
  final String initialUrl;
  final ValueChanged<String> onM3uLoaded;
  final bool dataSaverMode;

  const OTTAppHomePage({super.key, required this.initialUrl, required this.onM3uLoaded, this.dataSaverMode = false});

  @override
  State<OTTAppHomePage> createState() => _OTTAppHomePageState();
}

class _OTTAppHomePageState extends State<OTTAppHomePage>
    with SingleTickerProviderStateMixin {
  List<ChannelModel> _allChannels = [];
  List<ChannelModel> _filteredChannels = [];
  List<String> _favorites = [];
  List<String> _recentlyWatched = [];

  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Default';

  Timer? _debounce;
  String _m3uUrl = '';

  // ── Voice Search ──
  bool _isListening = false;
  static const MethodChannel _voiceChannel = MethodChannel('com.indiaserialhub/voice');

  bool get _dataSaverMode => widget.dataSaverMode;

  // ── Channel Icon Animation ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _favorites = StorageService.getFavorites();
    _recentlyWatched = StorageService.getRecentlyWatched();
    // Channel icon pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Auto-load channels with initial URL
    if (widget.initialUrl.isNotEmpty) {
      _loadChannels(widget.initialUrl);
    } else {
      setState(() => _isLoading = false);
    }
  }



  // ── Voice Search: Uses Android native speech recognition via MethodChannel ──
  void _startListening() async {
    setState(() => _isListening = true);
    try {
      final result = await _voiceChannel.invokeMethod<String>('startVoiceSearch');
      setState(() => _isListening = false);
      if (result != null && result.isNotEmpty) {
        setState(() => _searchQuery = result);
        _applyFilters();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: $result',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() => _isListening = false);
      // Fallback: Show voice search guidance dialog
      _showVoiceSearchGuide();
    } catch (e) {
      setState(() => _isListening = false);
      _showVoiceSearchGuide();
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    try {
      await _voiceChannel.invokeMethod('stopVoiceSearch');
    } catch (_) {}
  }

  void _showVoiceSearchGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.mic, color: AppTheme.primaryRed, size: 24),
            const SizedBox(width: 10),
            Text('Voice Search', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tap the mic icon to search channels by voice.',
                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            const SizedBox(height: 12),
            _voiceTip('How to use:', 'Say a channel name like "Aaj Tak" or "Star Sports"'),
            const SizedBox(height: 8),
            _voiceTip('Example:', '"Play Sony TV" / "Find News channels"'),
            const SizedBox(height: 8),
            _voiceTip('Tip:', 'Speak clearly for best results'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it', style: GoogleFonts.poppins(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _voiceTip(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(desc, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query);
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<ChannelModel> channels = List.from(_allChannels);

    // Category filter
    if (_selectedCategory == 'Favorites') {
      channels = channels.where((c) => _favorites.contains(c.name)).toList();
    } else if (_selectedCategory == 'Recent') {
      channels = channels.where((c) => _recentlyWatched.contains(c.name)).toList();
      // Sort recent by most recently watched
      channels.sort((a, b) {
        final aIdx = _recentlyWatched.indexOf(a.name);
        final bIdx = _recentlyWatched.indexOf(b.name);
        return aIdx.compareTo(bIdx);
      });
    } else if (_selectedCategory != 'All') {
      channels = channels
          .where((c) => detectCategory(c.name) == _selectedCategory)
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      channels = channels
          .where((c) =>
      c.name.toLowerCase().contains(q) ||
          c.group.toLowerCase().contains(q))
          .toList();
    }

    // Sort
    if (_sortBy == 'A-Z') {
      channels.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Z-A') {
      channels.sort((a, b) => b.name.compareTo(a.name));
    }

    setState(() => _filteredChannels = channels);
  }

  Future<void> _loadChannels(String url) async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load. Status: ${response.statusCode}');
      }

      final channels = _parseM3U(response.body);

      if (channels.isEmpty) {
        throw Exception('No channels found in the playlist.');
      }

      _m3uUrl = url;
      widget.onM3uLoaded(url);

      setState(() {
        _allChannels = channels;
        _filteredChannels = channels;
        _isLoading = false;
        _selectedCategory = 'All';
        _searchQuery = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  List<ChannelModel> _parseM3U(String content) {
    final lines = content.split('\n');
    final List<ChannelModel> channels = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF')) {
        String name = '';
        String logo = '';
        String group = 'Entertainment';
        String link = '';

        // Parse tvg-name
        final nameMatch = RegExp(r'tvg-name="([^"]*)"').firstMatch(line);
        if (nameMatch != null) {
          name = nameMatch.group(1) ?? '';
        }

        // Parse tvg-logo
        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        if (logoMatch != null) {
          logo = logoMatch.group(1) ?? '';
        }

        // Parse group-title
        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        if (groupMatch != null) {
          group = groupMatch.group(1) ?? 'Entertainment';
        }

        // If name not found from tvg-name, try extracting from comma
        if (name.isEmpty) {
          final commaIdx = line.lastIndexOf(',');
          if (commaIdx != -1 && commaIdx + 1 < line.length) {
            name = line.substring(commaIdx + 1).trim();
          }
        }

        // Get link from next non-empty line
        for (int j = i + 1; j < lines.length; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
            link = nextLine;
            break;
          }
        }

        if (name.isNotEmpty && link.isNotEmpty) {
          channels.add(ChannelModel(
            name: name,
            link: link,
            logo: logo,
            group: group,
          ));
        }
      }
    }

    return channels;
  }

  Future<void> _refreshChannels() async {
    if (_m3uUrl.isNotEmpty) {
      await _loadChannels(_m3uUrl);
    } else {
      // Try loading default
      _favorites = StorageService.getFavorites();
      _recentlyWatched = StorageService.getRecentlyWatched();
      setState(() {});
    }
  }

  // ── Time-based greeting ──
  String _getGreetingText() {
    final hour = DateTime.now().hour;
    final count = _filteredChannels.length;
    if (hour < 6) return '$count Channels Live | Good Night';
    if (hour < 12) return '$count Channels Live | Good Morning';
    if (hour < 17) return '$count Channels Live | Good Afternoon';
    if (hour < 21) return '$count Channels Live | Good Evening';
    return '$count Channels Live | Good Night';
  }

  void _playRandomChannel() {
    if (_allChannels.isEmpty) return;
    final random = Random();
    final channel = _allChannels[random.nextInt(_allChannels.length)];
    StorageService.addRecentlyWatched(channel.name);
    StorageService.incrementChannelView(channel.name);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerPage(channel: channel, channels: _allChannels),
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Statistics',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Channels', '${_allChannels.length}'),
            _buildStatRow('Favorites', '${_favorites.length}'),
            _buildStatRow('Recently Watched', '${_recentlyWatched.length}'),
            _buildStatRow('Showing', '${_filteredChannels.length}'),
            _buildStatRow('Category', _selectedCategory),
            _buildStatRow('Sort', _sortBy),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.poppins(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sort Channels',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: ['Default', 'A-Z', 'Z-A']
            .map((sort) => RadioListTile<String>(
          title: Text(sort,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          value: sort,
          groupValue: _sortBy,
          activeColor: AppTheme.primaryRed,
          onChanged: (val) {
            setState(() => _sortBy = val!);
            _applyFilters();
            Navigator.pop(ctx);
          },
        ))
            .toList(),
      ),
    );
  }

  // ── SEARCH BOTTOM SHEET ──
  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Search Channels', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (v) { _onSearchChanged(v); },
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isListening ? 'Listening...' : 'Type channel name...',
                hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryRed.withOpacity(0.6), size: 22),
                suffixIcon: _isListening
                    ? IconButton(icon: Icon(Icons.mic, color: Colors.red, size: 22), onPressed: _stopListening)
                    : IconButton(icon: Icon(Icons.mic_none, color: AppTheme.primaryRed.withOpacity(0.6), size: 22), onPressed: _startListening),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── CATEGORY BOTTOM SHEET ──
  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Select Category', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: categoryOrder.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedCategory = category);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryRed.withOpacity(0.2) : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primaryRed.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcons[category] ?? Icons.tv, color: isSelected ? AppTheme.primaryRed : Colors.white.withOpacity(0.5), size: 16),
                        const SizedBox(width: 6),
                        Text(category, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── RECENTLY WATCHED BOTTOM SHEET ──
  void _showRecentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Recently Watched', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._recentlyWatched.take(10).map((name) {
              final channel = _allChannels.firstWhere(
                    (c) => c.name == name,
                orElse: () => ChannelModel(name: name, link: '', logo: '', group: ''),
              );
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(10)),
                  child: channel.logo.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: channel.logo, fit: BoxFit.contain))
                      : Icon(Icons.tv, color: AppTheme.primaryRed, size: 20),
                ),
                title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.play_circle_filled, color: AppTheme.primaryRed, size: 28),
                onTap: () {
                  Navigator.pop(ctx);
                  if (channel.link.isNotEmpty) {
                    StorageService.addRecentlyWatched(channel.name);
                    StorageService.incrementChannelView(channel.name);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(channel: channel, channels: _allChannels)));
                  }
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showChannelInfoSheet(ChannelModel channel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (channel.logo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: channel.logo,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.darkBg,
                    child: Icon(Icons.tv, color: AppTheme.primaryRed, size: 30),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.darkBg,
                    child: Icon(Icons.tv, color: AppTheme.primaryRed, size: 30),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              channel.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                channel.group,
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryRed,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoAction(Icons.copy, 'Copy Link', () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: '${channel.name} - ${channel.link}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Channel link copied!',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      backgroundColor: AppTheme.accentBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }),
                _infoAction(Icons.play_circle, 'Open', () {
                  Navigator.pop(ctx);
                  StorageService.addRecentlyWatched(channel.name);
                  StorageService.incrementChannelView(channel.name);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerPage(
                        channel: channel,
                        channels: _allChannels,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryRed, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryRed.withOpacity(0.3),
                AppTheme.darkBg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(4),
          child: AppLogo.icon(size: 32),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.mainGradient.createShader(bounds),
          child: Text(
            'INDIA SERIAL HUB',
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR WITH COUNT ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? AppTheme.primaryRed.withOpacity(0.3)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  // Search icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(Icons.search, color: AppTheme.primaryRed, size: 20),
                  ),
                  // Text field
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search channels...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                  // Voice mic
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _isListening ? Border.all(color: Colors.red, width: 2) : null,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : AppTheme.primaryRed.withOpacity(0.6),
                        size: 18,
                      ),
                    ),
                  ),
                  // Channel count badge
                  Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_filteredChannels.length}',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── FILTER TABS ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: categoryOrder.map((category) {
                final isSelected = _selectedCategory == category;
                final count = category == 'Favorites'
                    ? _favorites.length
                    : category == 'Recent'
                    ? _recentlyWatched.length
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      _applyFilters();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryRed : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryRed : Colors.white.withOpacity(0.06),
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcons[category] ?? Icons.tv,
                            size: 14,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          if (count != null && count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.25)
                                    : AppTheme.accentBlue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : AppTheme.accentBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── DATA SAVER BADGE ──
          if (_dataSaverMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentGreen.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.data_saver_on, color: AppTheme.accentGreen, size: 13),
                  const SizedBox(width: 5),
                  Text('DATA SAVER ON', style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ],
              ),
            ),

          // ── CHANNEL GRID ──
          Expanded(
            child: _isLoading
                ? _buildShimmerGrid()
                : _isError
                ? _buildErrorState()
                : _filteredChannels.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              color: AppTheme.primaryRed,
              onRefresh: _refreshChannels,
              child: _buildChannelGrid(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating icon button helper ──  // ── Floating icon button helper ──
  Widget _floatingBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }



  Widget _buildShimmerGrid() {
    if (_dataSaverMode) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFoldingCube(color: AppTheme.primaryRed, size: 40),
            const SizedBox(height: 16),
            Text(
              'Loading channels...',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 15,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.primaryRed, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.bebasNeue(
                  color: Colors.white, fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshChannels,
              icon: const Icon(Icons.refresh),
              label: Text('Retry',
                  style: GoogleFonts.poppins(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tv_off, color: Colors.white.withOpacity(0.3), size: 60),
          const SizedBox(height: 16),
          Text(
            'No Channels Found',
            style: GoogleFonts.bebasNeue(
                color: Colors.white.withOpacity(0.6), fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Settings to load an M3U playlist',
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Channel Grid (Animated - matches screenshot design) ──
  Widget _buildChannelGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredChannels.length,
      itemBuilder: (context, index) {
        final channel = _filteredChannels[index];
        final isFav = _favorites.contains(channel.name);
        final category = detectCategory(channel.name);
        final epg = EPGService.getProgramForChannel(channel.name, category);

        // Staggered entrance animation + TV remote focus support
        return AnimatedChannelCard(
          index: index,
          isFav: isFav,
          onTap: () {
            StorageService.addRecentlyWatched(channel.name);
            StorageService.incrementChannelView(channel.name);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerPage(channel: channel, channels: _allChannels),
              ),
            );
          },
          onDoubleTap: () async {
            await StorageService.toggleFavorite(channel.name);
            setState(() => _favorites = StorageService.getFavorites());
            _applyFilters();
          },
          onLongPress: () => _showChannelInfoSheet(channel),
          child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFav
                      ? AppTheme.primaryRed.withOpacity(0.5)
                      : AppTheme.primaryRed.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFav
                        ? AppTheme.primaryRed.withOpacity(0.15)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  if (isFav)
                    BoxShadow(
                      color: AppTheme.primaryRed.withOpacity(0.08),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                children: [
                  // ── Logo area with favorite ──
                  Expanded(
                    child: Stack(
                      children: [
                        // ── Animated gradient behind logo ──
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: [
                                      AppTheme.primaryRed.withOpacity(
                                        0.03 + 0.03 * sin(
                                          _pulseController.value * 2 * pi + index * 0.5,
                                        ),
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Channel logo
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: (!_dataSaverMode && channel.logo.isNotEmpty)
                                ? Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: categoryGlowColor(category)
                                              .withOpacity(0.22),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: channel.logo,
                                        fit: BoxFit.contain,
                                        placeholder: (_, __) => const SpinKitPulse(
                                          color: AppTheme.primaryRed,
                                          size: 30,
                                        ),
                                        errorWidget: (_, __, ___) => Icon(
                                          Icons.tv,
                                          color: AppTheme.primaryRed.withOpacity(0.3),
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  )
                                : Icon(Icons.tv, color: AppTheme.primaryRed.withOpacity(0.3), size: 36),
                          ),
                        ),
                        // Favorite heart top-right
                        Positioned(
                          top: 4, right: 4,
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppTheme.primaryRed : Colors.white.withOpacity(0.25),
                            size: 16,
                          ),
                        ),
                        // Animated LIVE dot top-left
                        Positioned(
                          top: 6, left: 6,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              final pulseSize = 5.0 + 2.0 * sin(
                                _pulseController.value * 2 * pi + index * 0.6,
                              );
                              return Container(
                                width: pulseSize,
                                height: pulseSize,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5 + 0.4 * sin(
                                        _pulseController.value * 2 * pi + index * 0.6,
                                      )),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // EPG at bottom of logo area
                        if (epg.currentProgram.isNotEmpty)
                          Positioned(
                            bottom: 4, left: 4, right: 4,
                            child: Text(
                              epg.currentProgram,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppTheme.accentGreen.withOpacity(0.7),
                                fontSize: 7,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ── Channel name on RED strip ──
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) {
                      final stripGlow = 0.0 + 0.15 * sin(
                        _pulseController.value * 2 * pi + index * 0.3,
                      );
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryRed,
                              AppTheme.primaryRed.withOpacity(0.85 - stripGlow),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          boxShadow: stripGlow > 0.05
                              ? [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(stripGlow),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ]
                              : [],
                        ),
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANIMATED CHANNEL CARD
//  - Staggered entrance (fade + slide-up + pop) — ek baar, scroll par repeat
//  - TV Remote support: D-pad focus ring + OK/Enter button = open channel
//  - Touch: tap = play, double-tap = favorite, long-press = channel info
// ═══════════════════════════════════════════════════════════════════════════

Color categoryGlowColor(String category) {
  const catColors = {
    'News': AppTheme.accentBlue,
    'Entertainment': AppTheme.primaryRed,
    'Movies': AppTheme.accentGold,
    'Sports': AppTheme.neonGreen,
    'Kids': AppTheme.accentCyan,
    'Music': AppTheme.accentPurple,
    'Regional': AppTheme.accentGold,
    'Devotional': Colors.orangeAccent,
  };
  return catColors[category] ?? AppTheme.primaryRed;
}

class AnimatedChannelCard extends StatefulWidget {
  final int index;
  final bool isFav;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;
  final Widget child;

  const AnimatedChannelCard({
    super.key,
    required this.index,
    required this.isFav,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPress,
    required this.child,
  });

  @override
  State<AnimatedChannelCard> createState() => _AnimatedChannelCardState();
}

class _AnimatedChannelCardState extends State<AnimatedChannelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entrance;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'channel-card-${widget.index}');
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

    // Staggered start — grid me cards ek wave ki tarah aate hain
    Future.delayed(Duration(milliseconds: (widget.index % 12) * 55), () {
      if (mounted) _entrance.forward();
    });

    // TV: pehle card par auto-focus (sirf D-pad devices par)
    if (widget.index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final isDirectional =
            MediaQuery.of(context).navigationMode == NavigationMode.directional;
        if (isDirectional && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── TV Remote: OK / Enter / Select button = channel open ──
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      const keys = [
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
        LogicalKeyboardKey.gameButtonA,
        LogicalKeyboardKey.space,
      ];
      if (keys.contains(event.logicalKey)) {
        widget.onTap();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onLongPress: widget.onLongPress,
          child: AnimatedBuilder(
            animation: _entrance,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: child,
                  ),
                ),
              );
            },
            child: AnimatedScale(
              scale: _focused ? 1.07 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _focused ? AppTheme.primaryRed : Colors.transparent,
                    width: _focused ? 2.5 : 0,
                  ),
                  boxShadow: _focused
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryRed.withOpacity(0.55),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 13. PLAYER PAGE (with Aspect Ratio Toggle)
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════
//  PLAYER PAGE  —  Custom Controls + Zoom In/Out + Reliable Play/Pause
//  (Rewritten: fit/zoom now applies to VIDEO only, controls never distort)
// ═══════════════════════════════════════════════════════════════════════════

class PlayerPage extends StatefulWidget {
  final ChannelModel channel;
  final List<ChannelModel> channels;

  const PlayerPage({
    super.key,
    required this.channel,
    required this.channels,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late VideoPlayerController _videoController;
  late ChannelModel _currentChannel;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMsg = '';

  // Fit modes: default (Auto) | zoom | stretch | 16:9 | 4:3
  String _fitMode = 'default';
  bool _isFullScreen = false;
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isMuted = false;
  double _pinchScale = 1.0;
  double _scaleBase = 1.0;
  Timer? _hideTimer;

  static const Map<String, String> _modeLabels = {
    'default': 'Auto Fit',
    'zoom': 'Zoom (Fill Screen)',
    'stretch': 'Stretch',
    '16:9': 'Force 16:9',
    '4:3': 'Force 4:3',
  };

  // ── Picture-in-Picture (Android native via MethodChannel) ──
  static const MethodChannel _pipChannel = MethodChannel('com.indiaserialhub/pip');

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _fitMode = _normalizeMode(StorageService.getAspectRatio());
    _createController(_currentChannel);
  }

  String _normalizeMode(String saved) {
    const modes = ['default', 'zoom', 'stretch', '16:9', '4:3'];
    return modes.contains(saved) ? saved : 'default';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Controller lifecycle
  // ─────────────────────────────────────────────────────────────────────────
  void _createController(ChannelModel ch) {
    _videoController = VideoPlayerController.network(ch.link);
    _videoController.addListener(_onVideoTick);
    _videoController.initialize().then((_) {
      if (!mounted) return;
      _videoController.play();
      try {
        WakelockPlus.enable();
      } catch (_) {}
      setState(() => _isInitialized = true);
      _startHideTimer();
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMsg = e.toString();
      });
    });
  }

  void _onVideoTick() {
    if (!mounted) return;
    final v = _videoController.value;
    if (v.isPlaying != _isPlaying || v.isBuffering != _isBuffering) {
      setState(() {
        _isPlaying = v.isPlaying;
        _isBuffering = v.isBuffering;
      });
    }
  }

  void _playPause() {
    if (!_isInitialized) return;
    final v = _videoController.value;
    if (v.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    _resetHideTimer();
  }

  Future<void> _toggleMute() async {
    final newVol = _videoController.value.volume > 0 ? 0.0 : 1.0;
    await _videoController.setVolume(newVol);
    if (!mounted) return;
    setState(() => _isMuted = newVol == 0);
    _showToast(_isMuted ? 'Muted' : 'Sound On');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Fit / Zoom mode  —  applied ONLY to the video, never to the controls
  // ─────────────────────────────────────────────────────────────────────────
  void _setFitMode(String mode) {
    setState(() => _fitMode = mode);
    StorageService.setAspectRatio(mode);
    _showToast('Display: ${_modeLabels[mode] ?? mode}');
  }

  void _showFitModeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video Display / Zoom',
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final m in _modeLabels.keys)
                    ChoiceChip(
                      label: Text(
                        _modeLabels[m]!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      selected: _fitMode == m,
                      selectedColor: AppTheme.primaryRed,
                      backgroundColor: AppTheme.darkBg,
                      showCheckmark: false,
                      onSelected: (_) {
                        Navigator.pop(ctx);
                        _setFitMode(m);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Tip: Screen par pinch karke bhi 1x - 4x zoom kar sakte hain.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the raw video with the selected fit mode.
  /// FittedBox wraps ONLY the video texture — controls stay crisp & correct.
  Widget _buildVideoArea() {
    final size = _videoController.value.size;
    double vw = size.width;
    double vh = size.height;
    if (vw == 0 || vh == 0) {
      vw = 16;
      vh = 9;
    }

    BoxFit fit = BoxFit.contain;
    double? forcedRatio;

    switch (_fitMode) {
      case 'zoom':
        fit = BoxFit.cover;
        break;
      case 'stretch':
        fit = BoxFit.fill;
        break;
      case '16:9':
        forcedRatio = 16 / 9;
        break;
      case '4:3':
        forcedRatio = 4 / 3;
        break;
      default:
        fit = BoxFit.contain;
    }

    double boxW;
    double boxH;
    if (forcedRatio != null) {
      boxH = vh;
      boxW = vh * forcedRatio;
    } else {
      boxW = vw;
      boxH = vh;
    }

    return ClipRect(
      child: FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: boxW,
          height: boxH,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Controls visibility
  // ─────────────────────────────────────────────────────────────────────────
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: _isFullScreen ? 3 : 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _resetHideTimer() {
    if (_showControls) _startHideTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────
  //  TV Remote (D-pad) Key Handling
  //  OK / Enter      = Play / Pause
  //  Left / Right    = 10s seek (peeche / aage)
  //  Up / Down       = Channel change (next / previous)
  //  Back button     = Player se bahar (default navigation)
  // ───────────────────────────────────────────────────────────────────────
  KeyEventResult _handleTvKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;

    const List<LogicalKeyboardKey> okKeys = [
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.gameButtonA,
      LogicalKeyboardKey.space,
    ];

    // OK / Enter → Play / Pause
    if (okKeys.contains(key)) {
      // Agar koi button (back/mute/etc.) focused hai toh usko activate hone do
      if (FocusManager.instance.primaryFocus != node) {
        return KeyEventResult.ignored;
      }
      if (_hasError || !_isInitialized) return KeyEventResult.ignored;
      _playPause();
      if (!_showControls) {
        setState(() => _showControls = true);
      }
      _startHideTimer();
      return KeyEventResult.handled;
    }

    // Left / Right → Seek -10s / +10s
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      if (_hasError || !_isInitialized) return KeyEventResult.ignored;
      final bool fwd = key == LogicalKeyboardKey.arrowRight;
      final VideoPlayerValue v = _videoController.value;
      Duration target = v.position + Duration(seconds: fwd ? 10 : -10);
      if (target < Duration.zero) target = Duration.zero;
      if (v.duration > Duration.zero && target > v.duration) {
        target = v.duration;
      }
      _videoController.seekTo(target);
      if (!_showControls) {
        setState(() => _showControls = true);
      }
      _startHideTimer();
      return KeyEventResult.handled;
    }

    // Up / Down → Channel switch
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      if (_hasError) return KeyEventResult.ignored;
      // Buttons focused hain toh normal focus traversal hone do
      if (FocusManager.instance.primaryFocus != node) {
        return KeyEventResult.ignored;
      }
      _playAdjacentChannel(key == LogicalKeyboardKey.arrowUp ? 1 : -1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Fullscreen
  // ─────────────────────────────────────────────────────────────────────────
  void _toggleFullScreen() {
    // TV pe orientation change ki zaroorat nahi (TV hamesha landscape hai)
    final bool tvDevice = isLandscapeNativeDevice();
    if (!_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (!tvDevice) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      setState(() => _isFullScreen = true);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (!tvDevice) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
      setState(() => _isFullScreen = false);
    }
    _startHideTimer();
  }

  void _retryPlayer() {
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _isBuffering = false;
      _errorMsg = '';
    });
    _videoController.removeListener(_onVideoTick);
    _videoController.dispose();
    _createController(_currentChannel);
  }

  // ── Picture-in-Picture ──
  Future<void> _enterPiP() async {
    try {
      await _pipChannel.invokeMethod('enterPiP', {
        'aspectRatioX': 16,
        'aspectRatioY': 9,
      });
      if (mounted) _showToast('Playing in Picture-in-Picture mode');
    } on PlatformException catch (_) {
      if (mounted) _showToast('PiP not supported on this device');
    } catch (_) {
      if (mounted) _showToast('PiP entering failed. Try fullscreen instead.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Channel switching
  // ─────────────────────────────────────────────────────────────────────────
  void _switchChannel(ChannelModel newChannel) {
    _videoController.removeListener(_onVideoTick);
    _videoController.dispose();
    StorageService.addRecentlyWatched(newChannel.name);
    StorageService.incrementChannelView(newChannel.name);
    setState(() {
      _currentChannel = newChannel;
      _hasError = false;
      _isInitialized = false;
      _isBuffering = false;
      _isPlaying = false;
      _pinchScale = 1.0;
      _showControls = true;
    });
    _createController(newChannel);
  }

  void _playAdjacentChannel(int offset) {
    if (widget.channels.isEmpty) return;
    final idx = widget.channels.indexOf(_currentChannel);
    if (idx == -1) return;
    final next = widget.channels[(idx + offset) % widget.channels.length];
    _switchChannel(next);
  }

  void _showChannelListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Switch Channel',
                  style: GoogleFonts.bebasNeue(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.channels.length,
                  itemBuilder: (_, index) {
                    final ch = widget.channels[index];
                    final isCurrent = ch == _currentChannel;
                    return ListTile(
                      selected: isCurrent,
                      selectedTileColor: AppTheme.primaryRed.withOpacity(0.12),
                      leading: ch.logo.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: ch.logo,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => Container(
                                  width: 40,
                                  height: 40,
                                  color: AppTheme.darkBg,
                                  child: Icon(Icons.tv,
                                      color: AppTheme.primaryRed, size: 18),
                                ),
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.darkBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.tv,
                                  color: AppTheme.primaryRed, size: 18),
                            ),
                      title: Text(
                        ch.name,
                        style: GoogleFonts.poppins(
                          color: isCurrent
                              ? AppTheme.accentGold
                              : Colors.white,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        ch.group,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isCurrent) _switchChannel(ch);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    if (_isFullScreen && !isLandscapeNativeDevice()) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    _videoController.removeListener(_onVideoTick);
    _videoController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  UI
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // TV Remote: D-pad keys poore player par kaam karein
    return Focus(
      autofocus: true,
      onKeyEvent: _handleTvKey,
      child: Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen ? null : _buildAppBar(),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onDoubleTap: _toggleFullScreen,
        onScaleStart: (details) => _scaleBase = _pinchScale,
        onScaleUpdate: (details) {
          if (details.scale == 1.0) return;
          final s = (_scaleBase * details.scale).clamp(1.0, 4.0);
          if ((s - _pinchScale).abs() > 0.01) {
            setState(() => _pinchScale = s);
          }
        },
        onScaleEnd: (_) {
          if (_pinchScale <= 1.05 && mounted) {
            setState(() => _pinchScale = 1.0);
          }
        },
        child: Center(
          child: _hasError
              ? _buildPlayerError()
              : !_isInitialized
                  ? _buildLoading()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Zoomed video (pinch) — transforms video only
                        Transform.scale(
                          scale: _pinchScale,
                          child: _buildVideoArea(),
                        ),
                        if (_isBuffering) _buildBufferingIndicator(),
                        if (_showControls) _buildControlsOverlay(),
                        // Persistent exit-fullscreen pill (always visible in fs)
                        if (_isFullScreen && !_showControls)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _toggleFullScreen,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Icon(
                                  Icons.fullscreen_exit,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        // Reset pinch zoom pill
                        if (_pinchScale > 1.02)
                          Positioned(
                            bottom: _showControls ? 90 : 24,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => setState(() => _pinchScale = 1.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.accentGold
                                        .withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_out_map,
                                        color: AppTheme.accentGold, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reset Zoom ${_pinchScale.toStringAsFixed(1)}x',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          if (widget.channel.logo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CachedNetworkImage(
                imageUrl: widget.channel.logo,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Expanded(
            child: Text(
              widget.channel.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Fullscreen Toggle
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 22,
            ),
            tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
            onPressed: _toggleFullScreen,
          ),
        ),
        // Fit / Zoom sheet
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.aspect_ratio,
                color: Colors.white.withOpacity(0.9), size: 20),
            tooltip: 'Display: ${_modeLabels[_fitMode] ?? _fitMode}',
            onPressed: _showFitModeSheet,
          ),
        ),
        // Picture-in-Picture Toggle
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.picture_in_picture_alt,
                color: AppTheme.accentCyan, size: 20),
            tooltip: 'Picture-in-Picture',
            onPressed: _isInitialized ? _enterPiP : null,
          ),
        ),
        // Channel List
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.list, color: Colors.white, size: 20),
            onPressed: _showChannelListSheet,
          ),
        ),
      ],
    );
  }

  // ── Overlay controls ──
  Widget _buildControlsOverlay() {
    final isLive = _videoController.value.duration <= Duration.zero;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0, 0.18, 0.82, 1],
        ),
      ),
      child: Column(
        children: [
          // ── TOP BAR ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_isFullScreen) {
                        _toggleFullScreen();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  if (_currentChannel.logo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CachedNetworkImage(
                        imageUrl: _currentChannel.logo,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _currentChannel.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _overlayIconBtn(
                    icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                    tooltip: _isMuted ? 'Unmute' : 'Mute',
                    onTap: _toggleMute,
                  ),
                  _overlayIconBtn(
                    icon: Icons.picture_in_picture_alt,
                    tooltip: 'Picture-in-Picture',
                    onTap: _enterPiP,
                  ),
                  _overlayIconBtn(
                    icon: Icons.aspect_ratio,
                    tooltip: 'Display: ${_modeLabels[_fitMode] ?? _fitMode}',
                    onTap: _showFitModeSheet,
                  ),
                  _overlayIconBtn(
                    icon: Icons.list,
                    tooltip: 'Channel List',
                    onTap: _showChannelListSheet,
                  ),
                  _overlayIconBtn(
                    icon: _isFullScreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
                    onTap: _toggleFullScreen,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // ── CENTER: prev / play-pause / next ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bigControlBtn(
                icon: Icons.skip_previous_rounded,
                onTap: () => _playAdjacentChannel(-1),
              ),
              const SizedBox(width: 28),
              _buildPlayPauseButton(),
              const SizedBox(width: 28),
              _bigControlBtn(
                icon: Icons.skip_next_rounded,
                onTap: () => _playAdjacentChannel(1),
              ),
            ],
          ),
          const Spacer(),
          // ── BOTTOM BAR ──
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, color: AppTheme.primaryRed, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    isLive ? 'LIVE' : 'PLAYING',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showFitModeSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentGold.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in,
                              color: AppTheme.accentGold, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _modeLabels[_fitMode] ?? _fitMode,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlayIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  Widget _bigControlBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 30),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryRed.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            _isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            key: ValueKey<bool>(_isPlaying),
            color: Colors.white,
            size: 44,
          ),
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitFoldingCube(color: AppTheme.primaryRed, size: 36),
            const SizedBox(height: 12),
            Text(
              'Buffering...',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinKitFoldingCube(color: AppTheme.primaryRed, size: 50),
        const SizedBox(height: 20),
        Text(
          'Loading stream...',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: AppTheme.primaryRed, size: 60),
        const SizedBox(height: 16),
        Text(
          'Playback Error',
          style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _retryPlayer,
          icon: const Icon(Icons.refresh),
          label:
              Text('Retry Stream', style: GoogleFonts.poppins(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 14. ADMIN PANEL (SETTINGS) - with Firebase / Cloud section
// ─────────────────────────────────────────────────────────────────────────────

class AdminPanel extends StatefulWidget {
  final String m3uUrl;
  final ValueChanged<String> onM3uLoaded;
  final bool nightMode;
  final bool dataSaverMode;
  final ValueChanged<bool> onNightModeChanged;
  final ValueChanged<bool> onDataSaverChanged;

  const AdminPanel({
    super.key,
    required this.m3uUrl,
    required this.onM3uLoaded,
    this.nightMode = false,
    this.dataSaverMode = false,
    required this.onNightModeChanged,
    required this.onDataSaverChanged,
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late TextEditingController _urlController;
  bool _isLoading = false;
  String _loadStatus = '';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.m3uUrl.isNotEmpty ? widget.m3uUrl : 'REDACTED');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an M3U URL',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadStatus = 'Loading channels...';
    });

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode == 200) {
        widget.onM3uLoaded(url);
        setState(() => _loadStatus = 'Channels loaded successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Channels loaded! Switch to Channels tab.',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() => _loadStatus = 'Failed: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadStatus = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Fun Fact of the Day ──
  String _getFunFact() {
    final facts = [
      'India has 900+ TV channels across 30+ languages',
      'Star Plus launched in 1991 and revolutionized Indian TV',
      'TRP system was introduced in India in 1996',
      'DD National is India\'s oldest TV channel since 1959',
      'Sony TV started as Sony Entertainment Television in 1995',
      'Colors TV launched its first show in 2008',
      'Zee TV was India\'s first private Hindi channel',
      'Indian TV industry is worth over Rs 70,000 crore',
      'Tata Sky (now Tata Play) launched in 2006',
      'Hotstar got 10M downloads in first week of IPL 2019',
      'Bigg Boss started in India in 2006',
      'KBC made Amitabh Bachchan a household TV name',
    ];
    final today = DateTime.now();
    final seed = today.day + today.month * 31;
    return facts[seed % facts.length];
  }

  Future<void> _clearFavorites() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Clear Favorites?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('This will remove all your favorite channels.',
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                GoogleFonts.poppins(color: Colors.white.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style: GoogleFonts.poppins(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favorites cleared',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Clear Watch History?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('This will remove your recently watched channels.',
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                GoogleFonts.poppins(color: Colors.white.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style: GoogleFonts.poppins(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Watch history cleared',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Clear ALL Data?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text(
            'This will delete ALL app data including favorites, history, and settings. This cannot be undone.',
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                GoogleFonts.poppins(color: Colors.white.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete All',
                style: GoogleFonts.poppins(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All data cleared',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryRed).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryRed, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.5), fontSize: 12)),
      trailing: Icon(Icons.chevron_right,
          color: Colors.white.withOpacity(0.3)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryRed.withOpacity(0.3),
                AppTheme.accentGold.withOpacity(0.1),
                AppTheme.darkBg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primaryRed, AppTheme.accentGold],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            'Settings',
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── CREATIVE PROFILE HEADER ──
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.1),
                    AppTheme.accentPurple.withOpacity(0.05),
                    AppTheme.surfaceDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // AppLogo as avatar with neon ring
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryRed.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(child: AppLogo.icon(size: 55)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [AppTheme.primaryRed, AppTheme.accentPurple],
                          ).createShader(bounds),
                          child: Text(
                            'India Serial Hub',
                            style: GoogleFonts.bebasNeue(
                              color: Colors.white,
                              fontSize: 26,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live TV & Entertainment Platform',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGold.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'v3.0',
                          style: GoogleFonts.poppins(
                            color: AppTheme.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── M3U URL SECTION ──
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link,
                          color: AppTheme.primaryRed, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'M3U Playlist URL',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter M3U / M3U8 playlist URL...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppTheme.darkBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadChannels,
                      icon: _isLoading
                          ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.download),
                      label: Text(
                        _isLoading ? 'Loading...' : 'Load Channels',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        AppTheme.primaryRed.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (_loadStatus.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _loadStatus,
                      style: GoogleFonts.poppins(
                        color: _loadStatus.contains('success')
                            ? Colors.green
                            : _loadStatus.contains('Error')
                            ? Colors.red
                            : Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── CHANNEL OF THE DAY ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGold.withOpacity(0.12),
                    AppTheme.primaryRed.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Did You Know?',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentGold.withOpacity(0.12)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb, color: AppTheme.accentGold, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getFunFact(),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── ADMIN PANEL ENTRY ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.15),
                    AppTheme.primaryRed.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentPurple.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentPurple, AppTheme.primaryRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 22),
                ),
                title: Text('Admin Panel',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: Text('View users, analytics & device info (Password Protected)',
                    style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.45), fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lock, color: AppTheme.accentPurple, size: 18),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboard()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── DATA MANAGEMENT SECTION ──
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage,
                          color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Data Management',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _settingsTile(
                    icon: Icons.favorite_border,
                    title: 'Clear Favorites',
                    subtitle: 'Remove all saved favorite channels',
                    iconColor: AppTheme.primaryRed,
                    onTap: _clearFavorites,
                  ),
                  _settingsTile(
                    icon: Icons.history,
                    title: 'Clear Watch History',
                    subtitle: 'Remove recently watched channels',
                    iconColor: AppTheme.accentBlue,
                    onTap: _clearHistory,
                  ),
                  _settingsTile(
                    icon: Icons.delete_forever,
                    title: 'Clear All Data',
                    subtitle: 'Delete all app data permanently',
                    iconColor: Colors.red.shade400,
                    onTap: _clearAllData,
                  ),
                  const SizedBox(height: 12),
                  // ── Data Saver Toggle ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withOpacity(0.15)),
                    ),
                    child: SwitchListTile(
                      secondary: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.data_saver_on, color: AppTheme.accentGreen, size: 18),
                      ),
                      title: Text('Data Saver Mode',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text('Reduce data usage - smaller icons, no network images',
                          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      activeColor: AppTheme.accentGreen,
                      value: widget.dataSaverMode,
                      onChanged: (val) {
                        widget.onDataSaverChanged(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Data Saver ON - images disabled' : 'Data Saver OFF - full experience',
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            backgroundColor: AppTheme.accentGreen,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  // ── Night Mode Toggle ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGold.withOpacity(0.15)),
                    ),
                    child: SwitchListTile(
                      secondary: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.nightlight, color: AppTheme.accentGold, size: 18),
                      ),
                      title: Text('Night Mode (Blue Light Filter)',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text('Warm amber overlay to reduce eye strain',
                          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      activeColor: AppTheme.accentGold,
                      value: widget.nightMode,
                      onChanged: (val) {
                        widget.onNightModeChanged(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Night Mode ON - warm filter active' : 'Night Mode OFF',
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            backgroundColor: AppTheme.accentGold,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── WATCH HISTORY SECTION ──
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentBlue.withOpacity(0.06),
                    AppTheme.cardBg,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: AppTheme.accentBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Watch History',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          await _clearHistory();
                          if (mounted) setState(() {});
                        },
                        child: Text('Clear All',
                            style: GoogleFonts.poppins(
                                color: AppTheme.accentBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildWatchHistoryList(),
                ],
              ),
            ),

            // ── ABOUT SECTION ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.white.withOpacity(0.7), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'About',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _aboutRow('Version', '7.0.0 (Creative Edition)'),
                  _aboutRow('Built With', 'Flutter + Custom Video Player'),
                  _aboutRow('Stream Format', 'HLS / M3U8 / M3U'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── DEVIL { APP DEVELOPER } FOOTER ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.15),
                    AppTheme.accentGold.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Top border line
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.redGradient,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Devil gradient text
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [AppTheme.primaryRed, AppTheme.accentGold],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Devil { App Developer }',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 28,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created by Devil',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildWatchHistoryList() {
    final history = StorageService.getRecentlyWatched();
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, color: Colors.white.withOpacity(0.15), size: 32),
              const SizedBox(height: 8),
              Text(
                'No watch history yet',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final displayItems = history.take(10).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayItems.map((channelName) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.accentBlue.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withOpacity(0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.live_tv, color: AppTheme.accentBlue, size: 12),
              const SizedBox(width: 6),
              Text(
                channelName,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  await StorageService.removeRecentlyWatched(channelName);
                  if (mounted) setState(() {});
                },
                child: Icon(
                  Icons.close,
                  color: Colors.white.withOpacity(0.3),
                  size: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 15. ADMIN DASHBOARD (Password Protected)
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  bool _isUnlocked = false;
  bool _isLoading = true;
  final TextEditingController _passController = TextEditingController();
  bool _showPassword = false;
  String _errorText = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Dashboard data
  int _appOpenCount = 0;
  int _totalSessions = 0;
  int _totalChannelViews = 0;
  int _favoriteCount = 0;
  int _historyCount = 0;
  List<String> _sessions = [];
  List<Map<String, String>> _devices = [];
  Map<String, int> _channelViews = {};
  List<String> _watchHistory = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    // Check if already logged in
    _checkLogin();
  }

  void _checkLogin() {
    if (StorageService.isAdminLoggedIn()) {
      _isUnlocked = true;
      _loadDashboardData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _loadDashboardData() {
    setState(() {
      _appOpenCount = StorageService.getAppOpenCount();
      _totalSessions = StorageService.getSessionCount();
      _totalChannelViews = StorageService.getTotalChannelViews();
      _favoriteCount = StorageService.getFavorites().length;
      _historyCount = StorageService.getRecentlyWatched().length;
      _sessions = StorageService.getSessions();
      _devices = StorageService.getRegisteredDevices();
      _channelViews = StorageService.getChannelViews();
      _watchHistory = StorageService.getRecentlyWatched();
      _isLoading = false;
    });
    _fadeController.forward();
  }

  void _tryLogin() {
    final pass = _passController.text.trim();
    final storedPass = StorageService.getAdminPassword();
    if (pass == storedPass) {
      StorageService.setAdminLoggedIn(true);
      setState(() {
        _isUnlocked = true;
        _errorText = '';
      });
      _loadDashboardData();
    } else {
      setState(() => _errorText = 'Wrong password! Try again.');
    }
  }

  @override
  void dispose() {
    _passController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentPurple.withOpacity(0.3),
                AppTheme.primaryRed.withOpacity(0.15),
                AppTheme.darkBg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.accentPurple, AppTheme.primaryRed],
          ).createShader(bounds),
          child: Text(
            'Admin Panel',
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ),
        actions: [
          if (_isUnlocked)
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.7)),
              tooltip: 'Logout',
              onPressed: () {
                StorageService.setAdminLoggedIn(false);
                setState(() {
                  _isUnlocked = false;
                  _passController.clear();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: SpinKitFoldingCube(color: AppTheme.accentPurple, size: 50))
          : _isUnlocked
          ? _buildDashboard()
          : _buildLoginScreen(),
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentPurple.withOpacity(0.2), AppTheme.primaryRed.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentPurple.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: const Icon(Icons.shield, color: AppTheme.accentPurple, size: 44),
            ),
            const SizedBox(height: 28),
            Text(
              'Admin Access Only',
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter admin password to continue',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            // Password field
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _errorText.isNotEmpty
                      ? Colors.red.withOpacity(0.5)
                      : AppTheme.accentPurple.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentPurple.withOpacity(0.08), blurRadius: 15),
                ],
              ),
              child: TextField(
                controller: _passController,
                obscureText: !_showPassword,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                onSubmitted: (_) => _tryLogin(),
                decoration: InputDecoration(
                  hintText: 'Enter admin password...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.25), fontSize: 14),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.lock_outline, color: AppTheme.accentPurple.withOpacity(0.7), size: 20),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withOpacity(0.4),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_errorText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 6),
                  Text(_errorText, style: GoogleFonts.poppins(color: Colors.red.shade400, fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Default password: REDACTED',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.25), fontSize: 11),
            ),
            const SizedBox(height: 24),
            // Login button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.primaryRed]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentPurple.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: ElevatedButton(
                onPressed: _tryLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Unlock Admin Panel', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const Icon(Icons.lock_open, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: AppTheme.accentPurple,
        onRefresh: () async {
          _loadDashboardData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── ADMIN HEADER ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentPurple.withOpacity(0.15),
                      AppTheme.primaryRed.withOpacity(0.08),
                      AppTheme.surfaceDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentPurple.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentPurple.withOpacity(0.1), blurRadius: 25, spreadRadius: 2),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.primaryRed]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppTheme.accentPurple.withOpacity(0.3), blurRadius: 15),
                        ],
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.accentPurple, Colors.white],
                            ).createShader(bounds),
                            child: Text(
                              'Admin Dashboard',
                              style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 24, letterSpacing: 1.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time app analytics & user data',
                            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppTheme.neonGreen, blurRadius: 6)],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('LIVE', style: GoogleFonts.poppins(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── STATS GRID ──
              _buildStatsGrid(),
              const SizedBox(height: 16),

              // ── DEVICE INFO CARD ──
              _buildDeviceInfoCard(),
              const SizedBox(height: 16),

              // ── REGISTERED DEVICES / USERS ──
              _buildDevicesList(),
              const SizedBox(height: 16),

              // ── TOP CHANNELS ──
              _buildTopChannels(),
              const SizedBox(height: 16),

              // ── SESSION LOG ──
              _buildSessionLog(),
              const SizedBox(height: 16),

              // ── WATCH HISTORY ──
              _buildWatchHistory(),
              const SizedBox(height: 16),

              // ── ADMIN ACTIONS ──
              _buildAdminActions(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _statItem('App Opens', '$_appOpenCount', Icons.touch_app, AppTheme.primaryRed),
      _statItem('Sessions', '$_totalSessions', Icons.schedule, AppTheme.accentBlue),
      _statItem('Channel Views', '$_totalChannelViews', Icons.play_circle, AppTheme.accentPurple),
      _statItem('Favorites', '$_favoriteCount', Icons.favorite, Colors.pink),
      _statItem('History Items', '$_historyCount', Icons.history, AppTheme.accentGold),
      _statItem('Top Channel', _channelViews.isNotEmpty ? _channelViews.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'N/A', Icons.emoji_events, AppTheme.accentGold),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => stats[i],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), AppTheme.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: value.length > 10 ? 14 : 20,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    final deviceId = StorageService.getDeviceId();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentCyan.withOpacity(0.06), AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.devices, color: AppTheme.accentCyan, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Device Information', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.fingerprint, 'Device ID', deviceId),
          const SizedBox(height: 8),
          _infoRow(Icons.people, 'Registered Devices', '${_devices.length}'),
          const SizedBox(height: 8),
          _infoRow(Icons.history, 'Total Sessions', '$_totalSessions'),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time, 'Last Session', _sessions.isNotEmpty ? _formatDateTime(_sessions.first) : 'No sessions'),
          const SizedBox(height: 8),
          _infoRow(Icons.play_arrow, 'Total Views', '$_totalChannelViews'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.3), size: 14),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentGreen.withOpacity(0.06), AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smartphone, color: AppTheme.accentGreen, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Registered Devices / Users', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_devices.length}', style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_devices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No devices registered yet', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ),
            )
          else
            ..._devices.map((device) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.accentGreen, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device['id'] ?? 'Unknown', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(device['info'] ?? 'Unknown Device', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppTheme.neonGreen, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(device['lastSeen'] ?? ''),
                        style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildTopChannels() {
    final sorted = _channelViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentGold.withOpacity(0.06), AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart, color: AppTheme.accentGold, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Most Watched Channels', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No channel views recorded yet', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ),
            )
          else
            ...top.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final channel = entry.value;
              final maxViews = top.first.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: i < 3
                                ? [AppTheme.accentGold, Colors.grey.shade400, Colors.brown.shade400][i]
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.poppins(
                                color: i < 3 ? AppTheme.darkBg : Colors.white.withOpacity(0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            channel.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${channel.value} views',
                          style: GoogleFonts.poppins(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: maxViews > 0 ? channel.value / maxViews : 0,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          i == 0 ? AppTheme.accentGold : i == 1 ? Colors.grey.shade400 : AppTheme.accentPurple,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSessionLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentBlue.withOpacity(0.06), AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, color: AppTheme.accentBlue, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Session Log', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$_totalSessions total', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          if (_sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No sessions recorded yet', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ),
            )
          else
            ..._sessions.take(15).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final session = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: i == 0 ? AppTheme.accentBlue.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: i == 0 ? Border.all(color: AppTheme.accentBlue.withOpacity(0.15)) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      i == 0 ? Icons.fiber_manual_record : Icons.circle,
                      color: i == 0 ? AppTheme.neonGreen : Colors.white.withOpacity(0.15),
                      size: i == 0 ? 8 : 5,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDateTime(session),
                        style: GoogleFonts.poppins(
                          color: i == 0 ? Colors.white : Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (i == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Latest', style: GoogleFonts.poppins(color: AppTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWatchHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRed.withOpacity(0.06), AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tv, color: AppTheme.primaryRed, size: 16),
              ),
              const SizedBox(width: 8),
              Text('User Watch History', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          if (_watchHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No watch history available', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _watchHistory.take(15).map((ch) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryRed.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.live_tv, color: AppTheme.primaryRed, size: 11),
                      const SizedBox(width: 5),
                      Text(ch, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.06), AppTheme.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Admin Actions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _actionButton(
            icon: Icons.delete_sweep,
            title: 'Clear All User Data',
            subtitle: 'Delete sessions, views, device logs',
            color: Colors.red,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Clear ALL Admin Data?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  content: Text('This will delete all session logs, channel views, and device data. This cannot be undone.',
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await StorageService.clearAllData();
                _loadDashboardData();
              }
            },
          ),
          const SizedBox(height: 8),
          _actionButton(
            icon: Icons.key,
            title: 'Change Admin Password',
            subtitle: 'Current: ${StorageService.getAdminPassword()}',
            color: AppTheme.accentGold,
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 8),
          _actionButton(
            icon: Icons.assessment,
            title: 'Export App Data',
            subtitle: 'Copy analytics data to clipboard',
            color: AppTheme.accentBlue,
            onTap: () {
              final data = 'India Serial Hub - Admin Report\n'
                  '━━━━━━━━━━━━━━━━━━━━━\n'
                  'App Opens: $_appOpenCount\n'
                  'Sessions: $_totalSessions\n'
                  'Total Views: $_totalChannelViews\n'
                  'Favorites: $_favoriteCount\n'
                  'History Items: $_historyCount\n'
                  'Device ID: ${StorageService.getDeviceId()}\n'
                  'Registered Devices: ${_devices.length}\n'
                  '━━━━━━━━━━━━━━━━━━━━━\n'
                  'Top Channel: ${_channelViews.isNotEmpty ? _channelViews.entries.reduce((a, b) => a.value > b.value ? a : b).key : "N/A"}\n'
                  '━━━━━━━━━━━━━━━━━━━━━\n'
                  'Report Generated: ${DateTime.now().toIso8601String()}';
              Clipboard.setData(ClipboardData(text: data));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report copied to clipboard!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                  backgroundColor: AppTheme.accentGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Admin Password', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: newPassController,
          obscureText: true,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new password...',
            hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: AppTheme.darkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.accentGold)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)))),
          TextButton(
            onPressed: () async {
              final newPass = newPassController.text.trim();
              if (newPass.length >= 4) {
                await StorageService.setAdminPassword(newPass);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password changed successfully!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                      backgroundColor: AppTheme.accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Password must be at least 4 characters', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Save', style: GoogleFonts.poppins(color: AppTheme.accentGold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

/// ─────────────────────────────────────────────────────────────────────────
/// TV SAFETY: Android TV / LED TV landscape device hai. Agar app start hote
/// hi portrait lock laga dein toh kai TVs par app black screen dikhati hai
/// ya open hi nahi hoti. Isliye TV jaise landscape devices par portrait
/// lock bilkul nahi lagayenge.
/// ─────────────────────────────────────────────────────────────────────────
bool isLandscapeNativeDevice() {
  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final double w = view.physicalSize.width;
    final double h = view.physicalSize.height;
    if (w <= 0 || h <= 0) return false;
    return w > h; // TV hamesha landscape orientation me hota hai
  } catch (_) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT: TV par portrait lock lagana app ko crash/black-screen karta
  // hai, isliye sirf phone par lock lagate hain.
  if (!isLandscapeNativeDevice()) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const IndiaSerialHub());
}
