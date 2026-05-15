import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'search_autocomplete.dart';
import 'app_theme.dart';
import 'profile_screen.dart';
import 'weather_logs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedTheme();
  runApp(const SkyTrackApp());
}

// ── App ───────────────────────────────────────────────────────────────────────

class SkyTrackApp extends StatelessWidget {
  const SkyTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SkyTrack Weather App',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const _AuthGate(),
        routes: {
          '/home': (_) => const WeatherHome(),
          '/login': (_) => const LoginScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/logs': (_) => const WeatherLogsScreen(),
        },
      ),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!mounted) return;
    if (loggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ── Models ────────────────────────────────────────────────────────────────────

class SavedCity {
  final int id;
  final String city;
  final String condition;
  final int temp;
  final int feelsLike;
  final int humidity;
  final int windKph;
  final bool isPinned;
  final DateTime addedAt;

  const SavedCity({
    required this.id,
    required this.city,
    required this.condition,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windKph,
    this.isPinned = false,
    required this.addedAt,
  });

  SavedCity copyWith({
    String? city,
    String? condition,
    int? temp,
    int? feelsLike,
    int? humidity,
    int? windKph,
    bool? isPinned,
  }) =>
      SavedCity(
        id: id,
        city: city ?? this.city,
        condition: condition ?? this.condition,
        temp: temp ?? this.temp,
        feelsLike: feelsLike ?? this.feelsLike,
        humidity: humidity ?? this.humidity,
        windKph: windKph ?? this.windKph,
        isPinned: isPinned ?? this.isPinned,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'city': city,
        'condition': condition,
        'temp': temp,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'windKph': windKph,
        'isPinned': isPinned,
        'addedAt': addedAt.toIso8601String(),
      };

  factory SavedCity.fromJson(Map<String, dynamic> j) => SavedCity(
        id: j['id'] as int,
        city: j['city'] as String,
        condition: j['condition'] as String,
        temp: j['temp'] as int,
        feelsLike: j['feelsLike'] as int,
        humidity: j['humidity'] as int,
        windKph: j['windKph'] as int,
        isPinned: j['isPinned'] as bool? ?? false,
        addedAt: DateTime.parse(j['addedAt'] as String),
      );
}

class WeatherData {
  final String city, condition;
  final int temp, feelsLike, humidity, windKph;

  const WeatherData({
    required this.city,
    required this.condition,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windKph,
  });
}

class HourlyEntry {
  final String time, icon;
  final int temp;
  const HourlyEntry(this.time, this.icon, this.temp);
}

class DailyEntry {
  final String day, icon, condition;
  final int low, high;
  const DailyEntry(this.day, this.icon, this.condition, this.low, this.high);
}

// ── Constants (from app_theme.dart) ─────────────────────────────────────────

// ── Storage ───────────────────────────────────────────────────────────────────

class CityStorage {
  static const _key = 'skytrack_saved_cities';

  static Future<List<SavedCity>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SavedCity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<SavedCity> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(cities.map((c) => c.toJson()).toList()));
  }
}

// ── Home Screen ───────────────────────────────────────────────────────────────

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  bool _loading = false;
  String? _error;
  int _selectedHour = 0;
  List<SavedCity> _savedCities = [];
  int _nextId = 1;
  bool _isCelsius = true;
  String? _homeCityName;

  WeatherData? _weather; // null = no city loaded yet

  final List<HourlyEntry> _hourly = const [
    HourlyEntry('Now', '⛅', 29),
    HourlyEntry('3 PM', '🌤', 30),
    HourlyEntry('6 PM', '🌦', 28),
    HourlyEntry('9 PM', '🌧', 26),
    HourlyEntry('12 AM', '🌙', 24),
    HourlyEntry('3 AM', '🌙', 23),
  ];

  final List<DailyEntry> _daily = const [
    DailyEntry('Mon', '☀️', 'Sunny', 25, 33),
    DailyEntry('Tue', '⛅', 'Partly Cloudy', 24, 31),
    DailyEntry('Wed', '🌧', 'Heavy Rain', 22, 28),
    DailyEntry('Thu', '🌦', 'Showers', 23, 29),
    DailyEntry('Fri', '⛅', 'Cloudy', 24, 30),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedCities();
    _loadLastCity();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSavedCities() async {
    final cities = await CityStorage.load();
    setState(() {
      _savedCities = cities;
      _nextId = cities.fold(0, (m, c) => c.id > m ? c.id : m) + 1;
    });
  }

  // Restore the home city or last searched city on app restart
  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    final homeCity = prefs.getString('home_city');
    final lastCity = prefs.getString('last_city');
    
    setState(() {
      _homeCityName = homeCity;
    });

    final cityToLoad = (homeCity != null && homeCity.isNotEmpty) ? homeCity : lastCity;
    if (cityToLoad != null && cityToLoad.isNotEmpty) {
      await _fetchWeather(cityToLoad);
    }
  }

  Future<void> _setHomeCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    if (_homeCityName == city) {
      await prefs.remove('home_city');
      setState(() => _homeCityName = null);
    } else {
      await prefs.setString('home_city', city);
      setState(() => _homeCityName = city);
    }
  }

  void _toggleTheme() {
    final next = context.isDark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = next;
    saveTheme(next);
  }

  Future<void> _logout() async {
    // Show a friendly reminder before signing out
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Goodbye!'),
        content: const Text("Whenever you want to know the sky's mood just log in again!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // ── Temperature conversion ────────────────────────────────────────────────

  int _toDisplay(int celsius) =>
      _isCelsius ? celsius : ((celsius * 9 / 5) + 32).round();

  String get _unit => _isCelsius ? '°C' : '°F';

  // ── Condition helpers ─────────────────────────────────────────────────────

  String _conditionIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('sun')) return '☀️';
    if (c.contains('thunder')) return '⛈';
    if (c.contains('heavy rain')) return '🌧';
    if (c.contains('rain') || c.contains('shower')) return '🌦';
    if (c.contains('fog')) return '🌫';
    if (c.contains('wind')) return '🌬';
    if (c.contains('cloud')) return '⛅';
    return '🌤';
  }

  Color _conditionColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('sun')) return const Color(0xFFEA580C);
    if (c.contains('thunder')) return const Color(0xFF7C3AED);
    if (c.contains('rain') || c.contains('shower')) return const Color(0xFF0369A1);
    if (c.contains('fog')) return const Color(0xFF6B7280);
    return context.ac.blue;
  }

  // ── API fetch ─────────────────────────────────────────────────────────────

  Future<void> _fetchWeather(String city) async {
    if (city.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final url =
          Uri.parse('http://127.0.0.1:8000/api/weather/${city.trim()}');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        final fetchedCity = d['city'] ?? city;
        setState(() {
          _weather = WeatherData(
            city: fetchedCity,
            condition: d['condition'] ?? 'Unknown',
            temp: (d['temperature'] as num).toInt(),
            feelsLike: (d['feels_like'] as num?)?.toInt() ??
                (d['temperature'] as num).toInt() + 2,
            humidity: (d['humidity'] as num?)?.toInt() ?? 70,
            windKph: (d['wind_kph'] as num?)?.toInt() ?? 10,
          );
          _selectedHour = 0;
        });
        // Persist so next launch restores this city
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_city', fetchedCity);
      } else {
        setState(() => _error = 'City not found');
      }
    } catch (_) {
      setState(() => _error = 'Could not connect — is the server running?');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Saved cities ──────────────────────────────────────────────────────────

  void _saveCurrentCity() {
    if (_weather == null) {
      _showSnack('Search a city first!', icon: Icons.search);
      return;
    }
    final alreadySaved =
        _savedCities.any((c) => c.city.toLowerCase() == _weather!.city.toLowerCase());
    if (alreadySaved) {
      _showSnack('${_weather!.city} is already saved!', icon: Icons.info_outline);
      return;
    }
    final city = SavedCity(
      id: _nextId++,
      city: _weather!.city,
      condition: _weather!.condition,
      temp: _weather!.temp,
      feelsLike: _weather!.feelsLike,
      humidity: _weather!.humidity,
      windKph: _weather!.windKph,
      addedAt: DateTime.now(),
    );
    setState(() => _savedCities.add(city));
    CityStorage.save(_savedCities);
    _showSnack('${_weather!.city} saved!', icon: Icons.bookmark_added_outlined);
  }

  void _togglePin(int id) {
    setState(() {
      final idx = _savedCities.indexWhere((c) => c.id == id);
      if (idx == -1) return;
      _savedCities[idx] =
          _savedCities[idx].copyWith(isPinned: !_savedCities[idx].isPinned);
      _savedCities.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.addedAt.compareTo(a.addedAt);
      });
    });
    CityStorage.save(_savedCities);
  }

  void _removeCity(int id) {
    final city = _savedCities.firstWhere((c) => c.id == id);
    setState(() => _savedCities.removeWhere((c) => c.id == id));
    CityStorage.save(_savedCities);
    _showSnack('${city.city} removed', icon: Icons.delete_outline);
  }

  void _loadSavedCityWeather(SavedCity city) {
    setState(() {
      _weather = WeatherData(
        city: city.city,
        condition: city.condition,
        temp: city.temp,
        feelsLike: city.feelsLike,
        humidity: city.humidity,
        windKph: city.windKph,
      );
      _selectedHour = 0;
    });
    Navigator.pop(context);
  }

  void _showSnack(String msg, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
          ],
          Text(msg),
        ]),
        backgroundColor: context.ac.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Saved cities drawer ───────────────────────────────────────────────────

  void _openSavedCities() {
    final c = context.ac;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          minChildSize: 0.35,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Saved cities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: c.blueLight, borderRadius: BorderRadius.circular(50)),
                        child: Text('${_savedCities.length}',
                            style: TextStyle(fontSize: 13, color: c.blue, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                if (_savedCities.isEmpty)
                  Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bookmark_border, size: 48, color: c.textTertiary),
                    const SizedBox(height: 12),
                    Text('No saved cities yet', style: TextStyle(color: c.textSecondary, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text('Search a city and tap the bookmark icon', style: TextStyle(color: c.textTertiary, fontSize: 13)),
                  ])))
                else
                  Expanded(child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _savedCities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _savedCityCard(_savedCities[i], setModal),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _savedCityCard(SavedCity city, StateSetter setModal) {
    final ac = context.ac;
    final cardColor = _conditionColor(city.condition);
    final pinnedBg = context.isDark ? kPinnedBgDark : kPinnedBg;
    return GestureDetector(
      onTap: () => _loadSavedCityWeather(city),
      child: Container(
        decoration: BoxDecoration(
          color: city.isPinned ? pinnedBg : ac.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: city.isPinned ? kPinned : ac.border, width: city.isPinned ? 1.5 : 0.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: cardColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(_conditionIcon(city.condition), style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(city.city, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ac.textPrimary)),
              if (_homeCityName == city.city) ...[ const SizedBox(width: 6), Icon(Icons.home_rounded, size: 14, color: ac.blue) ],
              if (city.isPinned) ...[ const SizedBox(width: 6), const Icon(Icons.push_pin_rounded, size: 14, color: kPinned) ],
            ]),
            Text(city.condition, style: TextStyle(fontSize: 12, color: ac.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_toDisplay(city.temp)}$_unit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: cardColor)),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: () { _setHomeCity(city.city); setModal(() {}); },
                child: Icon(_homeCityName == city.city ? Icons.home_rounded : Icons.home_outlined,
                    size: 18, color: _homeCityName == city.city ? ac.blue : ac.textTertiary),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () { _togglePin(city.id); setModal(() {}); },
                child: Icon(city.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 18, color: city.isPinned ? kPinned : ac.textTertiary),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () { _removeCity(city.id); setModal(() {}); },
                child: Icon(Icons.delete_outline, size: 18, color: ac.textTertiary),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              _buildSearchBar(),
              const SizedBox(height: 4),
              if (_error != null) _buildErrorBanner(),
              if (_savedCities.isNotEmpty) _buildPinnedSection(),
              if (_weather == null) ...[
                if (_savedCities.where((c) => c.isPinned).isEmpty)
                  _buildEmptyState()
              ] else ...[
                _buildUnitToggle(),
                _buildWeatherCard(),
                _buildSectionTitle('Hourly forecast'),
                _buildHourlyRow(),
                _buildSectionTitle('7-day forecast'),
                _buildDailyList(),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

Widget _buildEmptyState() {
  final c = context.ac;

  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.travel_explore,
            size: 72,
            color: c.textTertiary,
          ),

          const SizedBox(height: 16),

          Text(
            'Search for a city',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Type a city name above to get the current weather',
            style: TextStyle(
              fontSize: 13,
              color: c.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final c = context.ac;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.cloud_outlined, color: c.blue, size: 22),
            const SizedBox(width: 8),
            Text('SkyTrack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c.textPrimary)),
          ]),
          Row(children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_outline),
                  color: c.textSecondary,
                  onPressed: _openSavedCities,
                ),
                if (_savedCities.isNotEmpty)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: c.blue, shape: BoxShape.circle),
                      child: Center(child: Text('${_savedCities.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.list_alt_outlined),
              color: c.textSecondary,
              tooltip: 'Weather Logs',
              onPressed: () => Navigator.of(context).pushNamed('/logs'),
            ),
            IconButton(
              icon: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              color: c.textSecondary,
              onPressed: _toggleTheme,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              color: c.textSecondary,
              onPressed: _logout,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSearchBar() => CitySearchBar(
        onSearch: _fetchWeather,
        onSave: _saveCurrentCity,
        loading: _loading,
      );

  Widget _buildUnitToggle() {
    final c = context.ac;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_formattedDate(), style: TextStyle(fontSize: 13, color: c.textTertiary)),
          GestureDetector(
            onTap: () => setState(() => _isCelsius = !_isCelsius),
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _unitBtn('°C', _isCelsius),
                  _unitBtn('°F', !_isCelsius),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitBtn(String label, bool active) {
    final c = context.ac;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? c.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: active ? Colors.white : c.textTertiary)),
    );
  }

  Widget _buildErrorBanner() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFDC2626), size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFF991B1B), fontSize: 13))),
            GestureDetector(
              onTap: () => setState(() => _error = null),
              child: const Icon(Icons.close,
                  color: Color(0xFF991B1B), size: 16),
            ),
          ]),
        ),
      );

  Widget _buildPinnedSection() {
    final pinned = _savedCities.where((c) => c.isPinned).toList();
    if (pinned.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(children: [
            const Icon(Icons.push_pin_rounded, size: 14, color: kPinned),
            const SizedBox(width: 6),
            Text('Pinned cities', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: context.ac.textSecondary)),
          ]),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: pinned.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = pinned[i];
              return GestureDetector(
                onTap: () => _fetchWeather(c.city),
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: _conditionColor(c.condition),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(c.city,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text(_conditionIcon(c.condition),
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      Text('${_toDisplay(c.temp)}$_unit',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1)),
                      Text(c.condition,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    final w = _weather!;
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Container(
          decoration: BoxDecoration(
            color: _conditionColor(w.condition),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.city,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          Text(_formattedDate(),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70)),
                        ]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_toDisplay(w.temp)}$_unit',
                            style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                height: 1.0)),
                        Text(w.condition,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white70)),
                      ]),
                  Text(_conditionIcon(w.condition),
                      style: const TextStyle(fontSize: 80)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0x33FFFFFF), height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weatherStat(Icons.thermostat_outlined, 'Feels like',
                      '${_toDisplay(w.feelsLike)}$_unit'),
                  _weatherStat(Icons.water_drop_outlined, 'Humidity',
                      '${w.humidity}%'),
                  _weatherStat(
                      Icons.air, 'Wind', '${w.windKph} km/h'),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _weatherStat(IconData icon, String label, String value) => Column(
        children: [
          Icon(icon, color: Colors.white60, size: 18),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      );

  Widget _buildSectionTitle(String title) {
    final c = context.ac;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textSecondary)),
    );
  }

  Widget _buildHourlyRow() {
    final c = context.ac;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _hourly.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isActive = _selectedHour == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedHour = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              decoration: BoxDecoration(
                color: isActive ? c.blueLight : c.card,
                border: Border.all(color: isActive ? c.blue : c.border, width: isActive ? 1.5 : 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_hourly[i].time, style: TextStyle(fontSize: 11, color: isActive ? c.blue : c.textTertiary)),
                  const SizedBox(height: 4),
                  Text(_hourly[i].icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('${_toDisplay(_hourly[i].temp)}$_unit',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? c.blue : c.textPrimary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyList() {
    final c = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: _daily.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  SizedBox(width: 40, child: Text(d.day, style: TextStyle(fontSize: 14, color: c.textSecondary))),
                  Text(d.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(d.condition, style: TextStyle(fontSize: 13, color: c.textTertiary))),
                  Text('${_toDisplay(d.low)}° / ${_toDisplay(d.high)}°$_unit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                ]),
              ),
              if (i < _daily.length - 1)
                Divider(height: 1, indent: 16, endIndent: 16, color: c.border),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}