import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const _kBg1 = Color(0xFF0F2027);
const _kBg2 = Color(0xFF203A43);
const _kBg3 = Color(0xFF2C5364);
const _kAccent = Color(0xFF4FC3F7);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String _name = 'User';
  String _email = '';
  int _logCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Load local user + GET /weather for log count ──────────────────────────

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load stored user data from SharedPreferences (set during login)
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? 'User';
      final email = prefs.getString('user_email') ?? '';

      // GET /weather — fetch log count from real backend
      int count = 0;
      try {
        final res = await http
            .get(
              Uri.parse('http://127.0.0.1:8000/api/weather'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is List) count = data.length;
        }
      } catch (_) {
        // Log count unavailable — non-critical, continue
      }

      setState(() {
        _name = name;
        _email = email;
        _logCount = count;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load profile';
        _loading = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: _kAccent.withOpacity(0.1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBg1, _kBg2, _kBg3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAccent))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                          _buildInfoNote(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _kAccent, width: 2),
            ),
            child: const Icon(Icons.person, color: _kAccent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email.isNotEmpty ? _email : 'No email stored',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(50),
                    border:
                        Border.all(color: _kAccent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Active Member',
                    style: TextStyle(
                        color: _kAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Weather Logs', '$_logCount', Icons.cloud_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('App Version', '1.0.0', Icons.info_outline)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kAccent, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _kAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Profile data is stored locally on this device. '
              'Weather log count is fetched live from the server via GET /api/weather.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
